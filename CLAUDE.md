# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

BetterAuthy is a Rails 8.0+ authentication engine with multi-scope support. It enables multiple authenticatable models (users, accounts, admins) through a scope-based configuration system.

## Commands

### Testing
```bash
bundle exec rspec                           # Run all tests
bundle exec rspec spec/lib/better_authy/    # Run specific directory
bundle exec rspec spec/path/to_spec.rb:42   # Run specific line
bundle exec rspec --format doc              # Verbose output
```

### Coverage
SimpleCov is configured with 90% minimum coverage. Coverage report generates to `coverage/`.

## Architecture

### Configuration Layer
- **BetterAuthy::Configuration** - Global scope registry, cookie settings (`cookie_config` hash)
- **BetterAuthy::ScopeConfiguration** - Per-scope settings (model_name, session_key, remember_cookie, remember_for, sign_in_path, after_sign_in_path)

### Model Layer
- **BetterAuthy::ModelExtensions** - Provides `better_authy_authenticable :scope_name` macro for ActiveRecord models
- **BetterAuthy::Models::Authenticable** - Concern included by macro: password hashing (bcrypt), email validation/normalization, remember tokens, sign-in tracking

### Controller Layer
- **BetterAuthy::ControllerHelpers** - Dynamically generates per-scope helpers: `current_{scope}`, `{scope}_signed_in?`, `sign_in_{scope}`, `sign_out_{scope}`, `authenticate_{scope}!`

### Cookie Security
Cookies use `cookies.encrypted` with configurable options:
```ruby
BetterAuthy.configure do |config|
  config.cookie_config = { secure: true, same_site: :strict }
end
```
ENV: `BETTER_AUTHY_SECURE_COOKIES=true` sets secure flag (default: false)

## Development Rules

### TDD (Required)
1. Write test first (RED)
2. Write minimum code to pass (GREEN)
3. Refactor if needed

### Database Schema for Authenticatable Models
```ruby
t.timestamps null: false                    # Immediately after primary key
t.string :email, null: false                # With unique index
t.string :password_digest, null: false
t.string :remember_token_digest             # Nullable
t.datetime :remember_created_at             # Nullable
t.string :password_reset_token_digest       # Nullable
t.datetime :password_reset_sent_at          # Nullable
t.integer :sign_in_count, default: 0
t.datetime :current_sign_in_at, :last_sign_in_at
t.string :current_sign_in_ip, :last_sign_in_ip
```

### Testing Patterns
- Reset configuration in `before` blocks: `BetterAuthy.reset_configuration!`
- Use `Class.new(ApplicationRecord)` + `stub_const` for dynamic test models
- Use `travel`/`freeze_time` from ActiveSupport::TimeHelpers for time-dependent tests
- Factories in `spec/factories/`

## Configuration Example
```ruby
BetterAuthy.configure do |config|
  config.scope :account do |scope|
    scope.model_name = "Account"            # Required
    scope.remember_for = 1.month            # Optional override
    scope.sign_in_path = "/login"           # Optional override
  end
end
```

## Git Commit Style (Conventional Commits)
Use format: `<type>(<scope>): <description>`

**Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation only
- `style:` - Formatting (no logic change)
- `refactor:` - Refactoring without new features or fixes
- `test:` - Adding/modifying tests
- `chore:` - Maintenance (build, deps, configs)

**Examples:**
```
feat: add password reset functionality
fix: correct token expiration check
docs: update README with installation instructions
```
