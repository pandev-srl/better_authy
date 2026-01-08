# frozen_string_literal: true

module BetterAuthy
  class ApplicationMailer < ::ActionMailer::Base
    default from: -> { default_from_address }

    private

    def default_from_address
      ENV.fetch("BETTER_AUTHY_MAILER_FROM", "noreply@example.com")
    end
  end
end
