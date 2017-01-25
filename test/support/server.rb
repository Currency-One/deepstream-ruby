require 'reel'
require_relative 'helpers'

class StubServer < Reel::Server::HTTP
  attr_accessor :clients, :client, :url, :second_url

  extend Forwardable

  def_delegators :@client, :send_message, :messages, :last_message, :all_messages, :reject_connection

  def initialize(host = CONFIG::IP, port = CONFIG::PORT)
    @url = "ws://#{host}:#{port}/deepstream"
    @second_url = "ws://#{host}:#{CONFIG::SECOND_PORT}/deepstream"
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

  def remove_connections(close_sockets = false)
    @clients.each { |c| c.socket.close if close_sockets }
    .each { |c| c.async.terminate rescue nil }.clear
    @client = nil
  end

  def close(close_sockets = false)
    remove_connections(close_sockets)
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
    Future.new { (@messages << incoming_message(@socket.read)).last }.value(timeout)
  end

  def all_messages
    @active ? loop { last_message(3) } : @messages
  rescue Celluloid::TimedOut
    @messages
  end

  def send_message(text)
    @socket.write(text)
  end

  def reject_connection
    @active = false
  end
end
