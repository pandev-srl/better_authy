# Installation

## Requirements

- Ruby >= 3.2.0
- Rails >= 8.0
- bcrypt ~> 3.1

## Add to Gemfile

```ruby
gem "better_authy", "~> 0.1.0"
```

Then install:

```bash
bundle install
```

## Quick Setup

### 1. Create the initializer

```ruby
# config/initializers/better_authy.rb
BetterAuthy.configure do |config|
  config.scope :user do |scope|
    scope.model_name = "User"
  end
end
```

### 2. Add the model macro

```ruby
# app/models/user.rb
class User < ApplicationRecord
  better_authy_authenticable :user
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

### 5. Create the migration

```ruby
# db/migrate/XXXXXX_create_users.rb
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
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip

      t.index :email, unique: true
    end
  end
end
```

Run the migration:

```bash
rails db:migrate
```

## Verify Installation

Start your Rails server and visit:

- Login: `http://localhost:3000/auth/user/login`
- Signup: `http://localhost:3000/auth/user/signup`

## Adding to Existing Model

If you have an existing users table, create a migration to add the required columns:

```ruby
class AddBetterAuthyToUsers < ActiveRecord::Migration[8.0]
  def change
    # Skip if columns already exist
    unless column_exists?(:users, :password_digest)
      add_column :users, :password_digest, :string, null: false
    end

    add_column :users, :remember_token_digest, :string
    add_column :users, :remember_created_at, :datetime
    add_column :users, :password_reset_token_digest, :string
    add_column :users, :password_reset_sent_at, :datetime
    add_column :users, :sign_in_count, :integer, default: 0
    add_column :users, :current_sign_in_at, :datetime
    add_column :users, :last_sign_in_at, :datetime
    add_column :users, :current_sign_in_ip, :string
    add_column :users, :last_sign_in_ip, :string

    add_index :users, :email, unique: true unless index_exists?(:users, :email)
  end
end
```
