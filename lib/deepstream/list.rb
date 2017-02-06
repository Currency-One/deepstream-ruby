require 'deepstream/record'

module Deepstream
  class List < Record
    def initialize(*args)
      super
      @data = []
    end

    def add(record_name)
      set(@data.length.to_s, record_name) unless @data.include?(record_name)
    end

    def read(version, data)
      @version = version.to_i
      data = JSON.parse(data)
      if data.is_a?(Array)
        @data.concat(data).uniq!
        set(@data) if @data.size > data.size
      end
    end

    def remove(record_name)
      set(@data) if @data.delete(record_name)
    end

    def keys
      @data
    end

    def all
      @data.map { |record_name| @client.get(record_name) }
    end
  end
end
