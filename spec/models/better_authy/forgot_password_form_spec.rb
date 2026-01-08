# frozen_string_literal: true

require "rails_helper"

RSpec.describe BetterAuthy::ForgotPasswordForm do
  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
  end

  describe "attributes" do
    it "has email attribute" do
      form = described_class.new(email: "test@example.com")
      expect(form.email).to eq("test@example.com")
    end
  end

  describe "#valid?" do
    context "with valid email" do
      it "returns true" do
        form = described_class.new(email: "test@example.com")
        expect(form).to be_valid
      end
    end

    context "with blank email" do
      it "returns false" do
        form = described_class.new(email: "")
        expect(form).not_to be_valid
        expect(form.errors[:email]).to include("can't be blank")
      end
    end

    context "with nil email" do
      it "returns false" do
        form = described_class.new(email: nil)
        expect(form).not_to be_valid
      end
    end
  end
end
