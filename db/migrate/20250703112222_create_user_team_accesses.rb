# frozen_string_literal: true

class CreateUserTeamAccesses < ActiveRecord::Migration[7.2]
  def change
    create_table :user_team_accesses, id: :uuid do |t|
      t.references :competition, foreign_key: true, type: :uuid, null: false
      t.references :user, foreign_key: true, type: :uuid, null: false
      t.references :team, foreign_key: true, type: :uuid, null: false

      t.timestamps
    end

    add_index :user_team_accesses, %i[user_id team_id competition_id], unique: true

    Team.where.not(applicant_id: nil).find_each do |team|
      UserTeamAccess.create!(team:, user_id: team.applicant_id, competition_id: team.competition_id)
    end

    remove_column :teams, :applicant_id
  end
end
