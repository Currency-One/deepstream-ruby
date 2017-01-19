require 'celluloid/test'
require 'pry'
require_relative '../../lib/deepstream'

module CONFIG
  IP = 'localhost'
  PORT = 7777
  SECOND_PORT = 8888
  ADDRESS = "ws://#{IP}:#{PORT}/deepstream"
  MESSAGE_TIMEOUT = 5
  ACK_TIMEOUT = 3
  CLIENT_SLEEP = 0.2
  MESSAGE_PART_SEPARATOR = '|'
  MESSAGE_SEPARATOR = '+'
end

def outgoing_message(message)
  message.gsub(CONFIG::MESSAGE_PART_SEPARATOR, Deepstream::MESSAGE_PART_SEPARATOR)
  .gsub(CONFIG::MESSAGE_SEPARATOR, Deepstream::MESSAGE_SEPARATOR)
end

def incoming_message(message)
  message.gsub(Deepstream::MESSAGE_PART_SEPARATOR, CONFIG::MESSAGE_PART_SEPARATOR)
  .gsub(Deepstream::MESSAGE_SEPARATOR, CONFIG::MESSAGE_SEPARATOR)
end
