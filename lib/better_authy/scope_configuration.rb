# frozen_string_literal: true

module BetterAuthy
  class ScopeConfiguration
    attr_reader :name
    attr_accessor :model_name, :session_key, :remember_cookie, :remember_for,
                  :sign_in_path, :after_sign_in_path, :layout, :password_reset_within

    def initialize(name)
      @name = name.to_sym
      @session_key = :"#{name}_id"
      @remember_cookie = :"_remember_#{name}_token"
      @remember_for = 2.weeks
      @password_reset_within = 1.hour
      @sign_in_path = "/auth/#{name}/login"
      @after_sign_in_path = "/"
      @layout = "better_authy/application"
    end

    def model_class
      raise ConfigurationError, "model_name is required for scope :#{name}" if model_name.blank?

      model_name.constantize
    end

    def validate!
      raise ConfigurationError, "model_name is required for scope :#{name}" if model_name.blank?
    end
  end
end
