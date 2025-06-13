# frozen_string_literal: true

class AddCalculationHelpToScoreResult < ActiveRecord::Migration[7.2]
  def change
    add_column :score_results, :calculation_help, :boolean, default: false, null: false
  end
end
