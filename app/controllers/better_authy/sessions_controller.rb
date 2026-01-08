# frozen_string_literal: true

module BetterAuthy
  class SessionsController < BaseController
    before_action :redirect_if_signed_in, only: %i[new create]

    def new
      @session_form = BetterAuthy::SessionForm.new(email: params.dig(:session, :email))
    end

    def create
      @session_form = BetterAuthy::SessionForm.new(session_params)

      # debugger

      resource = find_resource_by_email
      if resource&.authenticate(session_params[:password])
        remember = @session_form.remember_me
        send(:"sign_in_#{scope_name}", resource, remember: remember)
        redirect_to scope_config.after_sign_in_path
      else
        render_invalid_credentials
      end
    end

    def destroy
      send(:"sign_out_#{scope_name}")
      redirect_to scope_config.after_sign_in_path
    end

    private

    def session_params
      params.require(:session).permit(:email, :password, :remember_me)
    end

    def find_resource_by_email
      email = session_params[:email].to_s.strip.downcase
      scope_config.model_class.find_by(email: email)
    end

    def render_invalid_credentials
      flash.now[:alert] = I18n.t("better_authy.sessions.invalid_credentials",
                                  default: "Invalid email or password")
      render :new, status: :unprocessable_content
    end
  end
end
