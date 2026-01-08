# BetterAuthy

A flexible authentication engine for Rails 8.0+ with multi-scope support. Enables multiple authenticatable models (users, accounts, admins) through a scope-based configuration system.

## Features

- Multi-scope authentication (multiple user types)
- Session-based authentication with encrypted cookies
- Remember me functionality
- Password reset via email
- Sign-in tracking (IP, timestamp, count)

## Quick Start

### 1. Add to Gemfile

```ruby
gem "better_authy", "~> 0.7"
```

### 2. Configure scope

```ruby
# config/initializers/better_authy.rb
BetterAuthy.configure do |config|
  config.scope :user do |scope|
    scope.model_name = "User"
  end
end
```

### 3. Add to model

```ruby
class User < ApplicationRecord
  better_authy_authenticable :user
end
```

### 4. Include controller helpers

```ruby
class ApplicationController < ActionController::Base
  include BetterAuthy::ControllerHelpers
end
```

### 5. Mount engine

```ruby
Rails.application.routes.draw do
  mount BetterAuthy::Engine => "/auth"
end
```

### 6. Create migration

```ruby
class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users, id: :uuid do |t|
      t.timestamps null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :remember_token_digest
      t.datetime :remember_created_at
      t.string :password_reset_token_digest
      t.datetime :password_reset_sent_at
      t.integer :sign_in_count, default: 0
      t.datetime :current_sign_in_at, :last_sign_in_at
      t.string :current_sign_in_ip, :last_sign_in_ip
      t.index :email, unique: true
    end
  end
end
```

## Usage

```ruby
# In controllers
before_action :authenticate_user!
current_user
user_signed_in?

# Manual sign in/out
sign_in_user(user, remember: true)
sign_out_user
```

## Routes

| Path | Description |
|------|-------------|
| `/auth/user/login` | Login |
| `/auth/user/logout` | Logout |
| `/auth/user/signup` | Registration |
| `/auth/user/password/new` | Forgot password |
| `/auth/user/password/edit` | Reset password |

## Documentation

See the [docs/](docs/) folder for detailed guides:

- [Installation](docs/installation.md) - Complete setup instructions
- [Configuration](docs/configuration.md) - All configuration options
- [Models](docs/models.md) - Authenticable model setup
- [Controller Helpers](docs/controller-helpers.md) - Authentication methods
- [Routes](docs/routes.md) - Route helpers and customization
- [Password Reset](docs/password-reset.md) - Password reset flow
- [Multi-Scope](docs/multi-scope.md) - Multiple user types
- [Testing](docs/testing.md) - Test setup and patterns

## Dependencies

- Rails >= 8.0
- bcrypt ~> 3.1
- view_component ~> 4.0
- better_ui ~> 0.7

## License

MIT License
