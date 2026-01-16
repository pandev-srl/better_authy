# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "sqlite3"

# UI Components
gem "better_ui", "~> 0.7.2"
gem "view_component", "~> 4.1"
gem "tailwind_merge", "~> 0.12"

# Omakase Ruby styling
gem "rubocop-rails-omakase", require: false

group :development, :test do
  gem "rspec-rails", "~> 8.0"
  gem "debug"
end

group :test do
  gem "simplecov", require: false
  gem "shoulda-matchers"
  gem "factory_bot_rails"
  gem "faker"
end
