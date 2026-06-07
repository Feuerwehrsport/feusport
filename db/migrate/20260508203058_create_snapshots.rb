# frozen_string_literal: true

class CreateSnapshots < ActiveRecord::Migration[7.2]
  def change
    create_table :snapshots, id: :uuid do |t|
      t.references :competition, foreign_key: true, type: :uuid, null: false
      t.string :title, null: false
      t.boolean :highlight, null: false, default: false

      t.timestamps
    end
  end
end
