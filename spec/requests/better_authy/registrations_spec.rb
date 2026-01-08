# frozen_string_literal: true

require "rails_helper"

RSpec.describe "BetterAuthy::Registrations", type: :request do
  before do
    BetterAuthy.reset_configuration!
    BetterAuthy.configure do |config|
      config.scope :account do |scope|
        scope.model_name = "Account"
        scope.remember_for = 2.weeks
      end
    end
  end

  describe "GET /auth/account/signup" do
    it "renders signup form" do
      get "/auth/account/signup"
      expect(response).to have_http_status(:ok)
    end

    it "redirects if already signed in" do
      account = create(:account, password: "password123", password_confirmation: "password123")
      post "/auth/account/login", params: {
        session: { email: account.email, password: "password123" }
      }
      get "/auth/account/signup"
      expect(response).to redirect_to("/")
    end
  end

  describe "POST /auth/account/signup" do
    let(:valid_params) do
      {
        account: {
          email: "new@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    it "creates account with valid params" do
      expect {
        post "/auth/account/signup", params: valid_params
      }.to change(Account, :count).by(1)
    end

    it "signs in the new account" do
      post "/auth/account/signup", params: valid_params
      expect(session[:account_id]).to be_present
    end

    it "redirects to after_sign_in_path" do
      post "/auth/account/signup", params: valid_params
      expect(response).to redirect_to("/")
    end

    it "tracks sign in for the new account" do
      post "/auth/account/signup", params: valid_params
      new_account = Account.find_by(email: "new@example.com")
      expect(new_account.sign_in_count).to eq(1)
      expect(new_account.current_sign_in_at).to be_present
    end

    it "fails with invalid email" do
      post "/auth/account/signup", params: {
        account: { email: "", password: "password123", password_confirmation: "password123" }
      }
      expect(response).to have_http_status(:unprocessable_content)
      expect(Account.count).to eq(0)
    end

    it "fails with short password" do
      post "/auth/account/signup", params: {
        account: { email: "test@example.com", password: "short", password_confirmation: "short" }
      }
      expect(response).to have_http_status(:unprocessable_content)
      expect(Account.count).to eq(0)
    end

    it "fails with password mismatch" do
      post "/auth/account/signup", params: {
        account: { email: "test@example.com", password: "password123", password_confirmation: "different" }
      }
      expect(response).to have_http_status(:unprocessable_content)
      expect(Account.count).to eq(0)
    end

    it "fails with duplicate email" do
      create(:account, email: "existing@example.com")
      post "/auth/account/signup", params: {
        account: { email: "existing@example.com", password: "password123", password_confirmation: "password123" }
      }
      expect(response).to have_http_status(:unprocessable_content)
      expect(Account.where(email: "existing@example.com").count).to eq(1)
    end
  end
end
