# frozen_string_literal: true

module BetterAuthy
  module ModelExtensions
    extend ActiveSupport::Concern

    class_methods do
      def better_authy_authenticable(scope_name, **options)
        # Store scope name and options on the class
        class_attribute :authenticable_scope_name, default: scope_name
        class_attribute :authenticable_options, default: options

        # Include the authenticable concern (runs included do block)
        include BetterAuthy::Models::Authenticable
      end
    end
  end
end

# Extend ActiveRecord::Base when ActiveRecord is loaded
ActiveSupport.on_load(:active_record) do
  include BetterAuthy::ModelExtensions
end
