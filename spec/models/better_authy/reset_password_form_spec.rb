# frozen_string_literal: true

require "rails_helper"

RSpec.describe BetterAuthy::ResetPasswordForm do
  describe "validations" do
    it { is_expected.to validate_presence_of(:password) }
    it { is_expected.to validate_presence_of(:password_confirmation) }
    it { is_expected.to validate_length_of(:password).is_at_least(8) }
  end

  describe "attributes" do
    it "has password attribute" do
      form = described_class.new(password: "password123")
      expect(form.password).to eq("password123")
    end

    it "has password_confirmation attribute" do
      form = described_class.new(password_confirmation: "password123")
      expect(form.password_confirmation).to eq("password123")
    end

    it "has token attribute" do
      form = described_class.new(token: "abc123")
      expect(form.token).to eq("abc123")
    end
  end

  describe "#valid?" do
    context "with valid data" do
      it "returns true" do
        form = described_class.new(
          token: "abc123",
          password: "password123",
          password_confirmation: "password123"
        )
        expect(form).to be_valid
      end
    end

    context "with blank password" do
      it "returns false" do
        form = described_class.new(
          token: "abc123",
          password: "",
          password_confirmation: ""
        )
        expect(form).not_to be_valid
        expect(form.errors[:password]).to include("can't be blank")
      end
    end

    context "with short password" do
      it "returns false" do
        form = described_class.new(
          token: "abc123",
          password: "short",
          password_confirmation: "short"
        )
        expect(form).not_to be_valid
        expect(form.errors[:password]).to include("is too short (minimum is 8 characters)")
      end
    end

    context "with blank password_confirmation" do
      it "returns false" do
        form = described_class.new(
          token: "abc123",
          password: "password123",
          password_confirmation: ""
        )
        expect(form).not_to be_valid
        expect(form.errors[:password_confirmation]).to include("can't be blank")
      end
    end
  end
end
