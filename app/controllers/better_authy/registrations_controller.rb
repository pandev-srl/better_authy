# frozen_string_literal: true

module BetterAuthy
  class RegistrationsController < BaseController
    before_action :ensure_sign_up_enabled
    before_action :redirect_if_signed_in, only: %i[new create]

    def new
      @resource = scope_config.model_class.new
    end

    def create
      @resource = scope_config.model_class.new(resource_params)
      if @resource.save
        send(:"sign_in_#{scope_name}", @resource)
        redirect_to scope_config.after_sign_in_path
      else
        render :new, status: :unprocessable_content
      end
    end

    private

    def ensure_sign_up_enabled
      return if scope_config.sign_up_enabled?

      raise ActionController::RoutingError, "Not Found"
    end

    def resource_params
      params.require(scope_name).permit(:email, :password, :password_confirmation)
    end
  end
end
