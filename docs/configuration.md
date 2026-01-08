# Configuration

## Basic Configuration

Create an initializer at `config/initializers/better_authy.rb`:

```ruby
BetterAuthy.configure do |config|
  config.scope :user do |scope|
    scope.model_name = "User"
  end
end
```

## Scope Options

Each scope supports these configuration options:

```ruby
BetterAuthy.configure do |config|
  config.scope :account do |scope|
    # Required: The model class name
    scope.model_name = "Account"

    # Optional: Session key (default: :account_id)
    scope.session_key = :account_id

    # Optional: Remember cookie name (default: :_remember_account_token)
    scope.remember_cookie = :_remember_account_token

    # Optional: Remember me duration (default: 2.weeks)
    scope.remember_for = 1.month

    # Optional: Password reset token expiration (default: 1.hour)
    scope.password_reset_within = 2.hours

    # Optional: Redirect when not authenticated (default: /auth/account/login)
    scope.sign_in_path = "/login"

    # Optional: Redirect after login (default: /)
    scope.after_sign_in_path = "/dashboard"

    # Optional: Layout for auth views (default: better_authy/application)
    scope.layout = "application"
  end
end
```

## Cookie Security

### Via Configuration

```ruby
BetterAuthy.configure do |config|
  config.cookie_config = {
    secure: true,        # HTTPS only
    httponly: true,      # Not accessible via JavaScript
    same_site: :strict   # CSRF protection
  }
end
```

### Via Environment Variable

```bash
# In production
BETTER_AUTHY_SECURE_COOKIES=true
```

## Multiple Scopes

Configure multiple authenticatable models:

```ruby
BetterAuthy.configure do |config|
  # Regular users
  config.scope :user do |scope|
    scope.model_name = "User"
    scope.after_sign_in_path = "/dashboard"
  end

  # Admin users
  config.scope :admin do |scope|
    scope.model_name = "Admin"
    scope.sign_in_path = "/admin/login"
    scope.after_sign_in_path = "/admin/dashboard"
    scope.remember_for = 8.hours
  end

  # API accounts
  config.scope :account do |scope|
    scope.model_name = "Account"
    scope.after_sign_in_path = "/api/dashboard"
  end
end
```

## Accessing Configuration

```ruby
# Get global configuration
BetterAuthy.configuration

# Get scope configuration (returns nil if not found)
BetterAuthy.scope_for(:user)

# Get scope configuration (raises error if not found)
BetterAuthy.scope_for!(:user)

# Get model class for scope
BetterAuthy.scope_for!(:user).model_class  # => User
```

## Password Validation

Customize password requirements per model:

```ruby
class User < ApplicationRecord
  better_authy_authenticable :user, password_minimum: 12
end
```

```ruby
class Admin < ApplicationRecord
  better_authy_authenticable :admin, password_minimum: 16
end
```

## Reset Configuration (Testing)

In tests, reset configuration before each example:

```ruby
before do
  BetterAuthy.reset_configuration!
  BetterAuthy.configure do |config|
    config.scope :user do |scope|
      scope.model_name = "User"
    end
  end
end
```
