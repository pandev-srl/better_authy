# frozen_string_literal: true

module BetterAuthy
  module ControllerHelpers
    extend ActiveSupport::Concern

    included do
      # Define helper methods for each configured scope
      BetterAuthy.configuration.scopes.each_key do |scope_name|
        define_scope_helpers(scope_name)
      end
    end

    class_methods do
      def define_scope_helpers(scope_name)
        # current_{scope}
        define_method(:"current_#{scope_name}") do
          ivar = "@current_#{scope_name}"
          return instance_variable_get(ivar) if instance_variable_defined?(ivar)

          instance_variable_set(ivar, find_authenticated_resource(scope_name))
        end

        # {scope}_signed_in?
        define_method(:"#{scope_name}_signed_in?") do
          send(:"current_#{scope_name}").present?
        end

        # sign_in_{scope}
        define_method(:"sign_in_#{scope_name}") do |resource, remember: false|
          scope_config = BetterAuthy.scope_for!(scope_name)

          reset_session
          session[scope_config.session_key] = resource.id
          resource.track_sign_in!(request)

          if remember
            token = resource.remember_me!
            cookie_value = "#{resource.id}:#{token}"
            cookies.encrypted[scope_config.remember_cookie] = {
              value: cookie_value,
              expires: scope_config.remember_for.from_now,
              **BetterAuthy.configuration.cookie_config
            }
          end

          instance_variable_set("@current_#{scope_name}", resource)
        end

        # sign_out_{scope}
        define_method(:"sign_out_#{scope_name}") do
          scope_config = BetterAuthy.scope_for!(scope_name)
          current_resource = send(:"current_#{scope_name}")

          current_resource&.forget_me!

          session.delete(scope_config.session_key)
          cookies.delete(scope_config.remember_cookie)

          instance_variable_set("@current_#{scope_name}", nil)
        end

        # authenticate_{scope}!
        define_method(:"authenticate_#{scope_name}!") do
          return if send(:"#{scope_name}_signed_in?")

          scope_config = BetterAuthy.scope_for!(scope_name)
          redirect_to(scope_config.sign_in_path)
        end

        # Register as helper methods
        helper_method :"current_#{scope_name}", :"#{scope_name}_signed_in?"
      end
    end

    private

    def find_authenticated_resource(scope_name)
      scope_config = BetterAuthy.scope_for!(scope_name)
      model_class = scope_config.model_class

      # Try session first
      if (resource_id = session[scope_config.session_key])
        return model_class.find_by(id: resource_id)
      end

      # Try remember cookie
      if (cookie_value = cookies.encrypted[scope_config.remember_cookie])
        resource_id, token = cookie_value.split(":", 2)
        resource = model_class.find_by(id: resource_id)
        return resource if resource&.remember_token_valid?(token)
      end

      nil
    end
  end
end
