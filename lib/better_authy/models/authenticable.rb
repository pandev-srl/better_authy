# frozen_string_literal: true

module BetterAuthy
  module Models
    module Authenticable
      extend ActiveSupport::Concern

      included do
        # Configure has_secure_password
        has_secure_password

        # Email validations
        validates :email,
          presence: true,
          uniqueness: { case_sensitive: false },
          format: { with: URI::MailTo::EMAIL_REGEXP }

        # Password validation (uses options from better_authy_authenticable call)
        validates :password,
          length: { minimum: authenticable_options.fetch(:password_minimum, 8) },
          allow_nil: true

        # Email normalization
        normalizes :email, with: ->(email) { email.strip.downcase }
      end

      # Returns the scope name for this model
      def authenticable_scope
        self.class.authenticable_scope_name
      end

      # Returns the scope configuration
      def authenticable_scope_config
        BetterAuthy.scope_for(authenticable_scope)
      end

      # Generate remember token
      def remember_me!
        token = SecureRandom.urlsafe_base64(32)
        update!(
          remember_token_digest: BCrypt::Password.create(token),
          remember_created_at: Time.current
        )
        token
      end

      # Clear remember token
      def forget_me!
        update!(
          remember_token_digest: nil,
          remember_created_at: nil
        )
      end

      # Validate remember token
      def remember_token_valid?(token)
        return false if remember_token_digest.blank?
        return false if remember_created_at.blank?
        return false if remember_created_at < authenticable_scope_config.remember_for.ago

        BCrypt::Password.new(remember_token_digest).is_password?(token)
      end

      # Track sign in
      def track_sign_in!(request)
        now = Time.current
        update!(
          sign_in_count: sign_in_count + 1,
          last_sign_in_at: current_sign_in_at,
          last_sign_in_ip: current_sign_in_ip,
          current_sign_in_at: now,
          current_sign_in_ip: request.remote_ip
        )
      end

      # Generate password reset token
      def generate_password_reset_token!
        token = SecureRandom.urlsafe_base64(32)
        update!(
          password_reset_token_digest: BCrypt::Password.create(token),
          password_reset_sent_at: Time.current
        )
        token
      end

      # Validate password reset token
      def password_reset_token_valid?(token)
        return false if password_reset_token_digest.blank?
        return false if password_reset_sent_at.blank?
        return false if password_reset_sent_at < authenticable_scope_config.password_reset_within.ago

        BCrypt::Password.new(password_reset_token_digest).is_password?(token)
      end

      # Clear password reset token
      def clear_password_reset_token!
        update!(
          password_reset_token_digest: nil,
          password_reset_sent_at: nil
        )
      end

      # Reset password with confirmation
      def reset_password!(new_password, new_password_confirmation)
        self.password = new_password
        self.password_confirmation = new_password_confirmation

        if valid?
          save!
          clear_password_reset_token!
          true
        else
          false
        end
      end
    end
  end
end
