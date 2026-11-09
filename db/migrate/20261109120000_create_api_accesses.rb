# frozen_string_literal: true

class CreateApiAccesses < ActiveRecord::Migration[8.1]
  def change
    create_table :api_accesses, id: :uuid do |t|
      t.references :competition, type: :uuid, null: false, foreign_key: true
      t.string :name, limit: 50, null: false
      t.string :device_name, limit: 100
      t.integer :permission, null: false, default: 1
      t.uuid :score_list_ids, array: true, null: false, default: []
      t.string :pairing_code, limit: 8
      t.datetime :pairing_code_expires_at
      t.string :token_digest, limit: 64
      t.datetime :paired_at
      t.datetime :last_used_at

      t.timestamps
    end

    add_index :api_accesses, %i[competition_id name], unique: true
    add_index :api_accesses, :pairing_code, unique: true
    add_index :api_accesses, :token_digest, unique: true
  end
end
