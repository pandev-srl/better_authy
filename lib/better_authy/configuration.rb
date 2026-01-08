# frozen_string_literal: true

module BetterAuthy
  class Configuration
    attr_reader :scopes, :cookie_config

    def initialize
      @scopes = {}
      @cookie_config = {
        secure: ENV.fetch("BETTER_AUTHY_SECURE_COOKIES", "false") == "true",
        httponly: true,
        same_site: :lax
      }
    end

    def cookie_config=(options)
      @cookie_config = @cookie_config.merge(options)
    end

    def scope(name, &block)
      raise ArgumentError, "scope requires a block" unless block_given?

      name = name.to_sym
      raise ConfigurationError, "Scope :#{name} is already registered" if @scopes.key?(name)

      scope_config = ScopeConfiguration.new(name)
      yield(scope_config)
      @scopes[name] = scope_config
    end

    def scope_for(name)
      @scopes[name.to_sym]
    end

    def scope_for!(name)
      scope_for(name) || raise(ConfigurationError, "Scope :#{name} is not registered")
    end

    def validate!
      @scopes.each_value(&:validate!)
    end
  end
end
