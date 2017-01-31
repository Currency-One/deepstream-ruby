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

    def update(version, data)
      @version = version.to_i
      data = JSON.parse(data)
      if data.is_a?(Array)
        set(@data.concat(data).uniq!) unless @data.empty?
      end
    end

    def remove(record_name)
      set(@data) if @data.delete(record_name)
    end

    def all
      @data.map { |record_name| @client.get(record_name) }
    end
  end
end
