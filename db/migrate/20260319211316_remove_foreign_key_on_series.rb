# frozen_string_literal: true

class RemoveForeignKeyOnSeries < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key 'series_round_competition_associations', 'series_rounds', column: 'round_id'
  end
end
