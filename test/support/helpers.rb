require 'celluloid/test'
require 'pry'
require_relative '../../lib/deepstream'

module CONFIG
  IP = '127.0.0.1'
  PORT = 7777
  ADDRESS = "ws://#{IP}:#{PORT}"
  MESSAGE_TIMEOUT = 5
  CLIENT_SLEEP = 0.2
  MESSAGE_PART_SEPARATOR = '|'
  MESSAGE_SEPARATOR = '+'
end

def outgoing_message(message)
  message.gsub(CONFIG::MESSAGE_PART_SEPARATOR, Deepstream::MESSAGE_PART_SEPARATOR)
  .gsub(CONFIG::MESSAGE_SEPARATOR, Deepstream::MESSAGE_SEPARATOR)
end

def incoming_message(message)
  message[1..-1]
  .gsub(Deepstream::MESSAGE_PART_SEPARATOR, CONFIG::MESSAGE_PART_SEPARATOR)
  .gsub(Deepstream::MESSAGE_SEPARATOR, CONFIG::MESSAGE_SEPARATOR)
  .concat(CONFIG::MESSAGE_SEPARATOR)
end
