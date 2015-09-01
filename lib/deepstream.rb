require 'socket'
require 'json'
require 'timeout'


module Deepstream end


class Deepstream::Client

  def initialize(address, port = 6021)
    @address, @port, @unread_msg, @event_callbacks = address, port, nil, {}
  end

  def emit(event, value = nil)
    _write('E', 'EVT', event, _typed(value))
  end

  def on(event, &block)
    _write_and_read('E', 'S', event) { |msg| msg == %W{E A S #{event}} }
    @event_callbacks[event] = block
  end


  private
  def _open_socket
    timeout(2) { @socket = TCPSocket.new(@address, @port) }
    Thread.start do
      loop { _process_msg(@socket.gets(30.chr).tap { |m| break m.chomp(30.chr).split(31.chr) if m }) }
    end
  rescue
    print Time.now.to_s[/.+ .+ /], "Can't connect to deepstream server\n"
    raise
  end

  def _connect
    _open_socket
    @connected = true
    @connected = _write_and_read(%w{A REQ {}}) { |msg| msg == %w{A A} }
  end

  def _write_and_read(*args)
    @unread_msg = nil
    _write(*args)
    yield _read
  end

  def _write(*args)
    _connect unless @connected
    @socket.write(args.join(31.chr) + 30.chr)
  rescue
    @connected = false
  end

  def _process_msg(msg)
    (msg[0..1] == %w{E EVT} ? _fire_event_callback(msg) : @unread_msg = msg) if msg
  end

  def _read
    loop { break @unread_msg || (next sleep(0.05)) }.tap { @unread_msg = nil }
  end

  def _fire_event_callback(msg)
    @event_callbacks[msg[2]].tap { |cb| cb.(_parse_data(msg[3])) if cb }
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
    when 'S' then payload[1..-1]
    when 'N' then payload[1..-1].to_f
    when 'T' then true
    when 'F' then false
    when 'L' then nil
    end
  end

end
