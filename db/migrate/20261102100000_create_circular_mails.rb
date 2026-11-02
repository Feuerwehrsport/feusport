# frozen_string_literal: true

class CreateCircularMails < ActiveRecord::Migration[8.1]
  def change
    create_table :circular_mails, id: :uuid do |t|
      t.references :competition, foreign_key: true, type: :uuid, null: false
      t.references :user, foreign_key: true, type: :uuid, null: false
      t.string :subject, limit: 200, null: false
      t.text :message, null: false
      t.integer :recipients_count, null: false, default: 0

      t.timestamps
    end
  end
end
