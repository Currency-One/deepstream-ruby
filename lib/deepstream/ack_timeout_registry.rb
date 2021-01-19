module Deepstream
  class AckTimeoutRegistry
    def initialize(client)
      @client = client
      @timeouts = {}
    end

    def add(name, message)
      return unless (timeout = @client.options[:ack_timeout])
      @timeouts[name] = Thread.new do
        sleep timeout
        @client.on_error(message)
      end
    end

    def cancel(name)
      @timeouts[name].exit rescue nil
      @timeouts.delete(name)
    end
  end
end
