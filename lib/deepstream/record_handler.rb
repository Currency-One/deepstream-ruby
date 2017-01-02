require 'deepstream/constants'
require 'deepstream/record'

module Deepstream
  class RecordHandler
    def initialize(client)
      @client = client
      @records = {}
    end

    def on_message(message)
      case message.action
      when ACTION::ACK then nil
      when ACTION::READ then read(message)
      when ACTION::PATCH then patch(message)
      when ACTION::UPDATE then read(message)
      else @client.error(message)
      end
    end

    def get(name)
      @records[name] ||= Record.new(@client, name)
    end

    def set(name, *args)
      @records[name]&.set(args)
    end

    def unsubscribe(name)
      @records[name]&.unsubscribe
    end

    def discard(name)
      unsubscribe(name)
    end

    def delete(name)
      @client.send(TOPIC::RECORD, ACTION::DELETE, name) if @records.delete(name)
    end

    def read(message)
      name, *data = message.data
      @records[name]&.update(*data)
    end

    def patch(message)
      name, *data = message.data
      @records[name]&.patch(*data)
    end
  end
end
