# coding: utf-8

# Copyright (c) 2015, Currency-One S.A.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'socket'
require 'json'
require 'timeout'

module Deepstream end

class Deepstream::Record
  def initialize(client, name, data, version)
    @client, @name, @data, @version = client, name, data, version
  end

  def get_name
    @name
  end

  def set(*args)
    if args.size == 1
      if @client._write('R', 'U', @name, (@version += 1), JSON.dump(args[0]))
        @data = OpenStruct.new(args[0])
      end
    else
      @client._write('R', 'P', @name, (@version += 1), args[0][0..-2], @client._typed(args[1]))
      @data[args[0][0..-2]] = args[1]
    end
  rescue => e
    print "unable to set\n"
    print "Error: ", e.message, "\n" if @client.verbose
  end

  def _patch(version, field, value)
    @version = version.to_i
    @data[field] = value
  end

  def _update(version, data)
    @version = version.to_i
    @data = data
  end

  def method_missing(name, *args)
    unless @data.is_a?(Array)
      set(name, *args) if name[-1] == '='
      @data[name] || @data[name[-1]]
    end
  end

  def inspect
    "Deepstream::Record (#{@version}) #{@name} #{@data.to_h}"
  end
end

class Deepstream::List < Deepstream::Record
  def add(record_name)
    @data = [] unless @data.is_a?(Array)
    unless @data.include? record_name
      @data.push record_name
      @client._write('R', 'U', @name, (@version += 1), JSON.dump(@data))
    end
    @data
  rescue => e
    print "unable to add ", @data.pop, "\n"
    print "Error: ", e.message, "\n" if @client.verbose
    @data
  end

  def remove(record_name)
    @data.delete_if { |x| x == record_name }
    @client._write('R', 'U', @name, (@version += 1), JSON.dump(@data))
    @data
  rescue => e
    print "unable to remove ", record_name, "\n"
    @data.push record_name
    print "Error: ", e.message, "\n" if @client.verbose
    @data
  end

  def all
    @data.map { |x| @client.get_record(x) }
  end

  def keys
    @data
  end

  def set(*args)
    fail 'cannot use set on a list'
  end

  def inspect
    "Deepstream::List (#{@version}) #{@name} keys: #{@data}"
  end
end

