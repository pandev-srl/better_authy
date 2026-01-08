# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"

# Only load gems for this Gemfile
Bundler.require(*Rails.groups)

# Load the engine
require "better_authy"

module Dummy
  class Application < Rails::Application
    # Explicitly set root before anything else
    config.root = File.expand_path("..", __dir__)

    # Explicitly set paths to ensure we use dummy's config, not parent app's
    paths["config/database"] = [ File.expand_path("database.yml", __dir__) ]
    paths["db/migrate"] = [ File.expand_path("../db/migrate", __dir__) ]

    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false

    # Add app/models to autoload paths
    config.autoload_paths << File.expand_path("../app/models", __dir__)

    # Required settings
    config.active_support.deprecation = :log
    config.active_support.disallowed_deprecation = :raise
    config.active_support.disallowed_deprecation_warnings = []
  end
end
