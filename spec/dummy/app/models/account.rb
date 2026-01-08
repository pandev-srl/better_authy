# frozen_string_literal: true

class Account < ApplicationRecord
  better_authy_authenticable :account
end