class Deepstream::Client
  def initialize(address, port = 6021, credentials = {})
    @address, @port, @unread_msg, @event_callbacks, @records, @max_timeout, @timeout = address, port, nil, {}, {}, 60, 1
    connect(credentials)
  end

  attr_accessor :verbose, :max_timeout
  attr_reader :connected

  def _login(credentials)
    _write("A", "REQ", credentials.to_json)
    ack = _read_socket
    raise unless ack == %w{A A} || (ack == %w{C A} && _read_socket == %w{A A})
  end

  def _read_socket(timeout: nil)
    Timeout.timeout(timeout) do
      @socket.gets(30.chr).tap { |m| break m.chomp(30.chr).split(31.chr) if m }
    end
  end

  def connect(credentials)
    return self if @connected
    Thread.start do
      Thread.current[:name] = "reader#{object_id}"
      loop do
        break if @connected # ensures only one thread remains after reconnection
        begin
          Timeout.timeout(2) { @socket = TCPSocket.new(@address, @port) }
          _login(credentials)
          @connected = true
          print Time.now.to_s[/.+ .+ /], "Connected\n" if @verbose
          Thread.start do
            _sync_records
            _resubscribe_events
          end
          loop do
            @timeout = 1
            begin
              _process_msg(_read_socket(timeout: 10))
            rescue Timeout::Error
              _write("heartbeat") # send anything to check if deepstream responds
              _process_msg(_read_socket(timeout: 10))
            end
          end
        rescue => e
          @connected = false
          @socket.close rescue nil
          print Time.now.to_s[/.+ .+ /], "Can't connect to deepstream server\n" if @verbose
          print "Error: ", e.message, "\n" if @verbose
          sleep @timeout
          @timeout = [@timeout * 1.2, @max_timeout].min
        end
      end
    end
    sleep 0.5
    self
  end

  def disconnect
    @connected = false
    @socket.close rescue nil
    Thread.list.find { |x| x[:name] == "reader#{object_id}" }.kill
    self
  end

  def emit(event, value = nil, opts = { timeout: nil })
    result = nil
    Timeout::timeout(opts[:timeout]) do
      sleep 1 until (result = _write('E', 'EVT', event, _typed(value)) rescue false) || opts[:timeout].nil?
    end
    result
  end

  def on(event, &block)
    _write_and_read('E', 'S', event)
    @event_callbacks[event] = block
  rescue => e
    print "Error: ", e.message, "\n" if @verbose
    @event_callbacks[event] = block
  end

  def get(record_name)
    get_record(record_name)
  end

  def get_record(record_name, list: nil)
    name = list ? "#{list}/#{record_name}" : record_name
    if list
      @records[list] ||= get_list(list)
      @records[list].add(name)
    end
    @records[name] ||= (
      _write_and_read('R', 'CR', name)
      msg = _read
      Deepstream::Record.new(self, name, _parse_data(msg[4]), msg[3].to_i)
    )
    @records[name]
  rescue => e
    print "Error: ", e.message, "\n" if @verbose
    @records[name] = Deepstream::Record.new(self, name, OpenStruct.new, 0)
  end

  def get_list(list_name)
    @records[list_name] ||= (
      _write_and_read('R', 'CR', list_name)
      msg = _read
      Deepstream::List.new(self, list_name, _parse_data(msg[4]), msg[3].to_i)
    )
  rescue => e
    print "Error: ", e.message, "\n" if @verbose
    @records[list_name] = Deepstream::List.new(self, list_name, [], 0)
  end

  def delete(record_name)
    if matching = record_name.match(/(?<namespace>\w+)\/(?<record>.+)/)
      tmp = get_list(matching[:namespace])
      tmp.remove(record_name)
    end
    _write('R', 'D', record_name)
  rescue => e
    print "Error: ", e.message, "\n" if @verbose
    false
  end

  def _resubscribe_events
    @event_callbacks.keys.each do |event|
      _write_and_read('E', 'S', event)
    end
  end

  def _sync_records
    @records.each do |name, record|
      _write_and_read('R', 'CR', name)
      msg = _read
      @records[name]._update(msg[3].to_i, _parse_data(msg[4]))
    end
  end

  def _write_and_read(*args)
    @unread_msg = nil
    _write(*args)
    yield _read if block_given?
  end

  def _write(*args)
    @socket.write(args.join(31.chr) + 30.chr)
  rescue => e
    raise "not connected" unless @connected
    raise e
  end

  def _process_msg(msg)
    case msg[0..1]
    when %w{E EVT} then _fire_event_callback(msg)
    when %w{R P} then @records[msg[2]]._patch(msg[3], msg[4], _parse_data(msg[5]))
    when %w{R U} then @records[msg[2]]._update(msg[3], _parse_data(msg[4]))
    when %w{R A} then @records.delete(msg[3]) if msg[2] == 'D'
    when %w{E A} then nil
    when %w{X E} then nil
    when [] then nil
    else
      @unread_msg = msg
    end
  end

  def _read
    loop { break @unread_msg || (next sleep 0.01) }.tap { @unread_msg = nil }
  end

  def _fire_event_callback(msg)
    @event_callbacks[msg[2]].tap { |cb| Thread.start { cb.(_parse_data(msg[3])) } if cb }
  end

  def _typed(value)
    case value
    when Hash then "O#{value.to_json}"
    when String then "S#{value}"
    when Numeric then "N#{value}"
    when TrueClass then 'T'
    when FalseClass then 'F'
    when NilClass then 'L'
    end
  end

  def _parse_data(payload)
    case payload[0]
    when 'O' then JSON.parse(payload[1..-1], object_class: OpenStruct)
    when '{' then JSON.parse(payload, object_class: OpenStruct)
    when 'S' then payload[1..-1]
    when 'N' then payload[1..-1].to_f
    when 'T' then true
    when 'F' then false
    when 'L' then nil
    else JSON.parse(payload, object_class: OpenStruct)
    end
  end

  def inspect
    "Deepstream::Client #{@address}:#{@port} connected: #{@connected}"
  end
end
