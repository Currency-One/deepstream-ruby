require 'json'
require 'deepstream/constants'

module Deepstream
  class Message
    attr_reader :topic, :action, :data

    def initialize(*args)
      if args.size == 1
        args = args.first.delete(MESSAGE_SEPARATOR).split(MESSAGE_PART_SEPARATOR)
      end
      @topic, @action = args.take(2).map(&:to_sym)
      @data = args.drop(2)
    end

    def to_s
      args = [@topic, @action]
      args << @data unless @data.empty?
      args.join(MESSAGE_PART_SEPARATOR).concat(MESSAGE_SEPARATOR)
    end

    def inspect
      "#{self.class.name}: #{@topic} #{@action} #{@data}"
    end

    def needs_authentication?
      ![TOPIC::CONNECTION, TOPIC::AUTH].include?(@topic)
    end
  end
end
