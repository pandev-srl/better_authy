# Multi-Scope Authentication

BetterAuthy's core feature is support for multiple authenticatable models (scopes) in a single application.

## Use Cases

- **Users and Admins**: Separate user types with different permissions
- **Multi-tenant**: Different account types (personal, business, enterprise)
- **SaaS**: End users, team admins, super admins
- **Marketplace**: Buyers, sellers, administrators

## Configuration

Define multiple scopes in your initializer:

```ruby
# config/initializers/better_authy.rb
BetterAuthy.configure do |config|
  # Regular users
  config.scope :user do |scope|
    scope.model_name = "User"
    scope.remember_for = 2.weeks
    scope.after_sign_in_path = "/dashboard"
  end

  # Admin users
  config.scope :admin do |scope|
    scope.model_name = "Admin"
    scope.remember_for = 8.hours
    scope.sign_in_path = "/admin/login"
    scope.after_sign_in_path = "/admin"
  end

  # Seller accounts
  config.scope :seller do |scope|
    scope.model_name = "Seller"
    scope.after_sign_in_path = "/seller/dashboard"
  end
end
```

## Models

Create a model for each scope:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  better_authy_authenticable :user
end

# app/models/admin.rb
class Admin < ApplicationRecord
  better_authy_authenticable :admin, password_minimum: 16
end

# app/models/seller.rb
class Seller < ApplicationRecord
  better_authy_authenticable :seller
end
```

## Database Tables

Each scope needs its own table with required columns:

```ruby
class CreateAdmins < ActiveRecord::Migration[8.0]
  def change
    create_table :admins, id: :uuid do |t|
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

      # Admin-specific columns
      t.string :role, default: "editor"
      t.boolean :super_admin, default: false

      t.index :email, unique: true
    end
  end
end
```

## Routes

Mount the engine once - routes are generated for all scopes:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount BetterAuthy::Engine => "/auth"
end
```

This creates routes for each scope:

| Scope | Login Path | Signup Path |
|-------|------------|-------------|
| `:user` | `/auth/user/login` | `/auth/user/signup` |
| `:admin` | `/auth/admin/login` | `/auth/admin/signup` |
| `:seller` | `/auth/seller/login` | `/auth/seller/signup` |

## Controller Helpers

Each scope gets its own set of helpers:

```ruby
class ApplicationController < ActionController::Base
  include BetterAuthy::ControllerHelpers
end

# Now available:
# - current_user, user_signed_in?, sign_in_user, sign_out_user, authenticate_user!
# - current_admin, admin_signed_in?, sign_in_admin, sign_out_admin, authenticate_admin!
# - current_seller, seller_signed_in?, sign_in_seller, sign_out_seller, authenticate_seller!
```

## Protecting Controllers

### User Area

```ruby
class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
  end
end
```

### Admin Area

```ruby
class Admin::BaseController < ApplicationController
  before_action :authenticate_admin!
  layout "admin"
end

class Admin::DashboardController < Admin::BaseController
  def index
    @admin = current_admin
    @users = User.all
  end
end
```

### Seller Area

```ruby
class Seller::BaseController < ApplicationController
  before_action :authenticate_seller!

  private

  def current_store
    current_seller.store
  end
end
```

## Multiple Sessions

Users can be signed in to multiple scopes simultaneously:

```ruby
# In a controller
def status
  {
    user_signed_in: user_signed_in?,
    admin_signed_in: admin_signed_in?,
    current_user_email: current_user&.email,
    current_admin_email: current_admin&.email
  }
end
```

Sessions are independent - signing out of one scope doesn't affect others:

```ruby
sign_out_user   # Only signs out user, admin remains signed in
sign_out_admin  # Only signs out admin
```

## Navigation

```erb
<nav>
  <% if user_signed_in? %>
    <span>User: <%= current_user.email %></span>
    <%= link_to "User Dashboard", dashboard_path %>
    <%= button_to "Logout", auth.user_logout_path, method: :delete %>
  <% end %>

  <% if admin_signed_in? %>
    <span>Admin: <%= current_admin.email %></span>
    <%= link_to "Admin Panel", admin_path %>
    <%= button_to "Admin Logout", auth.admin_logout_path, method: :delete %>
  <% end %>

  <% unless user_signed_in? %>
    <%= link_to "User Login", auth.user_login_path %>
  <% end %>

  <% unless admin_signed_in? %>
    <%= link_to "Admin Login", auth.admin_login_path %>
  <% end %>
</nav>
```

## Cross-Scope Authorization

Require multiple authentications:

```ruby
class SuperAdminController < ApplicationController
  before_action :authenticate_admin!
  before_action :require_super_admin

  private

  def require_super_admin
    unless current_admin.super_admin?
      redirect_to admin_root_path, alert: "Super admin access required"
    end
  end
end
```

## Shared Layout with Scope Detection

```erb
<%# app/views/layouts/application.html.erb %>
<header>
  <% if admin_signed_in? %>
    <div class="admin-bar">Admin Mode: <%= current_admin.email %></div>
  <% end %>

  <nav>
    <%= render "shared/user_nav" if user_signed_in? %>
    <%= render "shared/guest_nav" unless user_signed_in? %>
  </nav>
</header>
```

## Testing Multiple Scopes

```ruby
RSpec.describe "Multi-scope authentication" do
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }

  before do
    BetterAuthy.reset_configuration!
    BetterAuthy.configure do |config|
      config.scope(:user) { |s| s.model_name = "User" }
      config.scope(:admin) { |s| s.model_name = "Admin" }
    end
  end

  it "allows simultaneous sessions" do
    sign_in_as(user, scope: :user)
    sign_in_as(admin, scope: :admin)

    expect(session[:user_id]).to eq(user.id)
    expect(session[:admin_id]).to eq(admin.id)
  end

  it "signs out independently" do
    sign_in_as(user, scope: :user)
    sign_in_as(admin, scope: :admin)

    delete "/auth/user/logout"

    expect(session[:user_id]).to be_nil
    expect(session[:admin_id]).to eq(admin.id)
  end
end
```
