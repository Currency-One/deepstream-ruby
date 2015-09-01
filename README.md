# deepstream-ruby
deepstream.io ruby client


### Usage

```ruby
ds_client = Deepstream::Client.new('localhost')

ds_client.emit 'my_event'

ds_client.on('some_event') do |msg|
  puts msg
end
```

