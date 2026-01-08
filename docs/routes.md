# Routes

## Mounting the Engine

Mount BetterAuthy in your routes file:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount BetterAuthy::Engine => "/auth"
end
```

## Generated Routes

Routes are generated dynamically for each configured scope. For a scope named `:user`:

| Path | Method | Controller#Action | Description |
|------|--------|-------------------|-------------|
| `/auth/user/login` | GET | `sessions#new` | Login form |
| `/auth/user/login` | POST | `sessions#create` | Create session |
| `/auth/user/logout` | DELETE | `sessions#destroy` | Destroy session |
| `/auth/user/signup` | GET | `registrations#new` | Registration form |
| `/auth/user/signup` | POST | `registrations#create` | Create account |
| `/auth/user/password/new` | GET | `passwords#new` | Forgot password form |
| `/auth/user/password` | POST | `passwords#create` | Send reset email |
| `/auth/user/password/edit` | GET | `passwords#edit` | Reset password form |
| `/auth/user/password` | PATCH | `passwords#update` | Update password |

## Route Helpers

Access route helpers using the `auth` namespace:

```ruby
# In controllers
redirect_to auth.user_login_path

# In views
<%= link_to "Login", auth.user_login_path %>
<%= link_to "Sign up", auth.user_signup_path %>
<%= button_to "Logout", auth.user_logout_path, method: :delete %>
```

### Available Route Helpers

For scope `:user`:

```ruby
auth.user_login_path       # GET  /auth/user/login
auth.user_login_path       # POST /auth/user/login
auth.user_logout_path      # DELETE /auth/user/logout
auth.user_signup_path      # GET/POST /auth/user/signup
auth.new_user_password_path  # GET /auth/user/password/new
auth.user_password_path      # POST/PATCH /auth/user/password
auth.edit_user_password_path # GET /auth/user/password/edit
```

For scope `:admin`:

```ruby
auth.admin_login_path
auth.admin_logout_path
auth.admin_signup_path
auth.new_admin_password_path
auth.admin_password_path
auth.edit_admin_password_path
```

## Custom Mount Path

Mount at a different path:

```ruby
# config/routes.rb
mount BetterAuthy::Engine => "/account"
```

Routes become:
- `/account/user/login`
- `/account/user/signup`
- etc.

## Multiple Mount Points

Mount the engine multiple times with different paths (advanced):

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # User auth at /auth
  mount BetterAuthy::Engine => "/auth", as: "user_auth"

  # Admin auth at /admin/auth
  mount BetterAuthy::Engine => "/admin/auth", as: "admin_auth"
end
```

## URL Generation

### In Controllers

```ruby
class ApplicationController < ActionController::Base
  include BetterAuthy::ControllerHelpers

  private

  def after_sign_in_redirect
    if admin_signed_in?
      admin_dashboard_path
    else
      root_path
    end
  end

  def require_authentication
    unless user_signed_in?
      redirect_to auth.user_login_path, alert: "Please sign in"
    end
  end
end
```

### In Views

```erb
<%# Login link %>
<%= link_to "Sign in", auth.user_login_path %>

<%# Logout button with Turbo %>
<%= button_to "Sign out", auth.user_logout_path, method: :delete %>

<%# Registration link %>
<%= link_to "Create account", auth.user_signup_path %>

<%# Password reset link %>
<%= link_to "Forgot password?", auth.new_user_password_path %>
```

### In Mailers

```ruby
class PasswordResetMailer < ApplicationMailer
  include BetterAuthy::Engine.routes.url_helpers

  def reset_email(user, token)
    @reset_url = edit_user_password_url(token: token, host: default_url_options[:host])
    mail(to: user.email, subject: "Reset your password")
  end

  private

  def default_url_options
    Rails.application.config.action_mailer.default_url_options || {}
  end
end
```

## Listing Routes

View all BetterAuthy routes:

```bash
rails routes -g better_authy
```

Example output:

```
           Prefix Verb   URI Pattern                        Controller#Action
user_login        GET    /auth/user/login(.:format)         better_authy/sessions#new
                  POST   /auth/user/login(.:format)         better_authy/sessions#create
user_logout       DELETE /auth/user/logout(.:format)        better_authy/sessions#destroy
user_signup       GET    /auth/user/signup(.:format)        better_authy/registrations#new
                  POST   /auth/user/signup(.:format)        better_authy/registrations#create
new_user_password GET    /auth/user/password/new(.:format)  better_authy/passwords#new
user_password     POST   /auth/user/password(.:format)      better_authy/passwords#create
edit_user_password GET   /auth/user/password/edit(.:format) better_authy/passwords#edit
                  PATCH  /auth/user/password(.:format)      better_authy/passwords#update
```

## Route Constraints

Add constraints to authentication routes:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Only allow auth routes in production from specific IPs for admin
  constraints ->(req) { req.path !~ /admin/ || AdminIpAllowlist.include?(req.remote_ip) } do
    mount BetterAuthy::Engine => "/auth"
  end
end
```

## Subdomain Routing

Mount engine on a subdomain:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  constraints subdomain: "auth" do
    mount BetterAuthy::Engine => "/"
  end
end
```

Routes become:
- `auth.yourapp.com/user/login`
- `auth.yourapp.com/user/signup`

## API Routes

For API-only applications, you might want to create custom routes:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post "login", to: "sessions#create"
      delete "logout", to: "sessions#destroy"
      post "signup", to: "registrations#create"
    end
  end
end
```

Then create custom controllers that use BetterAuthy helpers:

```ruby
# app/controllers/api/v1/sessions_controller.rb
class Api::V1::SessionsController < Api::BaseController
  def create
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      sign_in_user(user)
      render json: { user: user.as_json(only: [:id, :email]) }
    else
      render json: { error: "Invalid credentials" }, status: :unauthorized
    end
  end

  def destroy
    sign_out_user
    head :no_content
  end
end
```
