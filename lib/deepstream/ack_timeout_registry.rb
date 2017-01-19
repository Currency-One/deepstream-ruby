module Deepstream
  class AckTimeoutRegistry
    def initialize(client)
      @client = client
      @timeouts = {}
    end

    def add(name, message)
      return unless (timeout = @client.options[:ack_timeout])
      @timeouts[name] = Celluloid.after(timeout) { @client.on_error(message) }
    end

    def cancel(name)
      @timeouts.delete(name).cancel rescue nil
    end
  end
end
