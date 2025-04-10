# frozen_string_literal: true

class CreateScoreResultReferences < ActiveRecord::Migration[7.2]
  def change
    create_table :score_result_references, id: :uuid do |t|
      t.references :result, foreign_key: { to_table: :score_results }, type: :uuid, null: false
      t.references :multi_result, foreign_key: { to_table: :score_results }, type: :uuid, null: false

      t.timestamps
    end

    add_column :score_results, :image_key, :string, limit: 10
    change_column_null :score_results, :assessment_id, true

    # Score::Result.where(calculation_method: 2).where(forced_name: ['', nil]).find_each do |result|
    #   Score::Result.where(id: result.id).update_all(forced_name: result.generated_name)
    # end

    add_column :score_results, :multi_result_method, :integer, null: false, default: 0
    Score::Result.where(calculation_method: 2).update_all(multi_result_method: 1, calculation_method: 0, image_key: :zk, assessment_id: nil)

    Score::Result.where.not(double_event_result_id: nil).pluck(:id, :double_event_result_id).each do |id, zk_id|
      Score::ResultReference.create!(result_id: id, multi_result_id: zk_id)
    end

    remove_column :score_results, :double_event_result_id
  end
end
