# frozen_string_literal: true

class AddProcessedToSnapshots < ActiveRecord::Migration[7.2]
  def change
    add_column :snapshots, :processed, :boolean, default: false, null: false
    add_index :snapshots, :highlight
    add_index :snapshots, :processed
  end
end
