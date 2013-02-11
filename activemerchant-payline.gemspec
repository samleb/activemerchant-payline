# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "activemerchant-payline"
  gem.version       = "0.0.1.alpha1"
  gem.authors       = ["Samuel Lebeau"]
  gem.email         = ["samuel.lebeau@gmail.com"]
  gem.summary       = %q{Partial ActiveMerchant implementation of the Payline Gateway.}
  gem.homepage      = "https://github.com/Goldmund/activemerchant-payline"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  
  gem.add_dependency 'activemerchant', '~> 1.0'
  gem.add_dependency 'savon', '~> 1.0'
  gem.add_dependency 'builder', '~> 3.0'
end
