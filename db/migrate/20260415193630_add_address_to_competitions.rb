# frozen_string_literal: true

class AddAddressToCompetitions < ActiveRecord::Migration[7.2]
  def change
    enable_extension 'postgis'

    change_table :competitions, bulk: true do |t|
      t.text :address
      t.st_point :lnglat, geographic: true
      t.index :lnglat, using: :gist
    end
  end
end
