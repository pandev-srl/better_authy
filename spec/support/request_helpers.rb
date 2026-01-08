# frozen_string_literal: true

module BetterAuthy
  module RequestHelpers
    def sign_in(resource, scope: :account)
      scope_config = BetterAuthy.scope_for!(scope)
      post "/auth/#{scope}/login", params: {
        session: { email: resource.email, password: resource.password }
      }
    end

    def sign_in_via_session(resource, scope: :account)
      scope_config = BetterAuthy.scope_for!(scope)
      # Directly set session for tests that need to bypass the login form
      post "/auth/#{scope}/login", params: {
        session: { email: resource.email, password: "password123" }
      }
    end
  end
end

RSpec.configure do |config|
  config.include BetterAuthy::RequestHelpers, type: :request
end
