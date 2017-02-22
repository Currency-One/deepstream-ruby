# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "deepstream"
  spec.version       = "0.2.9"
  spec.authors       = ["Currency-One S.A."]
  spec.email         = ["piotr.szczudlak@currency-one.com"]

  spec.summary       = %q{deepstream.io ruby client}
  spec.description   = %q{Basic ruby client for the deepstream.io server}
  spec.homepage      = "https://github.com/Currency-One/deepstream-ruby"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.files         += Dir['lib/**/*.rb']
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.required_ruby_version = '>= 2.3.0'
  spec.license       = "Apache-2.0"
  spec.add_runtime_dependency 'celluloid-websocket-client', '~> 0'
  spec.add_development_dependency 'cucumber'
  spec.add_development_dependency 'reel'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rspec-expectations'
  spec.add_development_dependency 'rake'
end
