# frozen_string_literal: true

class CreateCompetitionFeatures < ActiveRecord::Migration[7.2]
  def change
    create_table :competition_features, id: :uuid do |t|
      t.references :competition, foreign_key: true, type: :uuid, null: false
      t.references :feature, foreign_key: true, type: :uuid, null: false

      t.timestamps
    end
  end
end
