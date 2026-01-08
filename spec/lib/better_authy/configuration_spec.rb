# frozen_string_literal: true

require "rails_helper"

RSpec.describe BetterAuthy::Configuration do
  subject(:config) { described_class.new }

  describe "#initialize" do
    it "initializes with empty scopes hash" do
      expect(config.scopes).to eq({})
    end

    it "initializes cookie_config with default values" do
      expect(config.cookie_config).to eq({
        secure: false,
        httponly: true,
        same_site: :lax
      })
    end
  end

  describe "#cookie_config" do
    context "with ENV variable set" do
      around do |example|
        original = ENV["BETTER_AUTHY_SECURE_COOKIES"]
        ENV["BETTER_AUTHY_SECURE_COOKIES"] = "true"
        example.run
        ENV["BETTER_AUTHY_SECURE_COOKIES"] = original
      end

      it "reads secure from ENV" do
        new_config = described_class.new
        expect(new_config.cookie_config[:secure]).to be true
      end
    end

    context "with ENV variable unset" do
      around do |example|
        original = ENV["BETTER_AUTHY_SECURE_COOKIES"]
        ENV.delete("BETTER_AUTHY_SECURE_COOKIES")
        example.run
        ENV["BETTER_AUTHY_SECURE_COOKIES"] = original
      end

      it "defaults secure to false" do
        new_config = described_class.new
        expect(new_config.cookie_config[:secure]).to be false
      end
    end
  end

  describe "#cookie_config=" do
    it "merges options with existing config" do
      config.cookie_config = { secure: true }
      expect(config.cookie_config).to eq({
        secure: true,
        httponly: true,
        same_site: :lax
      })
    end

    it "allows overriding multiple options" do
      config.cookie_config = { secure: true, same_site: :strict }
      expect(config.cookie_config[:secure]).to be true
      expect(config.cookie_config[:same_site]).to eq(:strict)
      expect(config.cookie_config[:httponly]).to be true
    end
  end

  describe "#scope" do
    it "registers a new scope with a block" do
      config.scope(:account) { |s| s.model_name = "Account" }
      expect(config.scopes[:account]).to be_a(BetterAuthy::ScopeConfiguration)
    end

    it "yields scope configuration to the block" do
      config.scope(:account) do |s|
        s.model_name = "Account"
        s.remember_for = 1.month
      end

      expect(config.scopes[:account].model_name).to eq("Account")
      expect(config.scopes[:account].remember_for).to eq(1.month)
    end

    it "converts scope name to symbol" do
      config.scope("account") { |s| s.model_name = "Account" }
      expect(config.scopes[:account]).to be_a(BetterAuthy::ScopeConfiguration)
    end

    it "raises error if scope is registered without block" do
      expect { config.scope(:account) }.to raise_error(ArgumentError, /block/)
    end

    it "raises error if scope name is already registered" do
      config.scope(:account) { |s| s.model_name = "Account" }
      expect { config.scope(:account) { |s| s.model_name = "Other" } }
        .to raise_error(BetterAuthy::ConfigurationError, /already registered/)
    end
  end

  describe "#scope_for" do
    before do
      config.scope(:account) { |s| s.model_name = "Account" }
    end

    it "returns the scope configuration by name" do
      expect(config.scope_for(:account)).to be_a(BetterAuthy::ScopeConfiguration)
    end

    it "returns nil for unregistered scope" do
      expect(config.scope_for(:unknown)).to be_nil
    end

    it "converts string to symbol" do
      expect(config.scope_for("account")).to be_a(BetterAuthy::ScopeConfiguration)
    end
  end

  describe "#scope_for!" do
    before do
      config.scope(:account) { |s| s.model_name = "Account" }
    end

    it "returns the scope configuration by name" do
      expect(config.scope_for!(:account)).to be_a(BetterAuthy::ScopeConfiguration)
    end

    it "raises error for unregistered scope" do
      expect { config.scope_for!(:unknown) }
        .to raise_error(BetterAuthy::ConfigurationError, /not registered/)
    end
  end

  describe "#validate!" do
    it "validates all registered scopes" do
      config.scope(:account) { |s| } # No model_name set
      expect { config.validate! }.to raise_error(BetterAuthy::ConfigurationError)
    end

    it "does not raise error if all scopes are valid" do
      config.scope(:account) { |s| s.model_name = "Account" }
      expect { config.validate! }.not_to raise_error
    end
  end
end
