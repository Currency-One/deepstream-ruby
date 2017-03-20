# deepstream-ruby

deepstream.io ruby client

[![Gem Version](https://badge.fury.io/rb/deepstream.svg)](http://badge.fury.io/rb/deepstream)
[![Gem License](https://img.shields.io/badge/license-Apache-blue.svg)](https://github.com/Currency-One/deepstream-ruby/blob/master/LICENSE)

## Installation

```
gem install deepstream
```

## Usage

### Client initialization
```ruby
ds = Deepstream::Client.new('localhost')
# or
ds = Deepstream::Client.new('ws://localhost:6020')
# or
ds = Deepstream::Client.new('ws://localhost:6020/deepstream',
  ack_timeout: nil, # ACK timeout; if nil, then the client never checks ACK timeout errors
  autologin: false, # authorise the client when a Websocket connection is initialized; you don't need to call login() then
  credentials: { username: 'John', password: 'Doe' }, # credentials used to authorise the client
  heartbeat_interval: nil # when two server heartbeats are missed the client considers the connection to be lost
  max_reconnect_attempts: nil,
  max_reconnect_interval: 30, # seconds
  reconnect_interval: 1, # seconds, the final interval is a lower number from (reconnect_interval * failed_attempts, max_reconnect_interval)
  emit_timeout: 0, # if 0, then events that failed to be emitted are thrown away
                   # if nil, then events are stored in a buffer, waiting for reconnection
                   # if another number, then events are stored in a buffer and sent if the client reconnects in emit_timeout seconds
  verbose: false, # show verbose information about connection, incoming and outgoing messages etc.
  debug: false # use for testing only; if true, any exception will terminate the client
  )
# log in to the server
ds.login
# you can use new credentials too
ds.login(username: 'John', password: 'betterDoe')
# check if the websocket connection is opened
ds.connected?
# check if the client is logged in
ds.logged_in?
```
### Events
```ruby
# emit an event
ds.emit('my_event')
# or
ds.emit('my_event', foo: 'bar', bar: 'foo')
# or
ds.emit('my_event', foo: 'bar', bar: 'foo', timeout: 10) # emit with a custom timeout
# subscribe to events
ds.on('my_event') { |data| puts data }
```
### Records
```ruby
# get a record
# list is an optional argument; when given, the client adds the record to a list with given name
foo = ds.get('foo', list: 'bar')
# or
foo = ds.get_record('foo', list: 'bar')
# Update a record
foo.set('bar', 'bar') # update 'bar' attribute
# or
foo.bar = 'bar'
# or set the whole record data at once
foo.set(bar: 'bar', baz: 'baz')
```
### Lists
```ruby
# get a list
foo = ds.get_list('foo')
# add to the list
foo.add('bar')
# Remove from list
foo.remove('foo')
# show record names in the list
foo.data
# or
foo.keys
# get records from the list
foo.all
```


### Development

```bash
git submodule update --init --recursive
```