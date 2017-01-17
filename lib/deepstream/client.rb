require 'forwardable'
require 'celluloid/websocket/client'
require 'deepstream/constants'
require 'deepstream/event_handler'
require 'deepstream/record_handler'
require 'deepstream/helpers'
require 'deepstream/message'

module Deepstream
  class Client
    attr_reader :state, :last_hearbeat, :error

    include Celluloid
    include Celluloid::Internals::Logger
    extend Forwardable

    execute_block_on_receiver :on

    def_delegators :@event_handler, :on, :emit, :unsubscribe
    def_delegators :@record_handler, :get, :set, :delete, :discard

    def initialize(url, options = {})
      @connection = Celluloid::WebSocket::Client.new(url, Actor.current)
      @record_handler = RecordHandler.new(self)
      @event_handler = EventHandler.new(self)
      @options = Helpers::default_options.merge!(options)
      @last_hearbeat = nil
      @error = nil
      @challenge_denied = false
      @login_requested = false
      @state = CONNECTION_STATE::CLOSED
      Celluloid.logger.level = @options[:verbose] ? LOG_LEVEL::INFO : LOG_LEVEL::OFF
    end

    def on_open
      @state = CONNECTION_STATE::AWAITING_CONNECTION
    end

    def on_message(data)
      message = Message.new(data)
      info("Incoming message: #{message.inspect}")
      case message.topic
      when TOPIC::CONNECTION then connection_message(message)
      when TOPIC::AUTH       then authentication_message(message)
      when TOPIC::EVENT      then @event_handler.on_message(message)
      when TOPIC::RECORD     then @record_handler.on_message(message)
      else on_error(message)
      end
    end

    def on_close(code, reason)
      info("Websocket connection closed: #{code.inspect}, #{reason.inspect}")
      @state = CONNECTION_STATE::CLOSED
    end

    def connection_message(message)
      case message.action
      when ACTION::ACK       then on_connection_ack
      when ACTION::CHALLENGE then challenge
      when ACTION::ERROR     then on_error(message)
      when ACTION::PING      then pong
      when ACTION::REDIRECT  then redirect(message)
      when ACTION::REJECTION then on_rejection
      else on_error(message)
      end
    end

    def authentication_message(message)
      case message.action
      when ACTION::ACK then on_login
      when ACTION::ERROR then on_error(message)
      else on_error(message)
      end
    end

    def challenge
      @state = CONNECTION_STATE::CHALLENGING
      send(TOPIC::CONNECTION, ACTION::CHALLENGE_RESPONSE, @connection.url)
    end

    def on_connection_ack
      @state = CONNECTION_STATE::AUTHENTICATING
      login if @options[:autologin] || @login_requested
    end

    def login(credentials = @options[:credentials])
      @options[:credentials] = credentials
      if @challenge_denied
        @error = "this client's connection was closed"
      elsif @state == CONNECTION_STATE::AUTHENTICATING
        send(TOPIC::AUTH, ACTION::REQUEST, @options[:credentials].to_json)
        @login_requested = false
      else
        @login_requested = true
      end
      self
    end

    def pong
      @last_heartbeat = Time.now
      send(TOPIC::CONNECTION, ACTION::PONG)
    end

    def on_login
      @state = CONNECTION_STATE::OPEN
      every(@options[:heartbeat_interval]) { check_heartbeat } if @options[:heartbeat_interval]
    end

    def on_rejection
      @challenge_denied = true
      close
    end

    def check_heartbeat
      if @last_heartbeat && Time.now - @last_heartbeat > 2 * @options[:heartbeat_interval]
        @state = CONNECTION_STATE::CLOSED
        @error = 'Two connections heartbeats missed successively'
      end
    end

    def redirect(message)
      close
      @connection = Celluloid::WebSocket::Client.new(message.data.last, Actor.current)
    end

    def on_error(message)
      @error = Helpers::to_type(message.data.last)
    end

    def close
      @connection.close
      @connection.terminate
      @state = CONNECTION_STATE::CLOSED
    end

    def send(*args)
      message = Message.new(*args)
      info("Sending message: #{message.inspect}")
      sleep 1 while !connected? && message.needs_authentication?
      @connection.text(message.to_s)
    end

    def connected?
      @state == CONNECTION_STATE::OPEN
    end
  end
end
