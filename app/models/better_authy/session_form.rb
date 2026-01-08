# frozen_string_literal: true

module BetterAuthy
  class SessionForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :email, :string
    attribute :password, :string
    attribute :remember_me, :boolean, default: false

    validates :email, presence: true
    validates :password, presence: true
  end
end
