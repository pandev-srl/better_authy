# Models

## Making a Model Authenticatable

Add the `better_authy_authenticable` macro to your model:

```ruby
class User < ApplicationRecord
  better_authy_authenticable :user
end
```

This includes the `BetterAuthy::Models::Authenticable` concern which provides:

- Password hashing via bcrypt
- Email validation and normalization
- Remember me tokens
- Sign-in tracking
- Password reset functionality

## Required Database Schema

```ruby
class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users, id: :uuid do |t|
      t.timestamps null: false

      # Authentication
      t.string :email, null: false
      t.string :password_digest, null: false

      # Remember me
      t.string :remember_token_digest
      t.datetime :remember_created_at

      # Password reset
      t.string :password_reset_token_digest
      t.datetime :password_reset_sent_at

      # Sign-in tracking
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

## Email Validation

Emails are automatically:

- Validated for presence and format
- Normalized (lowercase, stripped)
- Checked for uniqueness (case-insensitive)

```ruby
user = User.new(email: "  JOHN@EXAMPLE.COM  ")
user.valid?
user.email  # => "john@example.com"
```

## Password Handling

Passwords use bcrypt via `has_secure_password`:

```ruby
# Create user with password
user = User.create!(
  email: "john@example.com",
  password: "securepassword123",
  password_confirmation: "securepassword123"
)

# Authenticate
user.authenticate("securepassword123")  # => user
user.authenticate("wrongpassword")       # => false
```

### Custom Password Length

```ruby
class User < ApplicationRecord
  better_authy_authenticable :user, password_minimum: 12
end
```

## Remember Me

Generate and validate remember tokens:

```ruby
# Generate token (returns plain token, stores hash in DB)
token = user.remember_me!

# Check if token is valid
user.remember_token_valid?(token)  # => true

# Clear remember token
user.forget_me!
```

Token expiration is configured per scope:

```ruby
config.scope :user do |scope|
  scope.remember_for = 2.weeks  # default
end
```

## Sign-In Tracking

Track sign-in activity:

```ruby
user.track_sign_in!(request)
```

This updates:

- `sign_in_count` - incremented
- `last_sign_in_at` - previous `current_sign_in_at`
- `last_sign_in_ip` - previous `current_sign_in_ip`
- `current_sign_in_at` - current time
- `current_sign_in_ip` - request IP

## Password Reset

Generate and validate reset tokens:

```ruby
# Generate reset token (returns plain token)
token = user.generate_password_reset_token!

# Check if token is valid and not expired
user.password_reset_token_valid?(token)  # => true

# Reset password
user.reset_password!("newpassword", "newpassword")

# Clear token manually
user.clear_password_reset_token!
```

Token expiration is configured per scope:

```ruby
config.scope :user do |scope|
  scope.password_reset_within = 1.hour  # default
end
```

## Scope Information

Access scope from model instance:

```ruby
user = User.find(id)

# Get scope name
user.authenticable_scope  # => :user

# Get scope configuration
user.authenticable_scope_config  # => BetterAuthy::ScopeConfiguration
user.authenticable_scope_config.remember_for  # => 2.weeks
```

## Adding Custom Attributes

Add any additional columns to your model:

```ruby
class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users, id: :uuid do |t|
      t.timestamps null: false

      # BetterAuthy required columns
      t.string :email, null: false
      t.string :password_digest, null: false
      # ... other required columns

      # Your custom columns
      t.string :first_name
      t.string :last_name
      t.string :phone
      t.boolean :admin, default: false

      t.index :email, unique: true
    end
  end
end
```

```ruby
class User < ApplicationRecord
  better_authy_authenticable :user

  # Your custom validations
  validates :first_name, presence: true

  # Your custom methods
  def full_name
    "#{first_name} #{last_name}"
  end
end
```
