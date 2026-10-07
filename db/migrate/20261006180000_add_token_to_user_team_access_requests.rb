# frozen_string_literal: true

class AddTokenToUserTeamAccessRequests < ActiveRecord::Migration[8.0]
  def up
    add_column :user_team_access_requests, :token, :string
    execute "UPDATE user_team_access_requests SET token = encode(gen_random_bytes(24), 'hex')"
    change_column_null :user_team_access_requests, :token, false
    add_index :user_team_access_requests, :token, unique: true
  end

  def down
    remove_column :user_team_access_requests, :token
  end
end
