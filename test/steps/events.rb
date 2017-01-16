Given /^the client subscribes to an event named "([^"]*)"$/ do |event|
  @last_event, @event_data = nil
  @client.on(event) do |*args|
    @last_event, @last_event_data = args
  end
end

When /^the client listens to events matching "([^"]*)"$/ do |arg1|
  pending # express the regexp above with the code you wish you had
end

When /^the connection to the server is lost$/ do
  pending # express the regexp above with the code you wish you had
end

When /^the client publishes an event named "([^"]*)" with data "([^"]*)"$/ do |event, data|
  @client.emit(event, data)
end

Then /^the server did not recieve any messages$/ do
  pending # express the regexp above with the code you wish you had
end

When /^the connection to the server is reestablished$/ do
  pending # express the regexp above with the code you wish you had
end

Then /^the client received the event "([^"]*)" with data "([^"]*)"$/ do |event, data|
  sleep(1)
  expect(@last_event).to eq(event)
  expect(@last_event_data).to eq(data)
end

When /^the client unsubscribes from an event named "([^"]*)"$/ do |event|
  @client.unsubscribe(event)
end
