# frozen_string_literal: true

class AddLngLatToUsers < ActiveRecord::Migration[7.2]
  def change
    change_table :users, bulk: true do |t|
      t.st_point :lnglat, geographic: true
      t.index :lnglat, using: :gist

      t.integer :distance
      t.integer :want_mailing, default: 0, null: false
    end
  end
end
