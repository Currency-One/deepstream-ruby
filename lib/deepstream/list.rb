require 'deepstream/record'

module Deepstream
  class List < Record
    def initialize(*args)
      super
      @data = []
    end

    def add(record_name)
      unless @data.include?(record_name)
        @data << record_name
        set
      end
    rescue => e
      @client.on_exception(e)
    end

    def read(version, data)
      @version = version.to_i
      data = JSON.parse(data)
      if data.is_a?(Array)
        @data.concat(data).uniq!
        set if @data.size > data.size
      end
    end

    def remove(record_name)
      set if @data.delete(record_name)
    end

    def keys
      @data
    end

    def all
      @data.map { |record_name| @client.get(record_name) }
    end

    private

    def set
      @client.send_message(TOPIC::RECORD, ACTION::UPDATE, @name, (@version += 1), @data.to_json) if @version
    end
  end
end
