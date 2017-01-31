require 'forwardable'
require 'celluloid/websocket/client'
require 'deepstream/constants'
require 'deepstream/event_handler'
require 'deepstream/record_handler'
require 'deepstream/helpers'
require 'deepstream/message'

module Deepstream
  class Client
    attr_reader :state, :last_hearbeat, :error, :options

    include Celluloid
    include Celluloid::Internals::Logger
    extend Forwardable

    execute_block_on_receiver :on, :subscribe, :listen

    def_delegators :@event_handler, :on, :emit, :subscribe, :unsubscribe,
                   :listen, :resubscribe, :unlisten
    def_delegators :@record_handler, :get, :set, :delete, :discard, :get_list

    def initialize(url, options = {})
      @url = Helpers.get_url(url)
      @connection = connect
      @record_handler = RecordHandler.new(self)
      @event_handler = EventHandler.new(self)
      @options = Helpers.default_options.merge!(options)
      @message_buffer = []
      @last_hearbeat, @error = nil
      @challenge_denied, @login_requested, @deliberate_close = false
      @failed_reconnect_attempts = 0
      @state = CONNECTION_STATE::CLOSED
      Celluloid.logger.level = @options[:verbose] ? LOG_LEVEL::INFO : LOG_LEVEL::OFF
    end

    def on_open
      @state = CONNECTION_STATE::AWAITING_CONNECTION
      @failed_reconnect_attempts = 0
    end

    def on_message(data)
      message = Message.new(data)
      info("Incoming message: #{message.inspect}")
      case message.topic
      when TOPIC::AUTH       then authentication_message(message)
      when TOPIC::CONNECTION then connection_message(message)
      when TOPIC::EVENT      then @event_handler.on_message(message)
      when TOPIC::ERROR      then on_error(message)
      when TOPIC::RECORD     then @record_handler.on_message(message)
      else on_error(message)
      end
    end

    def on_close(code, reason)
      info("Websocket connection closed: #{code.inspect}, #{reason.inspect}")
      @state = CONNECTION_STATE::CLOSED
      reconnect unless @deliberate_close
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
      send_message(TOPIC::CONNECTION, ACTION::CHALLENGE_RESPONSE, @url)
    end

    def on_connection_ack
      @state = CONNECTION_STATE::AUTHENTICATING
      login if @options[:autologin] || @login_requested
    end

    def login(credentials = @options[:credentials])
      @options[:credentials] = credentials
      if @challenge_denied
        on_error("this client's connection was closed")
      elsif @state == CONNECTION_STATE::AUTHENTICATING
        @login_requested = false
        send_message(TOPIC::AUTH, ACTION::REQUEST, @options[:credentials].to_json)
      else
        @login_requested = true
      end
      self
    end

    def pong
      @last_heartbeat = Time.now
      send_message(TOPIC::CONNECTION, ACTION::PONG)
    end

    def on_login
      @state = CONNECTION_STATE::OPEN
      @message_buffer.each { |message| send_message(message) }.clear
      every(@options[:heartbeat_interval]) { check_heartbeat } if @options[:heartbeat_interval]
    end

    def on_rejection
      @challenge_denied = true
      close
    end

    def check_heartbeat
      return unless @last_heartbeat && Time.now - @last_heartbeat > 2 * @options[:heartbeat_interval]
      @state = CONNECTION_STATE::CLOSED
      on_error('Two connections heartbeats missed successively')
    end

    def redirect(message)
      close
      connect(message.data.last)
    end

    def connect(url = @url)
      @connection = Celluloid::WebSocket::Client.new(url, Actor.current)
    end

    def reconnect
      @state = CONNECTION_STATE::RECONNECTING
      if @failed_reconnect_attempts < @options[:max_reconnect_attempts]
        connect
        resubscribe
      else
        @state = CONNECTION_STATE::ERROR
      end
    rescue Errno::ECONNREFUSED
      @failed_reconnect_attempts += 1
      on_error("Can't connect! Deepstream server unreachable on #{@url}")
      sleep(reconnect_interval)
      reconnect
    end

    def reconnect_interval
      [@options[:reconnect_interval] * @failed_reconnect_attempts, @options[:max_reconnect_interval]].min
    end

    def on_error(message)
      @error = if message.is_a?(Message)
        message.topic == TOPIC::ERROR ? message.data : Helpers.to_type(message.data.last)
      else
        message
      end
    end

    def close
      @deliberate_close = true
      @connection.close
      @connection.terminate
      @state = CONNECTION_STATE::CLOSED
    end

    def send_message(*args)
      message = Message.parse(*args)
      if !connected? && message.needs_authentication?
        info("Placing message #{message.inspect} in buffer, waiting for connection")
        @message_buffer << message
      else
        info("Sending message: #{message.inspect}")
        @connection.text(message.to_s)
      end
    end

    def connected?
      @state == CONNECTION_STATE::OPEN
    end

    def inspect
      "#{self.class} #{@url} | connection state: #{@state}"
    end
  end
end
