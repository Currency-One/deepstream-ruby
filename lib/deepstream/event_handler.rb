require 'deepstream/ack_timeout_registry'
require 'deepstream/constants'
require 'deepstream/helpers'

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
        @client.send_message(TOPIC::EVENT, ACTION::SUBSCRIBE, event)
        @ack_timeout_registry.add(event, "No ACK message received in time for #{event}")
      end
      @callbacks[event] = block
    end
    alias subscribe on

    def listen(pattern, &block)
      pattern = pattern.is_a?(Regexp) ? pattern.source : pattern
      @listeners[pattern] = block
      @client.send_message(TOPIC::EVENT, ACTION::LISTEN, pattern)
      @ack_timeout_registry.add(pattern, "No ACK message received in time for #{pattern}")
    end

    def unlisten(pattern)
      pattern = pattern.is_a?(Regexp) ? pattern.source : pattern
      @listeners.delete(pattern)
      @client.send_message(TOPIC::EVENT, ACTION::UNLISTEN, pattern)
    end

    def on_message(message)
      case message.action
      when ACTION::ACK then @ack_timeout_registry.cancel(message.data.last)
      when ACTION::EVENT then fire_event_callback(message)
      when ACTION::SUBSCRIPTION_FOR_PATTERN_FOUND then fire_listen_callback(message)
      when ACTION::SUBSCRIPTION_FOR_PATTERN_REMOVED then fire_listen_callback(message)
      else @client.on_error(message)
      end
    end

    def emit(event, data = nil)
      @client.send_message(TOPIC::EVENT, ACTION::EVENT, event, Helpers.to_deepstream_type(data))
    end

    def unsubscribe(event)
      @callbacks.delete(event)
      @client.send_message(TOPIC::EVENT, ACTION::UNSUBSCRIBE, event)
    end

    def resubscribe
      @callbacks.keys.each { |event| @client.send_message(TOPIC::EVENT, ACTION::SUBSCRIBE, event) }
      @listeners.keys.each { |pattern| @client.send_message(TOPIC::EVENT, ACTION::LISTEN, pattern) }
    end

    private

    def fire_event_callback(message)
      event, data = message.data
      data = Helpers.to_type(data)
      Celluloid::Future.new { @callbacks[event].call(event, data) }
    end

    def fire_listen_callback(message)
      is_subscribed = message.action == ACTION::SUBSCRIPTION_FOR_PATTERN_FOUND
      pattern, event = message.data
      return @client.on_error(pattern) unless @listeners[pattern]
      @listeners[pattern].call(is_subscribed, event)
    end
  end
end
