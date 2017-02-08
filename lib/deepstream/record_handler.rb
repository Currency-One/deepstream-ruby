require 'deepstream/constants'
require 'deepstream/exceptions'
require 'deepstream/list'
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
      when ACTION::PATCH then patch(message)
      when ACTION::READ then read(message)
      when ACTION::UPDATE then update(message)
      else raise(UnknownAction, message)
      end
    end

    def get(name, list: nil)
      if list
        name.prepend("#{list}/")
        @records[list] ||= List.new(@client, list)
        @records[list].add(name)
      end
      @records[name] ||= Record.new(@client, name)
    end

    def get_list(name)
      @records[name] ||= List.new(@client, name)
    end

    def set(name, *args)
      @records[name]&.set(*args)
    end

    def unsubscribe(name)
      @records[name]&.unsubscribe
    end

    def discard(name)
      unsubscribe(name)
    end

    def delete(name)
      @client.send_message(TOPIC::RECORD, ACTION::DELETE, name) if @records.delete(name)
    end

    private

    def read(message)
      name, *data = message.data
      @records[name]&.read(*data)
    end

    def update(message)
      name, *data = message.data
      @records[name]&.update(*data)
    end

    def patch(message)
      name, *data = message.data
      @records[name]&.patch(*data)
    end
  end
end
