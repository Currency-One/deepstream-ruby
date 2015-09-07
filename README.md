# deepstream-ruby
deepstream.io ruby client


### Install

```
gem install deepstream
```


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


# Get a record
foo = ds.get('foo')

# Update record
foo.bar = 'bar'
# or
foo.set('bar', 'bar')

# Set the whole record
foo.set(foo: 'foo', bar: 1, )
