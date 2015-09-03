# deepstream-ruby
deepstream.io ruby client


### Usage

```ruby
ds = Deepstream::Client.new('localhost')

# Emit events

ds.emit 'my_event'
# or
ds.emit 'my_event', foo: 'bar', bar: 'foo'


# Subscribe to events
ds.on('some_event') do |msg|
  puts msg
end


# Get records
foo = ds.get('foo')

# Update record
foo.bar = 'bar'
# or
foo.set('bar', 'bar')

# Set whole record
foo.set(foo: 'foo', bar: 1, )

```
