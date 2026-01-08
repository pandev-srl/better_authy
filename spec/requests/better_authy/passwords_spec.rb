# frozen_string_literal: true

require "rails_helper"

RSpec.describe "BetterAuthy::Passwords", type: :request do
  let(:account) { create(:account, password: "password123", password_confirmation: "password123") }

  before do
    BetterAuthy.reset_configuration!
    BetterAuthy.configure do |config|
      config.scope :account do |scope|
        scope.model_name = "Account"
        scope.password_reset_within = 1.hour
      end
    end
  end

  describe "GET /auth/account/password/new" do
    it "renders forgot password form" do
      get "/auth/account/password/new"
      expect(response).to have_http_status(:ok)
    end

    it "redirects if already signed in" do
      post "/auth/account/login", params: {
        session: { email: account.email, password: "password123" }
      }
      get "/auth/account/password/new"
      expect(response).to redirect_to("/")
    end
  end

  describe "POST /auth/account/password" do
    context "with existing email" do
      it "sends password reset email" do
        expect {
          post "/auth/account/password", params: { forgot_password: { email: account.email } }
        }.to have_enqueued_mail(BetterAuthy::PasswordResetMailer, :reset_password_instructions)
      end

      it "generates password reset token" do
        post "/auth/account/password", params: { forgot_password: { email: account.email } }
        account.reload
        expect(account.password_reset_token_digest).to be_present
        expect(account.password_reset_sent_at).to be_present
      end

      it "redirects with generic success message" do
        post "/auth/account/password", params: { forgot_password: { email: account.email } }
        expect(response).to redirect_to("/auth/account/login")
        expect(flash[:notice]).to include("instructions")
      end
    end

    context "with non-existing email" do
      it "does not send email" do
        expect {
          post "/auth/account/password", params: { forgot_password: { email: "nonexistent@example.com" } }
        }.not_to have_enqueued_mail
      end

      it "still shows generic success message (security)" do
        post "/auth/account/password", params: { forgot_password: { email: "nonexistent@example.com" } }
        expect(response).to redirect_to("/auth/account/login")
        expect(flash[:notice]).to include("instructions")
      end
    end

    context "with empty email" do
      it "re-renders form with error" do
        post "/auth/account/password", params: { forgot_password: { email: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /auth/account/password/edit" do
    let(:token) { account.generate_password_reset_token! }

    context "with valid token" do
      it "renders reset password form" do
        get "/auth/account/password/edit", params: { token: token }
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid token" do
      it "redirects with error" do
        get "/auth/account/password/edit", params: { token: "invalid" }
        expect(response).to redirect_to("/auth/account/password/new")
      end
    end

    context "with expired token" do
      it "redirects with error" do
        token = account.generate_password_reset_token!
        travel 2.hours
        get "/auth/account/password/edit", params: { token: token }
        expect(response).to redirect_to("/auth/account/password/new")
      end
    end

    context "without token" do
      it "redirects with error" do
        get "/auth/account/password/edit"
        expect(response).to redirect_to("/auth/account/password/new")
      end
    end
  end

  describe "PATCH /auth/account/password" do
    let(:token) { account.generate_password_reset_token! }

    context "with valid token and matching passwords" do
      it "updates the password" do
        patch "/auth/account/password", params: {
          reset_password: { token: token, password: "newpassword123", password_confirmation: "newpassword123" }
        }
        account.reload
        expect(account.authenticate("newpassword123")).to be_truthy
      end

      it "clears the reset token" do
        patch "/auth/account/password", params: {
          reset_password: { token: token, password: "newpassword123", password_confirmation: "newpassword123" }
        }
        account.reload
        expect(account.password_reset_token_digest).to be_nil
      end

      it "redirects to login with success message" do
        patch "/auth/account/password", params: {
          reset_password: { token: token, password: "newpassword123", password_confirmation: "newpassword123" }
        }
        expect(response).to redirect_to("/auth/account/login")
      end
    end

    context "with invalid token" do
      it "redirects with error" do
        patch "/auth/account/password", params: {
          reset_password: { token: "invalid", password: "newpassword123", password_confirmation: "newpassword123" }
        }
        expect(response).to redirect_to("/auth/account/password/new")
      end
    end

    context "with password mismatch" do
      it "re-renders form with error" do
        patch "/auth/account/password", params: {
          reset_password: { token: token, password: "newpassword123", password_confirmation: "different" }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with short password" do
      it "re-renders form with error" do
        patch "/auth/account/password", params: {
          reset_password: { token: token, password: "short", password_confirmation: "short" }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with expired token" do
      it "redirects with error" do
        token = account.generate_password_reset_token!
        travel 2.hours
        patch "/auth/account/password", params: {
          reset_password: { token: token, password: "newpassword123", password_confirmation: "newpassword123" }
        }
        expect(response).to redirect_to("/auth/account/password/new")
      end
    end
  end
end
