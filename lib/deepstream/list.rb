require_relative './record'
require_relative './exceptions'

module Deepstream
  class List < Record
    LIST_CALLBACKS = %i{added removed}

    attr_reader :version

    def initialize(*args)
      super
      @data = []
      @handlers = {}
    end

    def add(record_name)
      unless @data.include?(record_name)
        @data << record_name
        set
        notify_listeners(:added, record_name)
      end
    rescue => e
      @client.on_exception(e)
    end

    def read(version, data)
      @version = version.to_i
      data = JSON.parse(data)
      if data.is_a?(Array)
        set_new_data (@data + data).uniq
        set if @data.size > data.size
      end
    end

    def remove(record_name)
      set if @data.delete(record_name)
      notify_listeners(:removed, record_name)
    end

    def keys
      @data
    end

    def all
      @data.map { |record_name| @client.get(record_name) }
    end

    def end_reinitializing
      reset_version
      set
      @is_reinitializing = false
    end

    def update(version, data)
      @version = version.to_i
      set_new_data JSON.parse(data)
    rescue => e
      @client.on_exception(e)
    end

    def on(cb_name, &block)
      unless LIST_CALLBACKS.include?(cb_name)
        raise(UnknownListCallback, "Uknown callback name: #{cb_name}. Must be one of: #{LIST_CALLBACKS}")
      end
      (@handlers[cb_name] ||= []).push(block)
      nil
    end

    def off(cb_name, &block)
      if block_given?
        @handlers[cb_name].delete block
      elsif cb_name
        @handlers[cb_name] = []
      else
        @handlers = {}
      end
      nil
    end

    private

    def set
      @client.send_message(TOPIC::RECORD, ACTION::UPDATE, @name, (@version += 1), @data.to_json) if @version
    end

    def set_new_data(new_data)
      (@data - new_data).each { |uid| notify_listeners(:removed, uid) }
      (new_data - @data).each { |uid| notify_listeners(:added, uid) }
      @data = new_data
    end

    def notify_listeners(cb_name, uid)
      (@handlers[cb_name] || []).each do |proc|
        record = @client.get(uid)
        if record.__version
          proc.call(record)
        else
          record.when_ready(&proc)
        end
      end
    end
  end
end