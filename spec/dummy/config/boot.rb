# frozen_string_literal: true

# Set up gems listed in the ENGINE's Gemfile (not the main app's)
ENGINE_ROOT = File.expand_path("../../../..", __dir__)
ENV["BUNDLE_GEMFILE"] ||= File.join(ENGINE_ROOT, "Gemfile")

# Force SQLite for test database (overrides any DATABASE_URL from parent)
ENV["DATABASE_URL"] = "sqlite3:db/test.sqlite3"

require "bundler/setup"

# Add engine lib to load path
$LOAD_PATH.unshift File.join(ENGINE_ROOT, "lib")
