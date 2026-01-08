# frozen_string_literal: true

require "rails_helper"

RSpec.describe BetterAuthy::ControllerHelpers do
  # Test cookie jar that supports encrypted cookies
  let(:cookie_store) { {} }
  let(:cookies) do
    store = cookie_store
    double("cookies").tap do |c|
      allow(c).to receive(:encrypted) do
        double("encrypted_cookies").tap do |ec|
          allow(ec).to receive(:[]=) { |key, value| store[key] = value.is_a?(Hash) ? value[:value] : value }
          allow(ec).to receive(:[]) { |key| store[key] }
        end
      end
      allow(c).to receive(:delete) { |key| store.delete(key) }
    end
  end

  let(:session) { {} }
  let(:request) { double("request", remote_ip: "192.168.1.1") }

  let(:account) do
    Account.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  # Helper to build controller class with current configuration
  # Use ActionController::Base directly to avoid inheriting pre-included modules from ApplicationController
  def build_controller_class
    Class.new(ActionController::Base) do
      include BetterAuthy::ControllerHelpers
    end
  end

  # Helper to build and configure controller instance
  def build_controller(klass = nil)
    klass ||= build_controller_class
    klass.new.tap do |c|
      allow(c).to receive(:session).and_return(session)
      allow(c).to receive(:cookies).and_return(cookies)
      allow(c).to receive(:request).and_return(request)
      allow(c).to receive(:reset_session) { session.clear }
      allow(c).to receive(:redirect_to)
    end
  end

  before do
    BetterAuthy.reset_configuration!
    BetterAuthy.configure do |config|
      config.scope :account do |scope|
        scope.model_name = "Account"
        scope.remember_for = 2.weeks
      end
    end
  end

  describe "dynamic method generation" do
    let(:controller) { build_controller }

    it "defines current_{scope} method" do
      expect(controller).to respond_to(:current_account)
    end

    it "defines {scope}_signed_in? method" do
      expect(controller).to respond_to(:account_signed_in?)
    end

    it "defines sign_in_{scope} method" do
      expect(controller).to respond_to(:sign_in_account)
    end

    it "defines sign_out_{scope} method" do
      expect(controller).to respond_to(:sign_out_account)
    end

    it "defines authenticate_{scope}! method" do
      expect(controller).to respond_to(:authenticate_account!)
    end
  end

  describe "#current_{scope}" do
    let(:controller) { build_controller }

    context "when not signed in" do
      it "returns nil" do
        expect(controller.current_account).to be_nil
      end
    end

    context "when signed in via session" do
      before { session[:account_id] = account.id }

      it "returns the account" do
        expect(controller.current_account).to eq(account)
      end

      it "caches the result" do
        expect(Account).to receive(:find_by).once.and_call_original
        2.times { controller.current_account }
      end
    end

    context "when signed in via remember cookie" do
      let(:token) { account.remember_me! }

      before do
        cookie_store[:_remember_account_token] = "#{account.id}:#{token}"
      end

      it "returns the account" do
        expect(controller.current_account).to eq(account)
      end

      it "validates the token" do
        cookie_store[:_remember_account_token] = "#{account.id}:wrong_token"
        expect(controller.current_account).to be_nil
      end
    end

    context "when session has invalid account id" do
      before { session[:account_id] = "non-existent-id" }

      it "returns nil" do
        expect(controller.current_account).to be_nil
      end
    end

    context "when remember cookie has expired token" do
      let(:token) { account.remember_me! }

      before do
        cookie_store[:_remember_account_token] = "#{account.id}:#{token}"
        travel BetterAuthy.scope_for(:account).remember_for + 1.day
      end

      it "returns nil" do
        expect(controller.current_account).to be_nil
      end
    end
  end

  describe "#account_signed_in?" do
    let(:controller) { build_controller }

    context "when not signed in" do
      it "returns false" do
        expect(controller.account_signed_in?).to be false
      end
    end

    context "when signed in via session" do
      before { session[:account_id] = account.id }

      it "returns true" do
        expect(controller.account_signed_in?).to be true
      end
    end

    context "when signed in via remember cookie" do
      let(:token) { account.remember_me! }

      before do
        cookie_store[:_remember_account_token] = "#{account.id}:#{token}"
      end

      it "returns true" do
        expect(controller.account_signed_in?).to be true
      end
    end
  end

  describe "#sign_in_{scope}" do
    let(:controller) { build_controller }

    it "stores account id in session" do
      controller.sign_in_account(account)
      expect(session[:account_id]).to eq(account.id)
    end

    it "calls track_sign_in! on the account" do
      expect(account).to receive(:track_sign_in!).with(request)
      controller.sign_in_account(account)
    end

    it "resets session to prevent fixation" do
      session[:old_key] = "old_value"
      controller.sign_in_account(account)
      expect(session[:old_key]).to be_nil
    end

    context "with remember: true" do
      it "sets remember cookie" do
        controller.sign_in_account(account, remember: true)
        expect(cookie_store[:_remember_account_token]).to be_present
      end

      it "calls remember_me! on the account" do
        expect(account).to receive(:remember_me!).and_call_original
        controller.sign_in_account(account, remember: true)
      end

      it "formats cookie as id:token" do
        controller.sign_in_account(account, remember: true)
        cookie_value = cookie_store[:_remember_account_token]
        expect(cookie_value).to match(/^#{account.id}:.+$/)
      end
    end

    context "without remember option" do
      it "does not set remember cookie" do
        controller.sign_in_account(account)
        expect(cookie_store[:_remember_account_token]).to be_nil
      end
    end
  end

  describe "#sign_out_{scope}" do
    let(:controller) { build_controller }

    before do
      session[:account_id] = account.id
      token = account.remember_me!
      cookie_store[:_remember_account_token] = "#{account.id}:#{token}"
    end

    it "clears session key" do
      controller.sign_out_account
      expect(session[:account_id]).to be_nil
    end

    it "clears remember cookie" do
      controller.sign_out_account
      expect(cookie_store[:_remember_account_token]).to be_nil
    end

    it "calls forget_me! on the account" do
      expect_any_instance_of(Account).to receive(:forget_me!)
      controller.sign_out_account
    end

    it "clears cached current_account" do
      controller.current_account # cache it
      controller.sign_out_account
      expect(controller.current_account).to be_nil
    end
  end

  describe "#authenticate_{scope}!" do
    let(:controller) { build_controller }

    context "when signed in" do
      before { session[:account_id] = account.id }

      it "does not redirect" do
        expect(controller).not_to receive(:redirect_to)
        controller.authenticate_account!
      end

      it "returns nil" do
        expect(controller.authenticate_account!).to be_nil
      end
    end

    context "when not signed in" do
      it "redirects to sign_in_path" do
        controller.authenticate_account!
        expect(controller).to have_received(:redirect_to).with("/auth/account/login")
      end

      it "uses scope's configured sign_in_path" do
        BetterAuthy.scope_for(:account).sign_in_path = "/custom/login"
        controller.authenticate_account!
        expect(controller).to have_received(:redirect_to).with("/custom/login")
      end
    end
  end

  describe "multi-scope support" do
    let(:controller) do
      # Configure multiple scopes BEFORE building controller
      BetterAuthy.reset_configuration!
      BetterAuthy.configure do |config|
        config.scope :account do |scope|
          scope.model_name = "Account"
          scope.session_key = :account_id
          scope.remember_cookie = :_remember_account_token
        end
        config.scope :admin do |scope|
          scope.model_name = "Account" # reuse Account for testing
          scope.session_key = :admin_id
          scope.remember_cookie = :_remember_admin_token
          scope.sign_in_path = "/admin/login"
        end
      end
      build_controller
    end

    it "defines helpers for all configured scopes" do
      expect(controller).to respond_to(:current_account)
      expect(controller).to respond_to(:current_admin)
      expect(controller).to respond_to(:account_signed_in?)
      expect(controller).to respond_to(:admin_signed_in?)
      expect(controller).to respond_to(:sign_in_account)
      expect(controller).to respond_to(:sign_in_admin)
      expect(controller).to respond_to(:sign_out_account)
      expect(controller).to respond_to(:sign_out_admin)
      expect(controller).to respond_to(:authenticate_account!)
      expect(controller).to respond_to(:authenticate_admin!)
    end

    it "keeps scopes independent" do
      session[:account_id] = account.id

      expect(controller.account_signed_in?).to be true
      expect(controller.admin_signed_in?).to be false
    end

    it "uses scope-specific session keys" do
      controller.sign_in_account(account)
      expect(session[:account_id]).to eq(account.id)
      expect(session[:admin_id]).to be_nil
    end

    it "uses scope-specific sign_in_paths" do
      controller.authenticate_account!
      expect(controller).to have_received(:redirect_to).with("/auth/account/login")

      controller.authenticate_admin!
      expect(controller).to have_received(:redirect_to).with("/admin/login")
    end
  end

  describe "cookie security" do
    let(:controller) { build_controller }

    it "sets cookie with proper format" do
      controller.sign_in_account(account, remember: true)
      expect(cookie_store[:_remember_account_token]).to be_present
      expect(cookie_store[:_remember_account_token]).to include(account.id.to_s)
    end

    it "cookie value contains id and token separated by colon" do
      controller.sign_in_account(account, remember: true)
      cookie_value = cookie_store[:_remember_account_token]
      id, token = cookie_value.split(":", 2)
      expect(id).to eq(account.id.to_s)
      expect(token).to be_present
    end
  end

  describe "helper methods availability" do
    it "makes helpers available as controller helpers" do
      controller_class = build_controller_class
      # helper_method stores the helper names in a set
      expect(controller_class._helper_methods).to include(:current_account, :account_signed_in?)
    end
  end
end
