# Testing

## Setup

### RSpec Configuration

```ruby
# spec/rails_helper.rb
require "better_authy"

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include ActiveSupport::Testing::TimeHelpers

  # Reset BetterAuthy configuration before each test
  config.before(:each) do
    BetterAuthy.reset_configuration!
  end
end
```

### Configure Scope for Tests

```ruby
# spec/support/better_authy_helpers.rb
module BetterAuthyHelpers
  def configure_user_scope
    BetterAuthy.configure do |config|
      config.scope :user do |scope|
        scope.model_name = "User"
      end
    end
  end

  def configure_admin_scope
    BetterAuthy.configure do |config|
      config.scope :admin do |scope|
        scope.model_name = "Admin"
      end
    end
  end
end

RSpec.configure do |config|
  config.include BetterAuthyHelpers
end
```

## Factory Setup

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { "password123" }
    password_confirmation { "password123" }
  end
end

# spec/factories/admins.rb
FactoryBot.define do
  factory :admin do
    email { Faker::Internet.email }
    password { "secureadminpass123" }
    password_confirmation { "secureadminpass123" }
  end
end
```

## Request Spec Helpers

```ruby
# spec/support/request_helpers.rb
module RequestHelpers
  def sign_in(resource, scope: :user)
    post "/auth/#{scope}/login", params: {
      session: {
        email: resource.email,
        password: resource.password
      }
    }
  end

  def sign_out(scope: :user)
    delete "/auth/#{scope}/logout"
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
```

## Model Tests

### Testing Authenticable Concern

```ruby
# spec/models/user_spec.rb
RSpec.describe User do
  before { configure_user_scope }

  describe "validations" do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should have_secure_password }
  end

  describe "email normalization" do
    it "normalizes email to lowercase" do
      user = create(:user, email: "TEST@EXAMPLE.COM")
      expect(user.email).to eq("test@example.com")
    end

    it "strips whitespace from email" do
      user = create(:user, email: "  test@example.com  ")
      expect(user.email).to eq("test@example.com")
    end
  end

  describe "#remember_me!" do
    let(:user) { create(:user) }

    it "generates remember token" do
      token = user.remember_me!
      expect(token).to be_present
      expect(user.remember_token_digest).to be_present
    end

    it "sets remember_created_at" do
      freeze_time do
        user.remember_me!
        expect(user.remember_created_at).to eq(Time.current)
      end
    end
  end

  describe "#remember_token_valid?" do
    let(:user) { create(:user) }

    it "returns true for valid token" do
      token = user.remember_me!
      expect(user.remember_token_valid?(token)).to be true
    end

    it "returns false for invalid token" do
      user.remember_me!
      expect(user.remember_token_valid?("invalid")).to be false
    end

    it "returns false for expired token" do
      token = user.remember_me!

      travel 3.weeks do
        expect(user.remember_token_valid?(token)).to be false
      end
    end
  end

  describe "#forget_me!" do
    let(:user) { create(:user) }

    it "clears remember token" do
      user.remember_me!
      user.forget_me!

      expect(user.remember_token_digest).to be_nil
      expect(user.remember_created_at).to be_nil
    end
  end

  describe "#track_sign_in!" do
    let(:user) { create(:user) }
    let(:request) { double("request", remote_ip: "192.168.1.1") }

    it "increments sign_in_count" do
      expect { user.track_sign_in!(request) }
        .to change { user.sign_in_count }.by(1)
    end

    it "updates sign_in timestamps" do
      freeze_time do
        user.track_sign_in!(request)

        expect(user.current_sign_in_at).to eq(Time.current)
        expect(user.current_sign_in_ip).to eq("192.168.1.1")
      end
    end
  end
