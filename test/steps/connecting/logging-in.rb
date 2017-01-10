Given /^the server sends the message (.*)$/ do |message|
  $server.send(outgoing_message(message))
end

When /^the client logs in with username "([^"]*)" and password "([^"]*)"$/ do |username, password|
  @client.login(username: username, password: password)
end

Then /^the last message the server recieved is (.*)$/ do |message|
  expect($server.last_message).to eq(message)
end

Then /^the last login was successful$/ do
  expect(@client.connected?).to eq(true)
end

Then /^the last login failed with error message "([^"]*)"$/ do |error|
  @client.sleep(CONFIG::CLIENT_SLEEP)
  expect(@client.connected?).to eq(false)
  expect(@client.error).to eq(error)
end
