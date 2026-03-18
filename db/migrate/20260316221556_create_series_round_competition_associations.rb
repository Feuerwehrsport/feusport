# frozen_string_literal: true

class CreateSeriesRoundCompetitionAssociations < ActiveRecord::Migration[7.2]
  def change
    create_table :series_round_competition_associations, id: :uuid do |t|
      t.references :round, foreign_key: { to_table: :series_rounds }, null: false
      t.references :competition, foreign_key: true, type: :uuid, null: false

      t.timestamps
    end
  end
end
