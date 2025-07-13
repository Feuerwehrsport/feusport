# frozen_string_literal: true

class AddStartingOrderToScoreLists < ActiveRecord::Migration[7.2]
  def change
    add_column :score_lists, :starting_time, :datetime
  end
end
