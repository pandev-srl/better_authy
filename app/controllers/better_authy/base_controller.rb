# frozen_string_literal: true

module BetterAuthy
  class BaseController < ::ApplicationController
    helper BetterAuthy::ApplicationHelper

    layout :resolve_layout
    protect_from_forgery with: :exception

    private

    def scope_name
      # Scope is injected into params via routes defaults: { scope: scope_name }
      params[:scope]
    end

    def scope_config
      @scope_config ||= BetterAuthy.scope_for!(scope_name)
    end

    def redirect_if_signed_in
      return unless send(:"#{scope_name}_signed_in?")

      redirect_to scope_config.after_sign_in_path
    end

    def resolve_layout
      return default_layout if scope_name.blank?

      scope_config.layout
    rescue BetterAuthy::ConfigurationError
      default_layout
    end

    def default_layout
      "better_authy/application"
    end
  end
end
