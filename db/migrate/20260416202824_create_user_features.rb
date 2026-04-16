# frozen_string_literal: true

class CreateUserFeatures < ActiveRecord::Migration[7.2]
  def change
    create_table :user_features, id: :uuid do |t|
      t.references :user, foreign_key: true, type: :uuid, null: false
      t.references :feature, foreign_key: true, type: :uuid, null: false

      t.timestamps
    end
  end
end
