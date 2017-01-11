Given(/^the client is initialised with a small heartbeat interval$/) do
  @client = Deepstream::Client.new(CONFIG::ADDRESS, { heartbeat_interval: 1 })
  @client.sleep(CONFIG::CLIENT_SLEEP)
end

Then /^the server received the message (.*)$/ do |message|
  expect($server.all_messages).to include(message)
end

When /^two seconds later$/ do
  Kernel.sleep 2
end

Then /^the client throws a "([^"]*)" error with message "([^"]*)"$/ do |exception, error|
  expect(@client.state).to eq(Deepstream::CONNECTION_STATE::CLOSED)
  expect(@client.error).to eq(error)
end
