require 'forwardable'
require 'celluloid/websocket/client'
require 'deepstream/constants'
require 'deepstream/event_handler'
require 'deepstream/message'

module Deepstream
  class Client
    attr_accessor :connection, :last_hearbeat

    include Celluloid
    include Celluloid::Internals::Logger
    extend Forwardable

    execute_block_on_receiver :on

    def_delegators :@event_handler, :on, :emit, :unsubscribe

    def initialize(url, credentials = {})
      @connection = Celluloid::WebSocket::Client.new(url, Actor.current)
      @event_handler = EventHandler.new(self)
      @credentials = credentials
      @last_hearbeat = nil
      @state = CONNECTION_STATE::CLOSED
    end

    def on_open
      @state = CONNECTION_STATE::AWAITING_CONNECTION
    end

    def on_message(data)
      message = Message.new(data)
      info(message.inspect)
      case message.topic
      when TOPIC::CONNECTION then connection_message(message)
      when TOPIC::AUTH       then authentication_message(message)
      when TOPIC::EVENT      then @event_handler.on_message(message)
      else error(message)
      end
    end

    def on_close(code, reason)
      info("websocket connection closed: #{code.inspect}, #{reason.inspect}")
      @state = CONNECTION_STATE::CLOSED
    end


    def connection_message(message)
      case message.action
      when ACTION::ACK       then login
      when ACTION::CHALLENGE then challenge
      when ACTION::ERROR     then error(message)
      when ACTION::PING      then pong
      when ACTION::REJECTION then @state = CONNECTION_STATE::CLOSED
      else error(message)
      end
    end

    def authentication_message(message)
      case message.action
      when ACTION::ACK then @state = CONNECTION_STATE::OPEN
      else error(message)
      end
    end

    def challenge
      @state = CONNECTION_STATE::CHALLENGING
      send(TOPIC::CONNECTION, ACTION::CHALLENGE_RESPONSE, @connection.url)
    end

    def login
      @state = CONNECTION_STATE::AUTHENTICATING
      send(TOPIC::AUTH, ACTION::REQUEST, @credentials)
    end

    def pong
      @last_hearbeat = Time.now
      send(TOPIC::CONNECTION, ACTION::PONG)
    end

    def error(*args)
      require 'pry'
      puts args
      binding.pry
    end

    def send(*args)
      message = Message.new(*args)
      sleep 1 while !connected? && message.needs_authentication?
      @connection.text(message.to_s)
    end

    def connected?
      @state == CONNECTION_STATE::OPEN
    end
  end
end