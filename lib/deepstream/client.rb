require 'forwardable'
require 'async'
require 'async/io/stream'
require 'async/http/endpoint'
require 'async/websocket/client'
require 'async/logger'
require_relative './constants'
require_relative './error_handler'
require_relative './event_handler'
require_relative './record_handler'
require_relative './helpers'
require_relative './message'
require_relative './exceptions'
require_relative './async_patch'

module Deepstream
  class Client
    attr_reader :options, :state

    extend Forwardable

    def_delegators :@event_handler, :on, :emit, :subscribe, :unsubscribe, :listen, :resubscribe, :unlisten
    def_delegators :@error_handler, :error, :on_error, :on_exception
    def_delegators :@record_handler, :get, :get_record, :set, :delete, :discard, :get_list

    def initialize(url, options = {})
      @url = Helpers.url(url)
      @error_handler = ErrorHandler.new(self)
      @record_handler = RecordHandler.new(self)
      @event_handler = EventHandler.new(self)
      @options = Helpers.default_options.merge!(options)
      @message_buffer = []
      @last_hearbeat = nil
      @challenge_denied, @@deliberate_close = false
      @state = CONNECTION_STATE::CLOSED
      @verbose = @options[:verbose]
      @log = Async.logger
      @never_connected_before = true
      connect
    end

    def on_open
      @log.info "Websocket connection opened" if @verbose
      @state = CONNECTION_STATE::AWAITING_CONNECTION
    end

    def on_message(data)
      message = Message.new(data)
      @log.info "Receiving msg = #{message.inspect}" if @verbose
      case message.topic
      when TOPIC::AUTH       then authentication_message(message)
      when TOPIC::CONNECTION then connection_message(message)
      when TOPIC::EVENT      then @event_handler.on_message(message)
      when TOPIC::ERROR      then @error_handler.on_error(message)
      when TOPIC::RECORD     then @record_handler.on_message(message)
      when TOPIC::RPC        then raise(UnknownTopic, 'RPC is currently not implemented.')
      when nil               then nil
      else raise(UnknownTopic, message)
      end
    rescue => e
      on_exception(e)
    end

    def login(credentials = @options[:credentials])
      @options[:credentials] = credentials
      if @challenge_denied
        on_error("this client's connection was closed")
      elsif @state == CONNECTION_STATE::AUTHENTICATING
        send_message(TOPIC::AUTH, ACTION::REQUEST, @options[:credentials].to_json, priority: true)
      end
      self
    rescue => e
      on_exception(e)
      self
    end

    def close
      return unless connected?
      @deliberate_close = true
      log.info 'deliberate closing' if @verbose
    rescue => e
      on_exception(e)
    end

    def reconnect
      return if connected?
      @deliberate_close = false
      @state = CONNECTION_STATE::RECONNECTING
      @log.info 'Reconnecting' if @verbose
    end

    def connected?
      @state != CONNECTION_STATE::CLOSED
    end

    def reconnecting?
      @state == CONNECTION_STATE::RECONNECTING
    end

    def logged_in?
      @state == CONNECTION_STATE::OPEN
    end

    def inspect
      "#{self.class} #{@url} | connection state: #{@state}"
    end

    def send_message(*args, **kwargs)
      message = Message.parse(*args)
      priority = kwargs[:priority] || false
      timeout = message.topic == TOPIC::EVENT ? kwargs[:timeout] : nil
      message.set_timeout(timeout) if timeout
      return unable_to_send_message(message, priority) if !logged_in? && message.needs_authentication?
      priority ? @message_buffer.unshift(message) : @message_buffer.push(message)
    rescue Errno::EPIPE
      unable_to_send_message(message, priority)
    rescue => e
      on_exception(e)
    end

    private

    def unable_to_send_message(message, priority)
      @state = CONNECTION_STATE::CLOSED if logged_in?
      unless message.expired?
       @log.info("Placing a message #{message.inspect} in the buffer, waiting for authentication") if @verbose
       priority ? @message_buffer.unshift(message) : @message_buffer.push(message)
      end
    end

    def connection_message(message)
      case message.action
      when ACTION::ACK       then on_connection_ack
      when ACTION::CHALLENGE then on_challenge
      when ACTION::ERROR     then on_error(message)
      when ACTION::PING      then on_ping
      when ACTION::REDIRECT  then on_redirection(message)
      when ACTION::REJECTION then on_rejection
      else raise(UnknownAction, message)
      end
    end

    def authentication_message(message)
      case message.action
      when ACTION::ACK   then on_login
      when ACTION::ERROR then on_error(message)
      else raise(UnknownAction, message)
      end
    end

    def on_challenge
      @state = CONNECTION_STATE::CHALLENGING
      send_message(TOPIC::CONNECTION, ACTION::CHALLENGE_RESPONSE, @url)
    end

    def on_connection_ack
      @state = CONNECTION_STATE::AUTHENTICATING
      @message_buffer.delete_if { |msg| msg.action == ACTION::PATCH }
      @record_handler.reinitialize unless @never_connected_before
      login
    end

    def on_ping
      @last_heartbeat = Time.now
      send_message(TOPIC::CONNECTION, ACTION::PONG)
    end

    def on_login
      @never_connected_before = false
      @state = CONNECTION_STATE::OPEN
      every(@options[:heartbeat_interval]) { check_heartbeat } if @options[:heartbeat_interval]
      resubscribe
    end

    def on_rejection
      @challenge_denied = true
      on_close
    end

    def on_close
      @log.info 'Websocket connection closed' if @verbose
      @state = CONNECTION_STATE::CLOSED
    rescue => e
      on_exception(e)
    end

    def check_heartbeat
      return unless @last_heartbeat && Time.now - @last_heartbeat > 2 * @options[:heartbeat_interval]
      @state = CONNECTION_STATE::CLOSED
      on_error('Two connections heartbeats missed successively')
    end

    def on_redirection(message)
      on_close
      @url = message.data.last
    end

    def connect(in_thread = @options[:in_thread])
      if in_thread
        Thread.start { connection_loop }
      else
        connection_loop
      end
    end

    def connection_loop
      Async do |task|
        @task = task
        loop do
          if @deliberate_close
            sleep 5
            next
          end
          _connect
          sleep 5
        end
      end
    end

    def _connect(url = @url)
      @log.info "Trying to connect to #{url}" if @verbose
      endpoint = Async::HTTP::Endpoint.parse(url)
      Async::WebSocket::Client.connect(endpoint) do |connection|
        on_open
        @task.async do
          loop do
            break if ( connection.closed? || @deliberate_close )
            while !@message_buffer.empty? && (logged_in? || !@message_buffer[0].needs_authentication?)
              msg = @message_buffer.shift
              next if msg.expired?
              encoded_msg = msg.to_s.encode(Encoding::UTF_8)
              @log.info "Sending msg = #{msg.inspect}" if @verbose
              connection.write(encoded_msg)
              connection.flush rescue @message_buffer.unshift(msg)
            end
            @task.sleep 0.001
          end
        end

        loop do
          on_message(connection.read)
          break if ( connection.closed? || @deliberate_close )
        end

      rescue => e
        @log.error "Connection error #{e.message}"
        on_exception(e)
      ensure
        connection.close
      end
      on_close
    end
  end
end