end
```

### Testing Password Reset

```ruby
RSpec.describe "Password Reset" do
  before { configure_user_scope }

  let(:user) { create(:user) }

  describe "#generate_password_reset_token!" do
    it "generates token and sets timestamp" do
      freeze_time do
        token = user.generate_password_reset_token!

        expect(token).to be_present
        expect(user.password_reset_token_digest).to be_present
        expect(user.password_reset_sent_at).to eq(Time.current)
      end
    end
  end

  describe "#password_reset_token_valid?" do
    it "returns true for valid unexpired token" do
      token = user.generate_password_reset_token!
      expect(user.password_reset_token_valid?(token)).to be true
    end

    it "returns false for expired token" do
      token = user.generate_password_reset_token!

      travel 2.hours do
        expect(user.password_reset_token_valid?(token)).to be false
      end
    end
  end

  describe "#reset_password!" do
    it "updates password when confirmation matches" do
      token = user.generate_password_reset_token!

      expect(user.reset_password!("newpassword", "newpassword")).to be true
      expect(user.authenticate("newpassword")).to be_truthy
    end

    it "clears reset token after successful reset" do
      user.generate_password_reset_token!
      user.reset_password!("newpassword", "newpassword")

      expect(user.password_reset_token_digest).to be_nil
    end

    it "returns false when confirmation doesn't match" do
      user.generate_password_reset_token!

      expect(user.reset_password!("password", "different")).to be false
    end
  end
end
```

## Request Tests

### Testing Authentication Flow

```ruby
# spec/requests/authentication_spec.rb
RSpec.describe "Authentication", type: :request do
  before { configure_user_scope }

  let(:user) { create(:user, password: "password123") }

  describe "POST /auth/user/login" do
    it "signs in with valid credentials" do
      post "/auth/user/login", params: {
        session: { email: user.email, password: "password123" }
      }

      expect(response).to redirect_to("/")
      expect(session[:user_id]).to eq(user.id)
    end

    it "fails with invalid credentials" do
      post "/auth/user/login", params: {
        session: { email: user.email, password: "wrong" }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(session[:user_id]).to be_nil
    end
  end

  describe "DELETE /auth/user/logout" do
    before { sign_in(user) }

    it "signs out the user" do
      delete "/auth/user/logout"

      expect(response).to redirect_to("/")
      expect(session[:user_id]).to be_nil
    end
  end
end
```

### Testing Protected Routes

```ruby
# spec/requests/dashboard_spec.rb
RSpec.describe "Dashboard", type: :request do
  before { configure_user_scope }

  describe "GET /dashboard" do
    context "when signed in" do
      let(:user) { create(:user) }

      before { sign_in(user) }

      it "returns success" do
        get "/dashboard"
        expect(response).to have_http_status(:ok)
      end
    end

    context "when not signed in" do
      it "redirects to login" do
        get "/dashboard"
        expect(response).to redirect_to("/auth/user/login")
      end
    end
  end
end
```

## Controller Tests

### Testing with Dynamic Models

```ruby
RSpec.describe BetterAuthy::ControllerHelpers do
  before do
    BetterAuthy.reset_configuration!
    BetterAuthy.configure do |config|
      config.scope :account do |scope|
        scope.model_name = "Account"
      end
    end
  end

  let(:controller_class) do
    Class.new(ActionController::Base) do
      include BetterAuthy::ControllerHelpers
    end
  end

  let(:controller) { controller_class.new }

  it "defines current_account method" do
    expect(controller).to respond_to(:current_account)
  end

  it "defines account_signed_in? method" do
    expect(controller).to respond_to(:account_signed_in?)
  end
end
```

## Integration Tests

```ruby
# spec/features/user_authentication_spec.rb
RSpec.describe "User authentication flow", type: :feature do
  before { configure_user_scope }

  let(:user) { create(:user, email: "test@example.com", password: "password123") }

  scenario "user signs in and out" do
    visit "/auth/user/login"

    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Sign in"

    expect(page).to have_content("Signed in successfully")

    click_button "Logout"

    expect(page).to have_content("Signed out")
  end
end
```

## Time-Dependent Tests

Always use `freeze_time` or `travel` for time-sensitive tests:

```ruby
describe "token expiration" do
  it "expires after configured duration" do
    freeze_time do
      token = user.remember_me!
      expect(user.remember_token_valid?(token)).to be true
    end

    travel 3.weeks do
      expect(user.remember_token_valid?(token)).to be false
    end
  end
end
```

## Mocking Cookies

```ruby
describe "remember me cookie" do
  let(:cookies) { double("cookies") }
  let(:encrypted) { double("encrypted") }

  before do
    allow(controller).to receive(:cookies).and_return(cookies)
    allow(cookies).to receive(:encrypted).and_return(encrypted)
  end

  it "sets encrypted cookie" do
    expect(encrypted).to receive(:[]=).with(
      :_remember_user_token,
      hash_including(value: anything, expires: anything)
    )

    controller.sign_in_user(user, remember: true)
  end
end
```
