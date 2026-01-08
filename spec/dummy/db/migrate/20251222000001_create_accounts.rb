# frozen_string_literal: true

class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
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
      t.integer :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip
    end

    add_index :accounts, :email, unique: true
  end
end
