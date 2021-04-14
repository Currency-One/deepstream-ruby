require 'json'
require_relative './constants'
require_relative './helpers'

module Deepstream
  class Record
    attr_reader :data

    def initialize(client, name)
      @client = client
      @name = name
      @data = {}
      @version = nil
      @is_reinitializing = false
      @data_cache = {}
      @client.send_message(TOPIC::RECORD, ACTION::CREATEORREAD, @name)
      @ready_callback = nil
    end

    def __version
      @version
    end

    def __name
      @name
    end

    def reset_version
      @version = 0
    end

    def is_reinitializing?
      @is_reinitializing
    end

    def start_reinitializing
      @is_reinitializing = true
      @data_cache = @data
      @client.send_message(TOPIC::RECORD, ACTION::CREATEORREAD, @name, priority: true)
    end

    def end_reinitializing
      reset_version if @client.options[:reinitialize_master]
      set(@data_cache) if @client.options[:reinitialize_master]
      @is_reinitializing = false
    end

    def inspect
      "#{self.class} #{@name} #{@version} #{@data}"
    end

    def unsubscribe
      @client.send_message(TOPIC::RECORD, ACTION::UNSUBSCRIBE, name)
    end

    def delete
      @client.delete(@name)
    end

    def set(*args)
      if args.size == 1
        raise(ArgumentError, "Record data must be a hash") unless args.first.is_a?(Hash)
        @data = args.first
        @client.send_message(TOPIC::RECORD, ACTION::UPDATE, @name, (@version += 1), @data.to_json) if @version
      elsif args.size == 2
        path, value = args
        set_path(@data, path, value)
        @client.send_message(TOPIC::RECORD, ACTION::PATCH, @name, (@version += 1), path, Helpers.to_deepstream_type(value)) if @version
      end
    rescue => e
      @client.on_exception(e)
    end

    def when_ready(&block)
      @ready_callback = block
    end

    def read(version, data)
      update(version, data)
      if @ready_callback
        @ready_callback.call(self)
        @ready_callback = nil
      end
    end

    def patch(version, path, value)
      @version = version.to_i
      set_path(@data, path, Helpers.to_type(value))
    rescue => e
      @client.on_exception(e)
    end

    def update(version, data)
      @version = version.to_i
      @data = JSON.parse(data)
    rescue => e
      @client.on_exception(e)
    end

    def method_missing(name, *args)
      name = name.to_s
      return @data.fetch(@data.is_a?(Array) ? name.to_i : name, nil) if args.empty?
      return set(name[0..-2], *args) if name.end_with?('=') && !args.empty?
      raise(NoMethodError, name)
    end

    private

    def set_path(data, path, value)
      key, subkey = path.to_s.split('.', 2)
      if data.is_a?(Hash)
        subkey ? set_path(data.fetch(key), subkey, value) : data[key] = value
      elsif data.is_a?(Array)
        subkey ? set_path(data[key.to_i], subkey, value) : data[key.to_i] = value
      end
    end
  end
end
