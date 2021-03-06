require_relative './constants'
require_relative './exceptions'
require_relative './list'
require_relative './record'

module Deepstream
  class RecordHandler
    def initialize(client)
      @client = client
      @records = {}
    end

    def reinitialize
      @records.map do |record|
        name, rec = record
        rec.start_reinitializing
      end
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
      name = name.dup.to_s
      if list
        name.prepend("#{list}/")
        @records[list] ||= List.new(@client, list)
        sleep 0.1 while @records[list].version.nil?
        @records[list].add(name)
      end
      @records[name] ||= Record.new(@client, name)
    end
    alias get_record get

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
      return @records[name].end_reinitializing if @records[name]&.is_reinitializing?
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
