# frozen_string_literal: true

require "rails_helper"

RSpec.describe BetterAuthy::ModelExtensions do
  before do
    BetterAuthy.reset_configuration!
    BetterAuthy.configure do |config|
      config.scope :account do |scope|
        scope.model_name = "Account"
      end
    end
  end

  describe ".better_authy_authenticable" do
    context "when called on a model" do
      before do
        # Redefine Account to use better_authy_authenticable
        stub_const("TestAccount", Class.new(ApplicationRecord) do
          self.table_name = "accounts"
          better_authy_authenticable :account
        end)
      end

      it "includes Authenticable concern" do
        expect(TestAccount.ancestors).to include(BetterAuthy::Models::Authenticable)
      end

      it "sets up has_secure_password" do
        instance = TestAccount.new
        expect(instance).to respond_to(:authenticate)
        expect(instance).to respond_to(:password=)
        expect(instance).to respond_to(:password_confirmation=)
      end

      it "sets authenticable_scope_name class attribute" do
        expect(TestAccount.authenticable_scope_name).to eq(:account)
      end

      it "sets authenticable_options class attribute" do
        expect(TestAccount.authenticable_options).to be_a(Hash)
      end

      it "allows custom options to be passed" do
        stub_const("CustomAccount", Class.new(ApplicationRecord) do
          self.table_name = "accounts"
          better_authy_authenticable :account, password_minimum: 12
        end)

        expect(CustomAccount.authenticable_options[:password_minimum]).to eq(12)
      end
    end

    context "email validations" do
      before do
        stub_const("TestAccount", Class.new(ApplicationRecord) do
          self.table_name = "accounts"
          better_authy_authenticable :account
        end)
      end

      it "requires email to be present" do
        instance = TestAccount.new(password: "password123", password_confirmation: "password123")
        expect(instance).not_to be_valid
        expect(instance.errors[:email]).to include("can't be blank")
      end

      it "requires email to be unique (case-insensitive)" do
        TestAccount.create!(email: "test@example.com", password: "password123", password_confirmation: "password123")
        duplicate = TestAccount.new(email: "TEST@EXAMPLE.COM", password: "password123", password_confirmation: "password123")
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:email]).to include("has already been taken")
      end

      it "requires email to have valid format" do
        instance = TestAccount.new(email: "invalid-email", password: "password123", password_confirmation: "password123")
        expect(instance).not_to be_valid
        expect(instance.errors[:email]).to include("is invalid")
      end

      it "accepts valid email format" do
        instance = TestAccount.new(email: "valid@example.com", password: "password123", password_confirmation: "password123")
        expect(instance).to be_valid
      end
    end

    context "email normalization" do
      before do
        stub_const("TestAccount", Class.new(ApplicationRecord) do
          self.table_name = "accounts"
          better_authy_authenticable :account
        end)
      end

      it "strips whitespace from email" do
        instance = TestAccount.new(email: "  test@example.com  ", password: "password123", password_confirmation: "password123")
        instance.valid?
        expect(instance.email).to eq("test@example.com")
      end

      it "downcases email" do
        instance = TestAccount.new(email: "TEST@EXAMPLE.COM", password: "password123", password_confirmation: "password123")
        instance.valid?
        expect(instance.email).to eq("test@example.com")
      end

      it "normalizes email with both whitespace and uppercase" do
        instance = TestAccount.new(email: "  TEST@Example.COM  ", password: "password123", password_confirmation: "password123")
        instance.valid?
        expect(instance.email).to eq("test@example.com")
      end
    end

    context "password validations" do
      before do
        stub_const("TestAccount", Class.new(ApplicationRecord) do
          self.table_name = "accounts"
          better_authy_authenticable :account
        end)
      end

      it "requires password to have minimum length of 8 by default" do
        instance = TestAccount.new(email: "test@example.com", password: "short", password_confirmation: "short")
        expect(instance).not_to be_valid
        expect(instance.errors[:password]).to include("is too short (minimum is 8 characters)")
      end

      it "accepts password with minimum length" do
        instance = TestAccount.new(email: "test@example.com", password: "password", password_confirmation: "password")
        expect(instance).to be_valid
      end

      it "allows nil password for existing records" do
        account = TestAccount.create!(email: "test@example.com", password: "password123", password_confirmation: "password123")
        account.reload
        account.email = "updated@example.com"
        expect(account).to be_valid
      end
    end

    context "with custom password minimum" do
      before do
        stub_const("CustomPasswordAccount", Class.new(ApplicationRecord) do
          self.table_name = "accounts"
          better_authy_authenticable :account, password_minimum: 12
        end)
      end

      it "uses custom password minimum length" do
        instance = CustomPasswordAccount.new(email: "test@example.com", password: "shortpass1", password_confirmation: "shortpass1")
        expect(instance).not_to be_valid
        expect(instance.errors[:password]).to include("is too short (minimum is 12 characters)")
      end

      it "accepts password meeting custom minimum" do
        instance = CustomPasswordAccount.new(email: "test@example.com", password: "longerpassword", password_confirmation: "longerpassword")
        expect(instance).to be_valid
      end
    end
  end
end
