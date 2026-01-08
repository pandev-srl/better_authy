# frozen_string_literal: true

require "spec_helper"
ENV["RAILS_ENV"] = "test"

# Load the dummy application
require_relative "dummy/config/environment"

abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "shoulda/matchers"
require "factory_bot_rails"

# Configure FactoryBot to load factories from the engine's spec/factories directory
FactoryBot.definition_file_paths = [ File.expand_path("factories", __dir__) ]
FactoryBot.find_definitions

# Load support files
Dir[File.join(__dir__, "support", "**", "*.rb")].each { |f| require f }

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # Include FactoryBot methods
  config.include FactoryBot::Syntax::Methods

  # Include ActiveSupport::Testing::TimeHelpers for travel/freeze_time
  config.include ActiveSupport::Testing::TimeHelpers
end
