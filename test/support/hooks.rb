Before do
  Celluloid.boot
end

After do |scenario|
  if scenario.failed?
    puts "Scenario failed: #{scenario.exception}"
  end
end
