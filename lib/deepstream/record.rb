require 'json'
require 'deepstream/constants'
require 'deepstream/helpers'

module Deepstream
  class Record
    attr_reader :name, :data, :version

    def initialize(client, name)
      @client, @name = client, name
      @data, @version = nil
      @client.send_message(TOPIC::RECORD, ACTION::CREATEORREAD, @name)
    end

    def inspect
      "#{self.class.name} #{@name} #{@version} #{@data}"
    end

    def update(version, data)
      @version = version.to_i
      @data = JSON.parse(data)
    end

    def patch(version, key, value)
      @version = version.to_i
      @data[key] = Helpers::to_type(value)
    end

    def unsubscribe
      @client.send_message(TOPIC::RECORD, ACTION::UNSUBSCRIBE, name)
    end

    def delete
      @client.delete(@name)
    end

    def set(*args)
      if args.size == 1
        @data = args.first
        @client.send_message(TOPIC::RECORD, ACTION::UPDATE, @name, (@version += 1), @data.to_json)
      elsif args.size == 2
        key, value = args
        @data[key] = value
        @client.send_message(TOPIC::RECORD, ACTION::PATCH, @name, (@version += 1), key, Helpers::to_deepstream_type(value))
      end
    end
  end
end
