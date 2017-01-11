Given /^the second test server is ready$/ do
  ($second_server ||= StubServer.new(CONFIG::IP, CONFIG::SECOND_PORT)).remove_connections
end

Given /^the second server has (\d+) active connections$/ do |number|
  expect($second_server.clients.size).to eq(number.to_i)
end

Then /^the server has received (\d+) messages$/ do |number|
  expect($second_server.all_messages.size).to eq(number.to_i)
end

When /^some time passes$/ do
  sleep(5)
end

Then /^the client is on the second server$/ do
  $server.shutdown
  $server = $second_server
end

Then /^the last message the server recieved is (C\|CHR\|(<FIRST_SERVER_URL>)\+)$/ do |message, url|
  expect($server.last_message).to eq(message.sub(url, $server.url))
end

When /the server sends the message (C\|RED\|(<SECOND_SERVER_URL>)\+)$/ do |message, url|
  $server.send(outgoing_message(message.sub(url, $server.second_url)))
  $server.remove_connections # because we reject the connection and redirect the client to another server
end
