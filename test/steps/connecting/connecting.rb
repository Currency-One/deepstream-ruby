Given(/^the test server is ready$/) do
  ($server ||= StubServer.new).remove_connections
end

Then(/^the server has (\d+) active connections$/) do |number|
  expect($server.clients.count).to eq(number.to_i)
end

Given(/^the client is initialised$/) do
  @client = Deepstream::Client.new(CONFIG::ADDRESS)
  @client.sleep(CONFIG::CLIENT_SLEEP)
end

Then(/^the clients connection state is "([^"]*)"$/) do |state|
  @client.sleep(CONFIG::CLIENT_SLEEP)
  expect(@client.state.to_s.upcase).to eq(state)
end
