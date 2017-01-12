Before do
  Celluloid.boot
end

After do |scenario|
  if $second_server
    [$server, $second_server].map(&:close)
    $server, $second_server = nil
    if $first_server
      $first_server.close
      $first_server = nil
    end
  end
  if scenario.failed?
    puts "Scenario failed: #{scenario.exception}"
  end
end
