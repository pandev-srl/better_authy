# Password Reset

BetterAuthy provides a complete password reset flow with secure token handling.

## Routes

The engine provides these password reset routes:

| Path | Method | Action |
|------|--------|--------|
| `/auth/user/password/new` | GET | Forgot password form |
| `/auth/user/password` | POST | Send reset email |
| `/auth/user/password/edit` | GET | Reset password form |
| `/auth/user/password` | PATCH | Update password |

## Flow Overview

1. User requests password reset via email
2. System generates secure token and sends email
3. User clicks link in email
4. User enters new password
5. Password is updated and token is cleared

## Token Generation

```ruby
# Generate a password reset token
token = user.generate_password_reset_token!

# This sets:
# - password_reset_token_digest (bcrypt hash)
# - password_reset_sent_at (current time)

# Returns the plain token for inclusion in email
```

## Token Validation

```ruby
# Check if token is valid and not expired
user.password_reset_token_valid?(token)  # => true/false
```

Tokens expire based on scope configuration:

```ruby
config.scope :user do |scope|
  scope.password_reset_within = 1.hour  # default
end
```

## Password Update

```ruby
# Reset password with confirmation
result = user.reset_password!("newpassword", "newpassword")

if result
  # Password updated, token cleared
else
  # Passwords don't match
end
```

## Mailer Setup

### Configure Action Mailer

```ruby
# config/environments/development.rb
config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
config.action_mailer.delivery_method = :letter_opener

# config/environments/production.rb
config.action_mailer.default_url_options = { host: "yourapp.com" }
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: "smtp.example.com",
  port: 587,
  user_name: ENV["SMTP_USERNAME"],
  password: ENV["SMTP_PASSWORD"],
  authentication: "plain",
  enable_starttls_auto: true
}
```

### Default Mailer

BetterAuthy includes `BetterAuthy::PasswordResetMailer` that sends reset emails automatically.

## Custom Mailer

Override the default mailer:

```ruby
# app/mailers/custom_password_reset_mailer.rb
class CustomPasswordResetMailer < ApplicationMailer
  def reset_email(user, token, scope_name)
    @user = user
    @token = token
    @scope_name = scope_name
    @reset_url = edit_password_url(token: token)

    mail(
      to: user.email,
      subject: "Reset your password"
    )
  end

  private

  def edit_password_url(token:)
    # Build the URL for your app
    "#{root_url}auth/#{@scope_name}/password/edit?token=#{token}"
  end
end
```

```erb
<%# app/views/custom_password_reset_mailer/reset_email.html.erb %>
<h1>Password Reset</h1>

<p>Hi <%= @user.email %>,</p>

<p>Someone requested a password reset for your account.</p>

<p><%= link_to "Reset Password", @reset_url %></p>

<p>If you didn't request this, please ignore this email.</p>

<p>This link expires in 1 hour.</p>
```

## Manual Password Reset

Implement custom password reset logic:

```ruby
class PasswordResetsController < ApplicationController
  def create
    user = User.find_by(email: params[:email])

    if user
      token = user.generate_password_reset_token!
      PasswordResetMailer.reset_email(user, token).deliver_later
    end

    # Always show success to prevent email enumeration
    redirect_to login_path, notice: "Check your email for reset instructions"
  end

  def edit
    @token = params[:token]
  end

  def update
    user = User.find_by(email: params[:email])

    if user&.password_reset_token_valid?(params[:token])
      if user.reset_password!(params[:password], params[:password_confirmation])
        redirect_to login_path, notice: "Password updated successfully"
      else
        flash[:alert] = "Passwords don't match"
        render :edit
      end
    else
      redirect_to new_password_reset_path, alert: "Invalid or expired token"
    end
  end
end
```

## Security Considerations

### Email Enumeration Prevention

The default controller returns a generic message regardless of whether the email exists:

```ruby
# Always shows this message
flash[:notice] = "If your email is registered, you'll receive reset instructions"
```

### Token Security

- Tokens are generated using `SecureRandom.urlsafe_base64(32)`
- Only the bcrypt hash is stored in the database
- Tokens expire after the configured duration
- Tokens are single-use (cleared after password update)

### Rate Limiting

Consider adding rate limiting to prevent abuse:

```ruby
class PasswordResetsController < ApplicationController
  before_action :check_rate_limit, only: :create

  private

  def check_rate_limit
    # Implement your rate limiting logic
    # e.g., using rack-attack or custom solution
  end
end
```

## Testing Password Reset

```ruby
RSpec.describe "Password Reset" do
  let(:user) { create(:user) }

  it "generates valid reset token" do
    token = user.generate_password_reset_token!

    expect(user.password_reset_token_valid?(token)).to be true
  end

  it "expires token after configured duration" do
    token = user.generate_password_reset_token!

    travel 2.hours do
      expect(user.password_reset_token_valid?(token)).to be false
    end
  end

  it "resets password successfully" do
    token = user.generate_password_reset_token!

    expect(user.reset_password!("newpassword", "newpassword")).to be true
    expect(user.authenticate("newpassword")).to be_truthy
  end

  it "clears token after reset" do
    token = user.generate_password_reset_token!
    user.reset_password!("newpassword", "newpassword")

    expect(user.password_reset_token_digest).to be_nil
  end
end
```
