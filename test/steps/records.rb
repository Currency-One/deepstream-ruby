Given /^the client creates a record named "([^"]*)"$/ do |name|
  @client.get(name)
end

When /^the client listens to a record matching "([^"]*)"$/ do |arg1|
  pending # express the regexp above with the code you wish you had
end

When /^the client sets the record "([^"]*)" "([^"]*)" to "([^"]*)"$/ do |name, key, value|
  @client.set(name, key, value)
end

Then /^the client record "([^"]*)" data is (.*)$/ do |name, data|
  sleep(1)
  expect(@client.get(name).data).to eq(JSON.parse(data))
end

When /^the client sets the record "([^"]*)" to (.*)$/ do |name, data|
  @client.set(name, JSON.parse(data))
end

When /^the client discards the record named "([^"]*)"$/ do |name|
  @client.discard(name)
end

Given /^the client deletes the record named "([^"]*)"$/ do |name|
  @client.delete(name)
end
