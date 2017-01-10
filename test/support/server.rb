require 'reel'
require_relative 'helpers'

class StubServer < Reel::Server::HTTP
  attr_accessor :clients, :client

  extend Forwardable

  def_delegators :@client, :send, :messages, :last_message

  def initialize(host = CONFIG::IP, port = CONFIG::PORT)
    @clients = []
    super(host, port, &method(:on_connection))
  end

  def on_connection(connection)
    while request = connection.request
      if request.websocket?
        connection.detach
        client = DeepstreamHandler.new(request.websocket)
        @clients << client
        @client = client
        return
      end
    end
  end

  def remove_connections
    @clients.map { |c| c.async.terminate }.clear
    @client = nil
  end
end

class DeepstreamHandler
  attr_accessor :socket, :messages, :last_message
  include Celluloid

  def initialize(websocket)
    @socket = websocket
    @messages = []
  end

  def last_message
    message = Future.new { @socket.read }.value(CONFIG::MESSAGE_TIMEOUT)
    @messages << incoming_message(message)
    incoming_message(message)
  end

  def send(text)
    @socket.write(text)
  end
end
