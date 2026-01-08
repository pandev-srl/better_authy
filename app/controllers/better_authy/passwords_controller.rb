# frozen_string_literal: true

module BetterAuthy
  class PasswordsController < BaseController
    before_action :redirect_if_signed_in, only: %i[new create edit update]
    before_action :find_resource_by_token, only: %i[edit update]

    def new
      @forgot_password_form = BetterAuthy::ForgotPasswordForm.new
    end

    def create
      @forgot_password_form = BetterAuthy::ForgotPasswordForm.new(forgot_password_params)

      if @forgot_password_form.valid?
        resource = find_resource_by_email
        if resource
          token = resource.generate_password_reset_token!
          BetterAuthy::PasswordResetMailer.reset_password_instructions(
            resource, token, scope_name
          ).deliver_later
        end
        # Always show generic message to prevent email enumeration
        redirect_to send(:"#{scope_name}_login_path"),
                    notice: I18n.t("better_authy.passwords.send_instructions")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      @reset_password_form = BetterAuthy::ResetPasswordForm.new(token: params[:token])
    end

    def update
      @reset_password_form = BetterAuthy::ResetPasswordForm.new(reset_password_params)

      if @reset_password_form.valid? && @resource.reset_password!(
        @reset_password_form.password,
        @reset_password_form.password_confirmation
      )
        redirect_to send(:"#{scope_name}_login_path"),
                    notice: I18n.t("better_authy.passwords.updated")
      else
        @resource.errors.each do |error|
          @reset_password_form.errors.add(error.attribute, error.message)
        end
        render :edit, status: :unprocessable_content
      end
    end

    private

    def forgot_password_params
      params.require(:forgot_password).permit(:email)
    end

    def reset_password_params
      params.require(:reset_password).permit(:token, :password, :password_confirmation)
    end

    def find_resource_by_email
      email = forgot_password_params[:email].to_s.strip.downcase
      scope_config.model_class.find_by(email: email)
    end

    def find_resource_by_token
      token = params[:token]
      token ||= params.dig(:reset_password, :token)

      if token.blank?
        redirect_to send(:"new_#{scope_name}_password_path"),
                    alert: I18n.t("better_authy.passwords.no_token")
        return
      end

      @resource = find_resource_with_valid_token(token)

      unless @resource
        redirect_to send(:"new_#{scope_name}_password_path"),
                    alert: I18n.t("better_authy.passwords.invalid_token")
      end
    end

    def find_resource_with_valid_token(token)
      scope_config.model_class.find_each do |resource|
        return resource if resource.password_reset_token_valid?(token)
      end
      nil
    end
  end
end
