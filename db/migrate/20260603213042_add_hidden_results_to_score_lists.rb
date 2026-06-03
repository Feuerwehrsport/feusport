# frozen_string_literal: true

class AddHiddenResultsToScoreLists < ActiveRecord::Migration[7.2]
  def change
    add_column :score_lists, :hidden_results, :boolean, default: false, null: false
  end
end
