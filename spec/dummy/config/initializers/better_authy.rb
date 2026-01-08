# frozen_string_literal: true

BetterAuthy.configure do |config|
  config.scope :account do |scope|
    scope.model_name = "Account"
  end
end
