# frozen_string_literal: true

require "rails_helper"

RSpec.describe "BetterAuthy Routes", type: :routing do
  routes { BetterAuthy::Engine.routes }

  before do
    BetterAuthy.reset_configuration!
    BetterAuthy.configure do |config|
      config.scope :account do |scope|
        scope.model_name = "Account"
      end
    end
    # Force route reload after configuration
    Rails.application.reload_routes!
  end

  describe "sessions routes" do
    describe "login page" do
      it "routes GET /account/login to sessions#new with scope parameter" do
        expect(get: "/account/login").to route_to(
          controller: "better_authy/sessions",
          action: "new",
          scope: :account
        )
      end
    end

    describe "login action" do
      it "routes POST /account/login to sessions#create with scope parameter" do
        expect(post: "/account/login").to route_to(
          controller: "better_authy/sessions",
          action: "create",
          scope: :account
        )
      end
    end

    describe "logout action" do
      it "routes DELETE /account/logout to sessions#destroy with scope parameter" do
        expect(delete: "/account/logout").to route_to(
          controller: "better_authy/sessions",
          action: "destroy",
          scope: :account
        )
      end
    end
  end

  describe "registrations routes" do
    describe "signup page" do
      it "routes GET /account/signup to registrations#new with scope parameter" do
        expect(get: "/account/signup").to route_to(
          controller: "better_authy/registrations",
          action: "new",
          scope: :account
        )
      end
    end

    describe "signup action" do
      it "routes POST /account/signup to registrations#create with scope parameter" do
        expect(post: "/account/signup").to route_to(
          controller: "better_authy/registrations",
          action: "create",
          scope: :account
        )
      end
    end
  end

  describe "route helpers" do
    # Route helpers include the mount point (/auth) from dummy app
    it "generates account_login_path" do
      expect(account_login_path).to eq("/auth/account/login")
    end

    it "generates account_logout_path" do
      expect(account_logout_path).to eq("/auth/account/logout")
    end

    it "generates account_signup_path" do
      expect(account_signup_path).to eq("/auth/account/signup")
    end
  end

  describe "unrecognized routes" do
    it "does not route GET /nonexistent/login" do
      expect(get: "/nonexistent/login").not_to be_routable
    end

    it "does not route PUT /account/login" do
      expect(put: "/account/login").not_to be_routable
    end

    it "does not route PATCH /account/login" do
      expect(patch: "/account/login").not_to be_routable
    end
  end

  describe "multiple scopes" do
    before do
      BetterAuthy.reset_configuration!
      BetterAuthy.configure do |config|
        config.scope :account do |scope|
          scope.model_name = "Account"
        end
        config.scope :admin do |scope|
          scope.model_name = "Admin"
        end
      end
      Rails.application.reload_routes!
    end

    describe "admin scope routes" do
      it "routes GET /admin/login to sessions#new with scope parameter" do
        expect(get: "/admin/login").to route_to(
          controller: "better_authy/sessions",
          action: "new",
          scope: :admin
        )
      end

      it "routes POST /admin/login to sessions#create with scope parameter" do
        expect(post: "/admin/login").to route_to(
          controller: "better_authy/sessions",
          action: "create",
          scope: :admin
        )
      end

      it "routes DELETE /admin/logout to sessions#destroy with scope parameter" do
        expect(delete: "/admin/logout").to route_to(
          controller: "better_authy/sessions",
          action: "destroy",
          scope: :admin
        )
      end

      it "routes GET /admin/signup to registrations#new with scope parameter" do
        expect(get: "/admin/signup").to route_to(
          controller: "better_authy/registrations",
          action: "new",
          scope: :admin
        )
      end

      it "routes POST /admin/signup to registrations#create with scope parameter" do
        expect(post: "/admin/signup").to route_to(
          controller: "better_authy/registrations",
          action: "create",
          scope: :admin
        )
      end
    end

    describe "admin route helpers" do
      it "generates admin_login_path" do
        expect(admin_login_path).to eq("/auth/admin/login")
      end

      it "generates admin_logout_path" do
        expect(admin_logout_path).to eq("/auth/admin/logout")
      end

      it "generates admin_signup_path" do
        expect(admin_signup_path).to eq("/auth/admin/signup")
      end
    end

    describe "both scopes work simultaneously" do
      it "routes to account and admin scopes independently with correct scope parameters" do
        expect(get: "/account/login").to route_to(
          controller: "better_authy/sessions",
          action: "new",
          scope: :account
        )
        expect(get: "/admin/login").to route_to(
          controller: "better_authy/sessions",
          action: "new",
          scope: :admin
        )
      end
    end
  end
end
