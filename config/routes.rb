# frozen_string_literal: true

BetterAuthy::Engine.routes.draw do
  # Generate routes for each configured scope
  # The defaults: { scope: scope_name } injects the scope into params
  # so controllers don't need to parse the URL path
  BetterAuthy.configuration.scopes.each_key do |scope_name|
    scope scope_name.to_s, defaults: { scope: scope_name } do
      get "login", to: "sessions#new", as: :"#{scope_name}_login"
      post "login", to: "sessions#create"
      delete "logout", to: "sessions#destroy", as: :"#{scope_name}_logout"

      get "signup", to: "registrations#new", as: :"#{scope_name}_signup"
      post "signup", to: "registrations#create"

      # Password reset routes
      get "password/new", to: "passwords#new", as: :"new_#{scope_name}_password"
      post "password", to: "passwords#create", as: :"#{scope_name}_password"
      get "password/edit", to: "passwords#edit", as: :"edit_#{scope_name}_password"
      patch "password", to: "passwords#update"
    end
  end
end
