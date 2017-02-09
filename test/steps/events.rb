Given /^the client subscribes to an event named "([^"]*)"$/ do |event|
  @last_event, @event_data = nil
  @client.on(event) do |data|
    @last_event = event
    @last_event_data = data
  end
end

When /^the client listens to events matching "([^"]*)"$/ do |pattern|
  @last_event_match, @is_subscribed = nil
  @client.listen(pattern) { |*args| @is_subscribed, @last_event_match = args }
end

When /^the connection to the server is lost$/ do
  $server.close(true)
end

When /^the client publishes an event named "([^"]*)" with data "([^"]*)"$/ do |event, data|
  @client.emit(event, data)
end

Then /^the server did not recieve any messages$/ do
  expect($server.clients.size).to eq(0)
  expect($server.client).to eq(nil)
end

When /^the connection to the server is reestablished$/ do
  ($server = StubServer.new).remove_connections
  sleep(5)
  expect(@client.connected?).to eq(true)
end

Then /^the client received the event "([^"]*)" with data "([^"]*)"$/ do |event, data|
  sleep(1)
  expect(@last_event).to eq(event)
  expect(@last_event_data).to eq(data)
end

When /^the client unsubscribes from an event named "([^"]*)"$/ do |event|
  @client.unsubscribe(event)
end

Given /^the server resets its message count$/ do
  $server.all_messages.clear
end

When /^the client unlistens to events matching "([^"]*)"$/ do |pattern|
  @client.unlisten(pattern)
end

Then /^the client will be notified of new event match "([^"]*)"$/ do |event|
  sleep(1)
  expect(@last_event_match).to eq(event)
  expect(@is_subscribed).to eq(true)
end

Then /^the client will be notified of event match removal "([^"]*)"$/ do |event|
  sleep(1)
  expect(@last_event_match).to eq(event)
  expect(@is_subscribed).to eq(false)
end
