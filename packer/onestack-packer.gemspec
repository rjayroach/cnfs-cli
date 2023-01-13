# frozen_string_literal: true

require_relative 'lib/one_stack/packer/version'

Gem::Specification.new do |spec|
  spec.name          = 'onestack-packer'
  spec.version       = OneStack::Packer::VERSION
  spec.authors       = ['Robert Roach']
  spec.email         = ['rjayroach@gmail.com']

  spec.summary       = 'OneStack CLI framework'
  spec.description   = 'OneStack CLI is a pluggable framework to configure and manage OneStack projects'
  spec.homepage      = 'https://cnfs.io'
  spec.license       = 'MIT'

  spec.required_ruby_version = Gem::Requirement.new('>= 3.0.0')

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/rails-on-services/cnfs-cli'
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'onestack', '~> 0.1.0'
  spec.add_dependency 'bump', '~> 0.1'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end