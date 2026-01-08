# BetterAuthy

A flexible authentication engine for Rails 8.0+ with multi-scope support. Enables multiple authenticatable models (users, accounts, admins) through a scope-based configuration system.

## Features

- Multi-scope authentication (multiple user types)
- Session-based authentication with encrypted cookies
- Remember me functionality
- Password reset via email
- Sign-in tracking (IP, timestamp, count)
- TDD-ready with complete test suite
- Integrates with BetterUI components

## Installation

Add to your Gemfile:

```ruby
gem "better_authy", "~> 0.7"
```

Then run:
```bash
bundle install
```

## Configuration

### 1. Create an initializer

```ruby
# config/initializers/better_authy.rb
BetterAuthy.configure do |config|
  config.scope :account do |scope|
    scope.model_name = "Account"
    scope.remember_for = 2.weeks
    scope.after_sign_in_path = "/"
    scope.layout = "better_authy"
  end
end
```

### 2. Add authenticable to your model

```ruby
# app/models/account.rb
class Account < ApplicationRecord
  better_authy_authenticable :account
end
```

### 3. Include controller helpers

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include BetterAuthy::ControllerHelpers
end
```

### 4. Mount the engine

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount BetterAuthy::Engine => "/auth"
end
```

### 5. Create required database fields

```ruby
# Migration for authenticatable model
class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts, id: :uuid do |t|
      t.timestamps null: false

      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :remember_token_digest
      t.datetime :remember_created_at
      t.string :password_reset_token_digest
      t.datetime :password_reset_sent_at
      t.integer :sign_in_count, default: 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip

      t.index :email, unique: true
    end
  end
end
```

## Usage

### Controller Helpers

For each scope, the following helpers are available:

```ruby
current_account          # Returns the signed-in account
account_signed_in?       # Boolean: is an account signed in?
sign_in_account(account) # Sign in the account
sign_out_account         # Sign out the account
authenticate_account!    # Before action to require authentication
```

### Protecting Routes

```ruby
class DashboardController < ApplicationController
  before_action :authenticate_account!

  def index
    @account = current_account
  end
end
```

### Routes

The engine provides these routes (for `:account` scope):

| Path | Action |
|------|--------|
| GET `/auth/account/login` | Login form |
| POST `/auth/account/login` | Create session |
| DELETE `/auth/account/logout` | Destroy session |
| GET `/auth/account/signup` | Registration form |
| POST `/auth/account/signup` | Create account |
| GET `/auth/account/password/new` | Forgot password form |
| POST `/auth/account/password` | Send reset email |
| GET `/auth/account/password/edit` | Reset password form |
| PATCH `/auth/account/password` | Update password |

## Scope Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `model_name` | Required | The model class name (e.g., "Account") |
| `remember_for` | `2.weeks` | Duration for remember me cookies |
| `password_reset_within` | `1.hour` | Token expiration for password reset |
| `sign_in_path` | `/auth/{scope}/login` | Redirect path when not authenticated |
| `after_sign_in_path` | `/` | Redirect path after successful login |
| `layout` | `better_authy/application` | Layout for auth views |

## Cookie Security

Configure secure cookies:

```ruby
BetterAuthy.configure do |config|
  config.cookie_config = { secure: true, same_site: :strict }
end
```

Or via environment variable:
```bash
BETTER_AUTHY_SECURE_COOKIES=true
```

## Dependencies

- Rails >= 8.0
- bcrypt ~> 3.1
- view_component ~> 4.0
- better_ui ~> 0.7

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
