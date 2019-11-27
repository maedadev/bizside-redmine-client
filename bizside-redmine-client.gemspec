lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "bizside/redmine/client/version"

Gem::Specification.new do |spec|
  spec.name          = "bizside-redmine-client"
  spec.version       = Bizside::Redmine::Client::VERSION
  spec.authors       = ["y-matsuda"]
  spec.email         = ["matsuda@lab.acs-jp.com"]

  spec.summary       = %q{redmine client for bizside}
  spec.description   = %q{operate redmine server using api request in bizside}
  spec.homepage      = "https://github.com/maedadev/bizside-redmine-client"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'faraday', '~> 0.12'
  spec.add_dependency 'activesupport', '>= 3.2', '< 6.0.0'
  spec.add_dependency 'nokogiri', '~> 1.10'

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency 'webmock', '~> 3.0'
end
