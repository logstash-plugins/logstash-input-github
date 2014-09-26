# -*- encoding: utf-8 -*-
require File.expand_path('../lib/logstash/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jason Kendall"]
  gem.email         = ["jason.kendall@ostlabs.com"]
  gem.description   = %q{A description}
  gem.summary       = %q{logstash-pluginname}
  gem.homepage      = "https://github.com/coolacid/logstash-github"
  gem.license       = "Apache License (2.0)"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "logstash-github"
  gem.require_paths = ["lib"]
  gem.version       = LOGSTASH_VERSION
end
