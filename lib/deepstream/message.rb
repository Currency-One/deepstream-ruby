require 'json'
require 'deepstream/constants'

module Deepstream
  class Message
    attr_reader :action, :data, :topic, :sending_deadline

    def self.parse(*args)
      args.first.is_a?(self) ? args.first : new(*args)
    end

    def initialize(*args)
      if args.one?
        args = args.first.delete(MESSAGE_SEPARATOR).split(MESSAGE_PART_SEPARATOR)
      end
      @sending_deadline = nil
      @topic, @action = args.take(2).map(&:to_sym)
      @data = args.drop(2)
    rescue
      ''
    end

    def set_timeout(timeout)
      @sending_deadline = Time.now + timeout
    end

    def to_s
      args = [@topic, @action]
      args << @data unless (@data.nil? || @data.empty?)
      args.join(MESSAGE_PART_SEPARATOR).concat(MESSAGE_SEPARATOR)
    end

    def inspect
      "#{self.class.name}: #{@topic} #{@action} #{@data}"
    end

    def needs_authentication?
      ![TOPIC::CONNECTION, TOPIC::AUTH].include?(@topic)
    end

    def expired?
      @sending_deadline && @sending_deadline < Time.now
    end
  end
end
