# frozen_string_literal: true

require_relative "lib/better_authy/version"

Gem::Specification.new do |spec|
  spec.name        = "better_authy"
  spec.version     = BetterAuthy::VERSION
  spec.authors     = [ "Umberto Peserico" ]
  spec.email       = [ "umberto.peserico@pandev.it" ]
  spec.homepage    = "https://github.com/pandev-srl/better_authy"
  spec.summary     = "Authentication engine for Rails with multi-scope support"
  spec.description = "A flexible authentication engine supporting multiple authenticatable models via scopes"
  spec.license     = "MIT"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.required_ruby_version = ">= 3.2.0"

  spec.add_dependency "rails", ">= 8.0", "< 8.2"
  spec.add_dependency "bcrypt", "~> 3.1"
  spec.add_dependency "view_component", "~> 4.0"
  spec.add_dependency "better_ui", "~> 0.7.1"
end
