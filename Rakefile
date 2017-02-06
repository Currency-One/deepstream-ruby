require 'cucumber/rake/task'

Cucumber::Rake::Task.new(:test) do |t|
  t.cucumber_opts = "--guess -r test/ test/features/"
end

task default: :test
