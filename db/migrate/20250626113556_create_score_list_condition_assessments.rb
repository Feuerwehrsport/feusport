# frozen_string_literal: true

class CreateScoreListConditionAssessments < ActiveRecord::Migration[7.2]
  def change
    create_table :score_list_condition_assessments, id: :uuid do |t|
      t.references :condition, foreign_key: { to_table: :score_list_conditions }, type: :uuid, null: false
      t.references :assessment, foreign_key: { to_table: :assessments }, type: :uuid, null: false

      t.timestamps
    end
  end
end
