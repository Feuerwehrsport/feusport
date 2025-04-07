# frozen_string_literal: true

class CreateInformationRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :information_requests, id: :uuid do |t|
      t.references :competition, foreign_key: true, type: :uuid, null: false
      t.references :user, foreign_key: true, type: :uuid, null: false
      t.text :message, null: false

      t.timestamps
    end
  end
end
