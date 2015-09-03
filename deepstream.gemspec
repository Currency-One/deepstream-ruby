# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "deepstream"
  spec.version       = "0.0.3"
  spec.authors       = ["Piotr Szczudlak"]
  spec.email         = ["thisredoned@gmail.com"]

  spec.summary       = %q{deepstream.io ruby client}
  spec.description   = %q{Basic ruby client for the deepstream.io server}
  spec.homepage      = "https://github.com/thisredone/deepstream-ruby"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.license       = "Apache License 2.0"
end
