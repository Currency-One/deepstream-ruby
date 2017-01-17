Given(/^the test server is ready$/) do
  ($server ||= StubServer.new).remove_connections
end

Then(/^the server has (\d+) active connections$/) do |number|
  expect($server.clients.select(&:active).count).to eq(number.to_i)
end

Given(/^the client is initialised$/) do
  @client = Deepstream::Client.new(CONFIG::ADDRESS, { autologin: false, ack_timeout: CONFIG::ACK_TIMEOUT })
  @client.sleep(CONFIG::CLIENT_SLEEP)
end

Then(/^the clients connection state is "([^"]*)"$/) do |state|
  @client.sleep(CONFIG::CLIENT_SLEEP)
  expect(@client.state.to_s.upcase).to eq(state)
end
Given(/^the client is initialised with a small heartbeat interval$/) do
  @client = Deepstream::Client.new(CONFIG::ADDRESS, { autologin: false, heartbeat_interval: 1 })
  @client.sleep(CONFIG::CLIENT_SLEEP)
end

Then /^the server received the message (.*)$/ do |message|
  expect($server.all_messages).to include(message)
end

When /^two seconds later$/ do
  sleep(2)
end

Then /^the client throws a "([^"]*)" error with message "([^"]*)"$/ do |exception, error|
  expect(@client.error).to eq(error)
end
Given /^the second test server is ready$/ do
  ($second_server ||= StubServer.new(CONFIG::IP, CONFIG::SECOND_PORT)).remove_connections
end

Given /^the second server has (\d+) active connections$/ do |number|
  expect($second_server.clients.select(&:active).count).to eq(number.to_i)
end

Then /^the server has received (\d+) messages$/ do |number|
  expect($server.all_messages.size).to eq(number.to_i)
end

When /^some time passes$/ do
  sleep(5)
end

Then /^the client is on the second server$/ do
  $first_server = $server
  $server = $second_server
end

Then /^the last message the server recieved is (C\|CHR\|(<FIRST_SERVER_URL>)\+)$/ do |message, url|
  expect($server.last_message).to eq(message.sub(url, $server.url))
end

When /the server sends the message (C\|RED\|(<SECOND_SERVER_URL>)\+)$/ do |message, url|
  $server.send(outgoing_message(message.sub(url, $server.second_url)))
  $server.remove_connections # because we reject the connection and redirect the client to another server
end

When /^the server sends the message C\|REJ\+$/ do
  $server.send(outgoing_message("C|REJ+"))
  $server.reject_connection
end
Given /^the server sends the message (.*)$/ do |message|
  $server.send(outgoing_message(message))
end

When /^the client logs in with username "([^"]*)" and password "([^"]*)"$/ do |username, password|
  @client.login(username: username, password: password)
end

Then /^the last message the server recieved is (.*)$/ do |message|
  expect($server.all_messages.last).to eq(message)
end

Then /^the last login was successful$/ do
  expect(@client.connected?).to eq(true)
end

Then /^the last login failed with error message "([^"]*)"$/ do |error|
  @client.sleep(CONFIG::CLIENT_SLEEP)
  expect(@client.connected?).to eq(false)
  expect(@client.error).to eq(error)
end
