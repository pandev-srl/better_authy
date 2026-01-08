# frozen_string_literal: true

Rails.application.routes.draw do
  mount BetterAuthy::Engine => "/auth"
end
