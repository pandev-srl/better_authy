# frozen_string_literal: true

require "rails_helper"

RSpec.describe BetterAuthy do
  before do
    # Reset configuration before each test to avoid conflicts
    described_class.reset_configuration!
  end

  describe ".configure" do
    it "yields a Configuration instance" do
      expect { |b| described_class.configure(&b) }
        .to yield_with_args(BetterAuthy::Configuration)
    end

    it "allows configuring scopes" do
      described_class.configure do |config|
        config.scope(:account) { |s| s.model_name = "Account" }
      end

      expect(described_class.configuration.scopes[:account]).to be_present
    end
  end

  describe ".configuration" do
    it "returns the configuration instance" do
      expect(described_class.configuration).to be_a(BetterAuthy::Configuration)
    end

    it "returns the same instance on multiple calls" do
      expect(described_class.configuration).to be(described_class.configuration)
    end
  end

  describe ".reset_configuration!" do
    it "creates a new configuration instance" do
      old_config = described_class.configuration
      described_class.reset_configuration!
      expect(described_class.configuration).not_to be(old_config)
    end
  end

  describe ".scope_for" do
    before do
      described_class.configure do |config|
        config.scope(:account) { |s| s.model_name = "Account" }
      end
    end

    it "delegates to configuration" do
      expect(described_class.scope_for(:account))
        .to be_a(BetterAuthy::ScopeConfiguration)
    end
  end

  describe ".scope_for!" do
    before do
      described_class.configure do |config|
        config.scope(:account) { |s| s.model_name = "Account" }
      end
    end

    it "delegates to configuration" do
      expect(described_class.scope_for!(:account))
        .to be_a(BetterAuthy::ScopeConfiguration)
    end

    it "raises error for unknown scope" do
      expect { described_class.scope_for!(:unknown) }
        .to raise_error(BetterAuthy::ConfigurationError)
    end
  end
end
