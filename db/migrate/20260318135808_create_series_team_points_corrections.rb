# frozen_string_literal: true

class CreateSeriesTeamPointsCorrections < ActiveRecord::Migration[7.2]
  def change
    create_table :series_team_points_corrections, id: :uuid do |t|
      t.references :competition, foreign_key: true, type: :uuid, null: false
      t.string :round_key, null: false
      t.string :discipline, null: false
      t.bigint :team_id, null: false
      t.integer :team_number, null: false, default: 1
      t.integer :points_correction, null: false
      t.string :points_correction_hint, null: false

      t.timestamps
    end
  end
end
