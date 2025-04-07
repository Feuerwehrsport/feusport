# frozen_string_literal: true

class AddRegistrationMailInfoToUserAccesses < ActiveRecord::Migration[7.2]
  def change
    add_column :user_accesses, :registration_mail_info, :boolean, default: true, null: false
  end
end
