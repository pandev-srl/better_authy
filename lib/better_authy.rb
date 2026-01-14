# frozen_string_literal: true

require "bcrypt"
require "better_ui"

require "better_authy/version"
require "better_authy/errors"
require "better_authy/scope_configuration"
require "better_authy/configuration"
require "better_authy/engine"
require "better_authy/models/authenticable"
require "better_authy/model_extensions"
require "better_authy/controller_helpers"

module BetterAuthy
  class << self
    def configure
      yield(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def reset_configuration!
      @configuration = Configuration.new
    end

    def scope_for(name)
      configuration.scope_for(name)
    end

    def scope_for!(name)
      configuration.scope_for!(name)
    end
  end
end
