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

# Get a record with a namespace (automaticly add to a list)
foo = ds.get_record('foo', list: 'bar') # record can also be accessed by ds.get('bar/foo')

# Update record
foo.bar = 'bar'
# or
foo.set('bar', 'bar')

# Set the whole record
foo.set(foo: 'foo', bar: 1, )

# Get a list
foo = ds.get_list('bar')

# Add to list
foo.add('foo')

# Remove from list
foo.remove('foo')

# Show record names on the list
foo.keys()

# Access records on the list
foo.all()
