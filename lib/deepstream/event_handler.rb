require 'deepstream/constants'
require 'deepstream/helpers'

module Deepstream
  class EventHandler
    def initialize(client)
      @client = client
      @callbacks = {}
      @ack_timeout_registry = {}
    end

    def on(event, &block)
      unless @callbacks[event]
        @client.send(TOPIC::EVENT, ACTION::SUBSCRIBE, event)
        @ack_timeout_registry[event] = add_ack_timeout(event)
      end
      @callbacks[event] = block
    end

    def on_message(message)
      case message.action
      when ACTION::ACK then cancel_ack_timeout(message)
      when ACTION::EVENT then fire_event_callback(message)
      else @client.on_error(message)
      end
    end

    def add_ack_timeout(event)
      timeout = @client.options[:ack_timeout]
      if timeout
        Celluloid::after(timeout) do
          @client.on_error("No ACK message received in time for #{event}")
        end
      end
    end

    def cancel_ack_timeout(message)
      event = message.data.last
      @ack_timeout_registry[event].cancel
      @ack_timeout_registry[event] = nil
    end

    def emit(event, data = nil)
      @client.send(TOPIC::EVENT, ACTION::EVENT, event, Helpers::to_deepstream_type(data))
    end

    def unsubscribe(event)
      @callbacks.delete(event)
      @client.send(TOPIC::EVENT, ACTION::UNSUBSCRIBE, event)
    end

    def fire_event_callback(message)
      event, data = message.data
      data = Helpers::to_type(data)
      Celluloid::Future.new { @callbacks[event].(event, data) }
    end
  end
end
