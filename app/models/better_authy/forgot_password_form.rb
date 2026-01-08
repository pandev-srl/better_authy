# frozen_string_literal: true

module BetterAuthy
  class ForgotPasswordForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :email, :string

    validates :email, presence: true
  end
end
