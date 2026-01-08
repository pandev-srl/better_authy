# frozen_string_literal: true

require "rails_helper"

RSpec.describe BetterAuthy::ScopeConfiguration do
  subject(:scope) { described_class.new(:account) }

  describe "#initialize" do
    it "stores the scope name" do
      expect(scope.name).to eq(:account)
    end

    it "sets default session_key based on scope name" do
      expect(scope.session_key).to eq(:account_id)
    end

    it "sets default remember_cookie based on scope name" do
      expect(scope.remember_cookie).to eq(:_remember_account_token)
    end

    it "sets default remember_for to 2 weeks" do
      expect(scope.remember_for).to eq(2.weeks)
    end

    it "sets default sign_in_path based on scope name" do
      expect(scope.sign_in_path).to eq("/auth/account/login")
    end

    it "sets default after_sign_in_path to root" do
      expect(scope.after_sign_in_path).to eq("/")
    end

    it "sets default layout to 'better_authy/application'" do
      expect(scope.layout).to eq("better_authy/application")
    end

    it "sets default password_reset_within to 1 hour" do
      expect(scope.password_reset_within).to eq(1.hour)
    end

    context "with different scope name" do
      subject(:scope) { described_class.new(:user) }

      it "sets session_key based on scope name" do
        expect(scope.session_key).to eq(:user_id)
      end

      it "sets remember_cookie based on scope name" do
        expect(scope.remember_cookie).to eq(:_remember_user_token)
      end

      it "sets sign_in_path based on scope name" do
        expect(scope.sign_in_path).to eq("/auth/user/login")
      end
    end
  end

  describe "#model_name=" do
    it "allows setting the model name" do
      scope.model_name = "BetterAuthy::Account"
      expect(scope.model_name).to eq("BetterAuthy::Account")
    end
  end

  describe "#model_class" do
    before do
      stub_const("BetterAuthy::Account", Class.new)
      scope.model_name = "BetterAuthy::Account"
    end

    it "constantizes model_name to return the class" do
      expect(scope.model_class).to eq(BetterAuthy::Account)
    end

    it "raises error if model_name is not set" do
      scope = described_class.new(:admin)
      expect { scope.model_class }.to raise_error(BetterAuthy::ConfigurationError, /model_name/)
    end
  end

  describe "#session_key=" do
    it "allows overriding the session_key" do
      scope.session_key = :custom_session_key
      expect(scope.session_key).to eq(:custom_session_key)
    end
  end

  describe "#remember_cookie=" do
    it "allows overriding the remember_cookie" do
      scope.remember_cookie = :_custom_remember
      expect(scope.remember_cookie).to eq(:_custom_remember)
    end
  end

  describe "#remember_for=" do
    it "allows overriding the remember_for duration" do
      scope.remember_for = 1.month
      expect(scope.remember_for).to eq(1.month)
    end
  end

  describe "#sign_in_path=" do
    it "allows overriding the sign_in_path" do
      scope.sign_in_path = "/custom/login"
      expect(scope.sign_in_path).to eq("/custom/login")
    end
  end

  describe "#after_sign_in_path=" do
    it "allows overriding the after_sign_in_path" do
      scope.after_sign_in_path = "/dashboard"
      expect(scope.after_sign_in_path).to eq("/dashboard")
    end
  end

  describe "#layout=" do
    it "allows overriding the layout" do
      scope.layout = "admin/auth"
      expect(scope.layout).to eq("admin/auth")
    end
  end

  describe "#password_reset_within=" do
    it "allows overriding the password_reset_within duration" do
      scope.password_reset_within = 2.hours
      expect(scope.password_reset_within).to eq(2.hours)
    end
  end

  describe "#validate!" do
    it "raises error if model_name is not set" do
      expect { scope.validate! }.to raise_error(BetterAuthy::ConfigurationError, /model_name/)
    end

    it "does not raise error if model_name is set" do
      scope.model_name = "Account"
      expect { scope.validate! }.not_to raise_error
    end
  end
end
