# deepstream-ruby
deepstream.io ruby client

### Install

```
gem install deepstream
```

### Usage
```ruby
ds = Deepstream::Client.new('localhost',
  autologin: false,
  verbose: true,
  credentials: { username: 'John', password: 'Doe' })
# or
ds = Deepstream::Client.new('ws://localhost:6020')
# or
ds = Deepstream::Client.new('ws://localhost:6020/deepstream')

# log in to the server
ds.login
# you can use new credentials too
ds.login(username: 'John', password: 'betterDoe')

# check if the websocket connection is opened
ds.connected?

# check if the client is logged in
ds.logged_in?

# Emit events
ds.emit 'my_event'
# or
ds.emit 'my_event', foo: 'bar', bar: 'foo'

# Subscribe to events
ds.on('some_event') do |event_name, msg|
  puts msg
end

# Get a record
foo = ds.get('foo')
bar = ds.get('bar', list: 'bar_list') # get a record within a namespace (this one automatically adds it to a list)

# Update a record
foo.set('bar', 'bar')

# Set the whole record
foo.set(foo: 'foo', bar: 1)

# Get a list
foo = ds.get_list('bar')

# Add to the list
foo.add('foo')

# Remove from list
foo.remove('foo')

# Show record names on the list
foo.data
# or
foo.keys

# Access records on the list
foo.all
