# frozen_string_literal: true

require "rails_helper"

RSpec.describe "BetterAuthy::Sessions", type: :request do
  let(:account) { create(:account, password: "password123", password_confirmation: "password123") }

  before do
    BetterAuthy.reset_configuration!
    BetterAuthy.configure do |config|
      config.scope :account do |scope|
        scope.model_name = "Account"
        scope.remember_for = 2.weeks
      end
    end
  end

  describe "GET /auth/account/login" do
    it "renders login form" do
      get "/auth/account/login"
      expect(response).to have_http_status(:ok)
    end

    it "redirects if already signed in" do
      post "/auth/account/login", params: {
        session: { email: account.email, password: "password123" }
      }
      get "/auth/account/login"
      expect(response).to redirect_to("/")
    end
  end

  describe "POST /auth/account/login" do
    it "signs in with valid credentials" do
      post "/auth/account/login", params: {
        session: { email: account.email, password: "password123" }
      }
      expect(response).to redirect_to("/")
      expect(session[:account_id]).to eq(account.id)
    end

    it "fails with invalid credentials" do
      post "/auth/account/login", params: {
        session: { email: account.email, password: "wrong" }
      }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "fails with non-existent email" do
      post "/auth/account/login", params: {
        session: { email: "nonexistent@example.com", password: "password123" }
      }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "sets remember cookie when remember_me checked" do
      post "/auth/account/login", params: {
        session: { email: account.email, password: "password123", remember_me: "1" }
      }
      expect(cookies[:_remember_account_token]).to be_present
    end

    it "does not set remember cookie when remember_me is not checked" do
      post "/auth/account/login", params: {
        session: { email: account.email, password: "password123" }
      }
      expect(cookies[:_remember_account_token]).to be_blank
    end

    it "tracks sign in on successful login" do
      post "/auth/account/login", params: {
        session: { email: account.email, password: "password123" }
      }
      account.reload
      expect(account.sign_in_count).to eq(1)
      expect(account.current_sign_in_at).to be_present
    end
  end

  describe "DELETE /auth/account/logout" do
    before do
      post "/auth/account/login", params: {
        session: { email: account.email, password: "password123", remember_me: "1" }
      }
    end

    it "signs out and redirects" do
      delete "/auth/account/logout"
      expect(response).to redirect_to("/")
    end

    it "clears session" do
      delete "/auth/account/logout"
      expect(session[:account_id]).to be_nil
    end

    it "clears remember cookie" do
      delete "/auth/account/logout"
      expect(cookies[:_remember_account_token]).to be_blank
    end

    it "clears remember token from account" do
      delete "/auth/account/logout"
      account.reload
      expect(account.remember_token_digest).to be_nil
    end
  end
end
