# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users, id: :uuid do |t|
      ## Database authenticatable
      t.string :email,              null: false, limit: 100
      t.string :encrypted_password, null: false, limit: 100

      ## Recoverable
      t.string   :reset_password_token, limit: 100
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip, limit: 100
      t.string   :last_sign_in_ip, limit: 100

      ## Confirmable
      t.string   :confirmation_token, limit: 100
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email, limit: 100 # Only if using reconfirmable

      ## Lockable
      t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      t.string   :unlock_token, limit: 100 # Only if unlock strategy is :email or :both
      t.datetime :locked_at

      t.timestamps null: false

      # normal fields
      t.string :name, null: false, limit: 100
      t.boolean :user_manager, default: false, null: false
      t.boolean :competition_manager, default: false, null: false
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token,   unique: true
    add_index :users, :unlock_token,         unique: true
  end
end
