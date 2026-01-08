# frozen_string_literal: true

module BetterAuthy
  class PasswordResetMailer < ApplicationMailer
    include BetterAuthy::Engine.routes.url_helpers

    def reset_password_instructions(resource, token, scope_name)
      @resource = resource
      @token = token
      @scope_name = scope_name
      @scope_config = BetterAuthy.scope_for!(scope_name)
      @reset_url = send(:"edit_#{scope_name}_password_url", token: token)

      mail(
        to: resource.email,
        subject: I18n.t("better_authy.passwords.mailer.subject")
      )
    end
  end
end
