# Controller Helpers

## Setup

Include the helpers in your ApplicationController:

```ruby
class ApplicationController < ActionController::Base
  include BetterAuthy::ControllerHelpers
end
```

## Generated Methods

For each configured scope, BetterAuthy generates these methods dynamically.

### For scope `:user`:

| Method | Description |
|--------|-------------|
| `current_user` | Returns the signed-in user or nil |
| `user_signed_in?` | Returns true if a user is signed in |
| `sign_in_user(user, remember: false)` | Signs in the user |
| `sign_out_user` | Signs out the user |
| `authenticate_user!` | Before action filter |

### For scope `:admin`:

| Method | Description |
|--------|-------------|
| `current_admin` | Returns the signed-in admin or nil |
| `admin_signed_in?` | Returns true if an admin is signed in |
| `sign_in_admin(admin, remember: false)` | Signs in the admin |
| `sign_out_admin` | Signs out the admin |
| `authenticate_admin!` | Before action filter |

## Protecting Routes

### Require Authentication

```ruby
class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
  end
end
```

### Multiple Scopes

```ruby
class AdminController < ApplicationController
  before_action :authenticate_admin!

  def index
    @admin = current_admin
  end
end
```

## Accessing Current User

In controllers:

```ruby
class ProfileController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
  end

  def update
    current_user.update!(user_params)
    redirect_to profile_path
  end
end
```

In views:

```erb
<% if user_signed_in? %>
  <p>Welcome, <%= current_user.email %></p>
  <%= link_to "Logout", auth.user_logout_path, data: { turbo_method: :delete } %>
<% else %>
  <%= link_to "Login", auth.user_login_path %>
<% end %>
```

## Manual Sign In

```ruby
class CustomSessionsController < ApplicationController
  def create
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      sign_in_user(user, remember: params[:remember_me])
      redirect_to dashboard_path
    else
      flash[:alert] = "Invalid credentials"
      render :new
    end
  end
end
```

## Manual Sign Out

```ruby
class CustomSessionsController < ApplicationController
  def destroy
    sign_out_user
    redirect_to root_path
  end
end
```

## Remember Me

Enable remember me when signing in:

```ruby
# Without remember me (session only)
sign_in_user(user)

# With remember me (persistent cookie)
sign_in_user(user, remember: true)
```

The cookie persists for the duration configured in the scope:

```ruby
config.scope :user do |scope|
  scope.remember_for = 2.weeks
end
```

## Conditional Logic

```ruby
class ApplicationController < ActionController::Base
  include BetterAuthy::ControllerHelpers

  private

  def after_sign_in_path
    if admin_signed_in?
      admin_dashboard_path
    elsif user_signed_in?
      user_dashboard_path
    else
      root_path
    end
  end
end
```

## Skip Authentication

```ruby
class PublicController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    # Public access
  end

  def edit
    # Requires authentication
  end
end
```

## Custom Unauthorized Handler

Override the `authenticate_*!` behavior:

```ruby
class ApplicationController < ActionController::Base
  include BetterAuthy::ControllerHelpers

  private

  def authenticate_user!
    unless user_signed_in?
      respond_to do |format|
        format.html { redirect_to login_path, alert: "Please sign in" }
        format.json { render json: { error: "Unauthorized" }, status: :unauthorized }
      end
    end
  end
end
```

## Accessing from API Controllers

```ruby
class Api::BaseController < ActionController::API
  include BetterAuthy::ControllerHelpers

  before_action :authenticate_user!

  private

  def authenticate_user!
    render json: { error: "Unauthorized" }, status: :unauthorized unless user_signed_in?
  end
end
```

## View Helpers

`current_user` and `user_signed_in?` are automatically available as view helpers:

```erb
<%# app/views/layouts/application.html.erb %>
<nav>
  <% if user_signed_in? %>
    <span>Logged in as <%= current_user.email %></span>
    <%= button_to "Logout", auth.user_logout_path, method: :delete %>
  <% else %>
    <%= link_to "Login", auth.user_login_path %>
    <%= link_to "Sign up", auth.user_signup_path %>
  <% end %>
</nav>
```
