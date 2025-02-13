# frozen_string_literal: true

class AddUniqueIndexToBandNames < ActiveRecord::Migration[7.0]
  def change
    add_index :bands, %i[name competition_id], unique: true
  end
end
