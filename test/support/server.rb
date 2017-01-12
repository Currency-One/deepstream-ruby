require 'reel'
require_relative 'helpers'

class StubServer < Reel::Server::HTTP
  attr_accessor :clients, :client, :url, :second_url

  extend Forwardable

  def_delegators :@client, :send, :messages, :last_message, :all_messages, :reject_connection

  def initialize(host = CONFIG::IP, port = CONFIG::PORT)
    @url = "ws://#{host}:#{port}"
    @second_url = "ws://#{host}:#{CONFIG::SECOND_PORT}"
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
    @clients.each { |c| c.async.terminate rescue nil }.clear
    @client = nil
  end

  def close
    remove_connections
    shutdown
  end
end

class DeepstreamHandler
  attr_accessor :socket, :messages, :last_message, :active

  include Celluloid

  def initialize(websocket)
    @socket = websocket
    @messages = []
    @active = true
  end

  def last_message(timeout = CONFIG::MESSAGE_TIMEOUT)
    message = Future.new { @socket.read }.value(timeout)
    (@messages << incoming_message(message)).last
  end

  def all_messages
    @active ? loop { last_message(3) } : @messages
  rescue Celluloid::TimedOut
    @messages
  end

  def send(text)
    @socket.write(text)
  end

  def reject_connection
    @active = false
  end
end
