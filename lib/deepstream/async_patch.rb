module Async
  module WebSocket
    class Client < ::Protocol::HTTP::Middleware
      include ::Protocol::WebSocket::Headers

      def self.open(endpoint, *args, &block)
        client = self.new(HTTP::Client.new(endpoint, *args), mask: true)

        return client unless block_given?

        begin
          yield client
        ensure
          client.close
        end
      end

      def self.connect(endpoint, *args, **options, &block)
        self.open(endpoint, *args) do |client|
          connection = client.connect(endpoint.path, **options)

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

module Protocol
  module WebSocket
    class TextFrame

      def unpack
        encoded_readed_string = super.encode(Encoding::UTF_8)
      end
    end
  end
end
