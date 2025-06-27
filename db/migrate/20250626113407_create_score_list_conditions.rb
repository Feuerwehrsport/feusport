# frozen_string_literal: true

class CreateScoreListConditions < ActiveRecord::Migration[7.2]
  def change
    create_table :score_list_conditions, id: :uuid do |t|
      t.references :competition, foreign_key: { to_table: :competitions }, type: :uuid, null: false
      t.references :list, foreign_key: { to_table: :score_lists }, type: :uuid
      t.references :factory, foreign_key: { to_table: :score_list_factories }, type: :uuid
      t.integer :track, null: false

      t.timestamps
    end
  end
end
