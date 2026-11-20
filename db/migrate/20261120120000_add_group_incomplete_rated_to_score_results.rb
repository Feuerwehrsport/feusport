# frozen_string_literal: true

class AddGroupIncompleteRatedToScoreResults < ActiveRecord::Migration[8.1]
  def change
    add_column :score_results, :group_incomplete_rated, :boolean, default: false, null: false
  end
end
