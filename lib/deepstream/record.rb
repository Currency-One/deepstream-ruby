require 'json'
require 'deepstream/constants'

module Deepstream
  class Record
    attr_reader :name, :data, :version

    def initialize(client, name)
      @client, @name = client, name
      @data, @version = nil
      @client.send(TOPIC::RECORD, ACTION::CREATEORREAD, @name)
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
      @data[key] = to_type(value)
    end

    def unsubscribe
      @client.send(TOPIC::RECORD, ACTION::UNSUBSCRIBE, name)
    end

    def delete
      @client.delete(@name)
    end

    def set(*args)
      if args.size == 1
        @data = args.first
        @client.send(TOPIC::RECORD, ACTION::UPDATE, @name, (@version += 1), @data.to_json)
      elsif args.size == 2
        key, value = args
        @data[key] = value
        @client.send(TOPIC::RECORD, ACTION::PATCH, @name, (@version += 1), key, to_deepstream_type(value))
      end
    end

    def to_deepstream_type(value)
      case value
      when Hash then "O#{value.to_json}"
      when String then "S#{value}"
      when Numeric then "N#{value}"
      when TrueClass then 'T'
      when FalseClass then 'F'
      when NilClass then 'L'
      end
    end

    def to_type(payload)
      case payload[0]
      when 'O' then JSON.parse(payload[1..-1])
      when '{' then JSON.parse(payload)
      when 'S' then payload[1..-1]
      when 'N' then payload[1..-1].to_f
      when 'T' then true
      when 'F' then false
      when 'L' then nil
      else JSON.parse(payload)
      end
    end
  end
end
