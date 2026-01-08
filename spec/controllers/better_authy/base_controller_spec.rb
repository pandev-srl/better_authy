# frozen_string_literal: true

require "rails_helper"

RSpec.describe BetterAuthy::BaseController, type: :controller do
  controller(BetterAuthy::BaseController) do
    def index
      render plain: "test"
    end
  end

  before do
    routes.draw { get "index" => "anonymous#index", defaults: { scope: :account } }
  end

  describe "#resolve_layout" do
    context "with default layout" do
      before do
        BetterAuthy.reset_configuration!
        BetterAuthy.configure do |config|
          config.scope :account do |scope|
            scope.model_name = "Account"
          end
        end
      end

      it "returns the default layout" do
        controller.params[:scope] = :account
        expect(controller.send(:resolve_layout)).to eq("better_authy/application")
      end
    end

    context "with custom layout" do
      before do
        BetterAuthy.reset_configuration!
        BetterAuthy.configure do |config|
          config.scope :account do |scope|
            scope.model_name = "Account"
            scope.layout = "admin/auth"
          end
        end
      end

      it "returns the configured layout" do
        controller.params[:scope] = :account
        expect(controller.send(:resolve_layout)).to eq("admin/auth")
      end
    end

    context "when scope is nil" do
      before do
        BetterAuthy.reset_configuration!
      end

      it "falls back to default layout" do
        controller.params[:scope] = nil
        expect(controller.send(:resolve_layout)).to eq("better_authy/application")
      end
    end

    context "when scope is not configured" do
      before do
        BetterAuthy.reset_configuration!
        BetterAuthy.configure do |config|
          config.scope :account do |scope|
            scope.model_name = "Account"
          end
        end
      end

      it "falls back to default layout" do
        controller.params[:scope] = :unknown
        expect(controller.send(:resolve_layout)).to eq("better_authy/application")
      end
    end
  end
end
