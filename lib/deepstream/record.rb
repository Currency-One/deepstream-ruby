require 'json'
require 'deepstream/constants'
require 'deepstream/helpers'

module Deepstream
  class Record
    attr_reader :name, :data, :version

    def initialize(client, name)
      @client = client
      @name = name
      @data, @version = nil
      @client.send_message(TOPIC::RECORD, ACTION::CREATEORREAD, @name)
    end

    def inspect
      "#{self.class} #{@name} #{@version} #{@data}"
    end

    def update(version, data)
      @version = version.to_i
      @data = JSON.parse(data)
    end

    def patch(version, path, value)
      @version = version.to_i
      set_path(@data, path, Helpers.to_type(value))
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
        path, value = args
        set_path(@data, path, value)
        @client.send_message(TOPIC::RECORD, ACTION::PATCH, @name, (@version += 1), path, Helpers.to_deepstream_type(value))
      end
    end

    def set_path(data, path, value)
      key, subkey = path.split('.', 2)
      if data.is_a?(Hash)
        subkey ? set_path(data.fetch(key), subkey, value) : data[key] = value
      elsif data.is_a?(Array)
        subkey ? set_path(data[key.to_i], subkey, value) : data[key.to_i] = value
      end
    end
  end
end
