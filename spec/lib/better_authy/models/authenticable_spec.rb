# frozen_string_literal: true

require "rails_helper"

RSpec.describe BetterAuthy::Models::Authenticable do
  # Define a test model class that includes the concern
  let(:test_model_class) do
    Class.new(ApplicationRecord) do
      self.table_name = "accounts"
      better_authy_authenticable :account
    end
  end

  before do
    BetterAuthy.reset_configuration!
    BetterAuthy.configure do |config|
      config.scope :account do |scope|
        scope.model_name = "Account"
        scope.remember_for = 2.weeks
        scope.password_reset_within = 1.hour
      end
    end
    stub_const("TestAuthAccount", test_model_class)
  end

  let(:account) do
    TestAuthAccount.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  describe "#authenticable_scope" do
    it "returns the scope name" do
      expect(account.authenticable_scope).to eq(:account)
    end
  end

  describe "#authenticable_scope_config" do
    it "returns the scope configuration" do
      expect(account.authenticable_scope_config).to be_a(BetterAuthy::ScopeConfiguration)
      expect(account.authenticable_scope_config.name).to eq(:account)
    end
  end

  describe "#remember_me!" do
    it "generates and returns a token" do
      token = account.remember_me!
      expect(token).to be_present
      expect(token.length).to be >= 32
    end

    it "stores hashed token in remember_token_digest" do
      token = account.remember_me!
      account.reload
      expect(account.remember_token_digest).to be_present
      expect(account.remember_token_digest).not_to eq(token)
    end

    it "stores remember_created_at timestamp" do
      freeze_time do
        account.remember_me!
        account.reload
        expect(account.remember_created_at).to eq(Time.current)
      end
    end

    it "returns plain token that validates against stored digest" do
      token = account.remember_me!
      account.reload
      expect(BCrypt::Password.new(account.remember_token_digest).is_password?(token)).to be true
    end
  end

  describe "#forget_me!" do
    before { account.remember_me! }

    it "clears remember_token_digest" do
      account.forget_me!
      account.reload
      expect(account.remember_token_digest).to be_nil
    end

    it "clears remember_created_at" do
      account.forget_me!
      account.reload
      expect(account.remember_created_at).to be_nil
    end
  end

  describe "#remember_token_valid?" do
    context "with valid unexpired token" do
      it "returns true" do
        token = account.remember_me!
        expect(account.remember_token_valid?(token)).to be true
      end
    end

    context "with wrong token" do
      it "returns false" do
        account.remember_me!
        expect(account.remember_token_valid?("wrong_token")).to be false
      end
    end

    context "with expired token" do
      it "returns false" do
        token = account.remember_me!
        travel BetterAuthy.scope_for(:account).remember_for + 1.day
        expect(account.remember_token_valid?(token)).to be false
      end
    end

    context "when no token stored" do
      it "returns false" do
        expect(account.remember_token_valid?("any_token")).to be false
      end
    end

    context "when remember_token_digest is nil" do
      it "returns false" do
        account.update!(remember_token_digest: nil, remember_created_at: Time.current)
        expect(account.remember_token_valid?("any_token")).to be false
      end
    end

    context "when remember_created_at is nil" do
      it "returns false" do
        account.update!(remember_token_digest: "some_digest", remember_created_at: nil)
        expect(account.remember_token_valid?("any_token")).to be false
      end
    end
  end

  describe "#track_sign_in!" do
    let(:request) { double("request", remote_ip: "192.168.1.1") }

    it "increments sign_in_count" do
      expect { account.track_sign_in!(request) }
        .to change { account.reload.sign_in_count }.by(1)
    end

    it "updates current_sign_in_at to current time" do
      freeze_time do
        account.track_sign_in!(request)
        expect(account.current_sign_in_at).to eq(Time.current)
      end
    end

    it "stores current remote IP" do
      account.track_sign_in!(request)
      expect(account.current_sign_in_ip).to eq("192.168.1.1")
    end

    context "when previously signed in" do
      before do
        account.update!(
          current_sign_in_at: 1.day.ago,
          current_sign_in_ip: "10.0.0.1"
        )
      end

      it "moves current_sign_in_at to last_sign_in_at" do
        previous_time = account.current_sign_in_at
        account.track_sign_in!(request)
        expect(account.last_sign_in_at).to be_within(1.second).of(previous_time)
      end

      it "moves current_sign_in_ip to last_sign_in_ip" do
        account.track_sign_in!(request)
        expect(account.last_sign_in_ip).to eq("10.0.0.1")
      end
    end

    context "with different IP addresses" do
      it "tracks IPv4 addresses" do
        request = double("request", remote_ip: "203.0.113.42")
        account.track_sign_in!(request)
        expect(account.current_sign_in_ip).to eq("203.0.113.42")
      end

      it "tracks IPv6 addresses" do
        request = double("request", remote_ip: "2001:db8::1")
        account.track_sign_in!(request)
        expect(account.current_sign_in_ip).to eq("2001:db8::1")
      end
    end
  end

  describe "#generate_password_reset_token!" do
    it "generates and returns a token" do
      token = account.generate_password_reset_token!
      expect(token).to be_present
      expect(token.length).to be >= 32
    end

    it "stores hashed token in password_reset_token_digest" do
      token = account.generate_password_reset_token!
      account.reload
      expect(account.password_reset_token_digest).to be_present
      expect(account.password_reset_token_digest).not_to eq(token)
    end

    it "stores password_reset_sent_at timestamp" do
      freeze_time do
        account.generate_password_reset_token!
        account.reload
        expect(account.password_reset_sent_at).to eq(Time.current)
      end
    end

    it "returns plain token that validates against stored digest" do
      token = account.generate_password_reset_token!
      account.reload
      expect(BCrypt::Password.new(account.password_reset_token_digest).is_password?(token)).to be true
    end
  end

  describe "#password_reset_token_valid?" do
    context "with valid unexpired token" do
      it "returns true" do
        token = account.generate_password_reset_token!
        expect(account.password_reset_token_valid?(token)).to be true
      end
    end

    context "with wrong token" do
      it "returns false" do
        account.generate_password_reset_token!
        expect(account.password_reset_token_valid?("wrong_token")).to be false
      end
    end

    context "with expired token" do
      it "returns false" do
        token = account.generate_password_reset_token!
        travel BetterAuthy.scope_for(:account).password_reset_within + 1.minute
        expect(account.password_reset_token_valid?(token)).to be false
      end
    end

    context "when no token stored" do
      it "returns false" do
        expect(account.password_reset_token_valid?("any_token")).to be false
      end
    end

    context "when password_reset_token_digest is nil" do
      it "returns false" do
        account.update!(password_reset_token_digest: nil, password_reset_sent_at: Time.current)
        expect(account.password_reset_token_valid?("any_token")).to be false
      end
    end

    context "when password_reset_sent_at is nil" do
      it "returns false" do
        account.update!(password_reset_token_digest: "some_digest", password_reset_sent_at: nil)
        expect(account.password_reset_token_valid?("any_token")).to be false
      end
    end
  end

  describe "#clear_password_reset_token!" do
    before { account.generate_password_reset_token! }

    it "clears password_reset_token_digest" do
      account.clear_password_reset_token!
      account.reload
      expect(account.password_reset_token_digest).to be_nil
    end

    it "clears password_reset_sent_at" do
      account.clear_password_reset_token!
      account.reload
      expect(account.password_reset_sent_at).to be_nil
    end
  end

  describe "#reset_password!" do
    before { account.generate_password_reset_token! }

    context "with valid matching passwords" do
      it "updates the password" do
        account.reset_password!("newpassword123", "newpassword123")
        expect(account.authenticate("newpassword123")).to be_truthy
      end

      it "clears the password reset token" do
        account.reset_password!("newpassword123", "newpassword123")
        account.reload
        expect(account.password_reset_token_digest).to be_nil
      end

      it "returns true" do
        expect(account.reset_password!("newpassword123", "newpassword123")).to be true
      end
    end

    context "with non-matching passwords" do
      it "returns false" do
        expect(account.reset_password!("newpassword123", "different")).to be false
      end

      it "adds validation errors" do
        account.reset_password!("newpassword123", "different")
        expect(account.errors[:password_confirmation]).to be_present
      end

      it "does not change the password" do
        original_digest = account.password_digest
        account.reset_password!("newpassword123", "different")
        account.reload
        expect(account.password_digest).to eq(original_digest)
      end
    end

    context "with password too short" do
      it "returns false" do
        expect(account.reset_password!("short", "short")).to be false
      end

      it "adds validation errors" do
        account.reset_password!("short", "short")
        expect(account.errors[:password]).to be_present
      end
    end
  end
end
