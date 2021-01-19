require_relative './ack_timeout_registry'
require_relative './constants'
require_relative './exceptions'
require_relative './helpers'

module Deepstream
  class EventHandler
    def initialize(client)
      @client = client
      @callbacks = {}
      @listeners = {}
      @ack_timeout_registry = AckTimeoutRegistry.new(@client)
    end

    def on(event, &block)
      unless @callbacks[event]
        @client.send_message(TOPIC::EVENT, ACTION::SUBSCRIBE, event) if @client.state == CONNECTION_STATE::OPEN
        @ack_timeout_registry.add(event, "No ACK message received in time for #{event}")
      end
      @callbacks[event] = block
    rescue => e
      @client.on_exception(e)
    end
    alias subscribe on

    def listen(pattern, &block)
      pattern = pattern.is_a?(Regexp) ? pattern.source : pattern
      @listeners[pattern] = block
      @client.send_message(TOPIC::EVENT, ACTION::LISTEN, pattern)
      @ack_timeout_registry.add(pattern, "No ACK message received in time for #{pattern}")
    rescue => e
      @client.on_exception(e)
    end

    def unlisten(pattern)
      pattern = pattern.is_a?(Regexp) ? pattern.source : pattern
      @listeners.delete(pattern)
      @client.send_message(TOPIC::EVENT, ACTION::UNLISTEN, pattern)
    rescue => e
      @client.on_exception(e)
    end

    def on_message(message)
      case message.action
      when ACTION::ACK then @ack_timeout_registry.cancel(message.data.last)
      when ACTION::EVENT then fire_event_callback(message)
      when ACTION::SUBSCRIPTION_FOR_PATTERN_FOUND then fire_listen_callback(message)
      when ACTION::SUBSCRIPTION_FOR_PATTERN_REMOVED then fire_listen_callback(message)
      else raise(UnknownAction, message)
      end
    end

    def emit(event, *args, timeout: @client.options[:emit_timeout], **kwargs)
      data = Helpers.message_data(*args, **kwargs)
      @client.send_message(TOPIC::EVENT, ACTION::EVENT, event, Helpers.to_deepstream_type(data), timeout: timeout)
    rescue => e
      @client.on_exception(e)
    end

    def unsubscribe(event)
      @callbacks.delete(event)
      @client.send_message(TOPIC::EVENT, ACTION::UNSUBSCRIBE, event)
    rescue => e
      @client.on_exception(e)
    end

    def resubscribe
      @callbacks.keys.each { |event| @client.send_message(TOPIC::EVENT, ACTION::SUBSCRIBE, event) }
      @listeners.keys.each { |pattern| @client.send_message(TOPIC::EVENT, ACTION::LISTEN, pattern) }
    rescue => e
      @client.on_exception(e)
    end

    private

    def fire_event_callback(message)
      event, data = message.data
      @callbacks[event].call(Helpers.to_type(data))
    end

    def fire_listen_callback(message)
      is_subscribed = message.action == ACTION::SUBSCRIPTION_FOR_PATTERN_FOUND
      pattern, event = message.data
      return @client.on_error(pattern) unless @listeners[pattern]
      @listeners[pattern].call(is_subscribed, event)
    end
  end
end
