# frozen_string_literal: true

class CreateUserTeamAccessRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :user_team_access_requests, id: :uuid do |t|
      t.references :competition, foreign_key: true, type: :uuid, null: false
      t.references :team, foreign_key: true, type: :uuid, null: false
      t.references :sender, foreign_key: { to_table: :users }, type: :uuid, null: false
      t.string :email, null: false, limit: 200
      t.text :text, null: false

      t.timestamps
    end

    add_index :user_team_access_requests, %i[team_id competition_id email], unique: true
  end
end
