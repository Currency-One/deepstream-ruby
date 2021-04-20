module Async
  module WebSocket
    class Client < ::Protocol::HTTP::Middleware
      include ::Protocol::WebSocket::Headers

      def self.connect(endpoint, *args, **options, &block)
        self.open(endpoint, *args) do |client|
          connection = client.connect(endpoint.authority, endpoint.path, **options)
       
          return connection unless block_given?

          begin
            yield connection
          ensure
            connection.close
          end
        rescue
          puts "cant connect to #{endpoint}"
        end
      end
    end

    class Connection < ::Protocol::WebSocket::Connection

      def write(object)
        super(object)
      end

      def parse(buffer)
        buffer
      end
    end
  end
end
