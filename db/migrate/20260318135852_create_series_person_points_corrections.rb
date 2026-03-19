# frozen_string_literal: true

class CreateSeriesPersonPointsCorrections < ActiveRecord::Migration[7.2]
  def change
    create_table :series_person_points_corrections, id: :uuid do |t|
      t.references :competition, foreign_key: true, type: :uuid
      t.string :round_key
      t.bigint :person_id
      t.integer :points_correction
      t.string :points_correction_hint

      t.timestamps
    end
  end
end
