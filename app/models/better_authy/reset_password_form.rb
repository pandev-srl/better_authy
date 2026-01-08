# frozen_string_literal: true

module BetterAuthy
  class ResetPasswordForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :token, :string
    attribute :password, :string
    attribute :password_confirmation, :string

    validates :password, presence: true, length: { minimum: 8 }
    validates :password_confirmation, presence: true
  end
end
