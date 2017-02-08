require 'deepstream/constants'
require 'deepstream/helpers'
require 'deepstream/message'

module Deepstream
  class ErrorHandler
    attr_reader :error

    def initialize(client)
      @client = client
      @error = nil
    end

    def on_error(message)
      @error =
        if message.is_a?(Message)
          message.topic == TOPIC::ERROR ? message.data : Helpers.to_type(message.data.last)
        else
          message
        end
      puts "#{@error}\n" unless @client.options[:debug]
    end

    def on_exception(exception)
      raise exception if @client.options[:debug]
      puts "\n#{exception.message}\n#{exception.backtrace}\n"
    end
  end
end
