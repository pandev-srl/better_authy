# frozen_string_literal: true

require "rails_helper"

RSpec.describe BetterAuthy::PasswordResetMailer, type: :mailer do
  let(:account) { create(:account) }
  let(:token) { "test_token_abc123" }

  before do
    BetterAuthy.reset_configuration!
    BetterAuthy.configure do |config|
      config.scope :account do |scope|
        scope.model_name = "Account"
        scope.password_reset_within = 1.hour
      end
    end
  end

  describe "#reset_password_instructions" do
    let(:mail) { described_class.reset_password_instructions(account, token, :account) }

    it "renders the headers" do
      expect(mail.subject).to eq(I18n.t("better_authy.passwords.mailer.subject"))
      expect(mail.to).to eq([ account.email ])
    end

    it "includes the token in the body" do
      expect(mail.body.encoded).to include(token)
    end

    it "includes the account email in the body" do
      expect(mail.body.encoded).to include(account.email)
    end

    it "generates reset URL using route helpers with default_url_options" do
      expect(mail.body.encoded).to include("http://example.com/auth/account/password/edit?token=#{token}")
    end

    context "with Italian locale" do
      around do |example|
        I18n.with_locale(:it) { example.run }
      end

      it "uses Italian subject" do
        expect(mail.subject).to eq("Istruzioni per reimpostare la password")
      end
    end

    context "with English locale" do
      around do |example|
        I18n.with_locale(:en) { example.run }
      end

      it "uses English subject" do
        expect(mail.subject).to eq("Password Reset Instructions")
      end
    end
  end
end
