# frozen_string_literal: true

class RemoveBandsFromScoreListFactories < ActiveRecord::Migration[7.2]
  def change
    drop_table :score_list_factory_bands
  end
end
