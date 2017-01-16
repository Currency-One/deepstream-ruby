require 'deepstream/constants'
require 'deepstream/helpers'

module Deepstream
  class EventHandler
    def initialize(client)
      @client = client
      @callbacks = {}
    end

    def on(event, &block)
      @callbacks[event] = block
      @client.send(TOPIC::EVENT, ACTION::SUBSCRIBE, event)
    end

    def on_message(message)
      case message.action
      when ACTION::ACK then nil
      when ACTION::EVENT then fire_event_callback(message)
      else @client.on_error(message)
      end
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
