# frozen_string_literal: true

class CreateFeatures < ActiveRecord::Migration[7.2]
  def change
    create_table :features, id: :uuid do |t|
      t.string :name, null: false

      t.timestamps
    end

    # Feature.create!(name: 'Hakenleitersteigen')
    # Feature.create!(name: 'Hindernisbahn')
    # Feature.create!(name: 'Jugend')
    # Feature.create!(name: 'Löschangriff - Jugend')
    # Feature.create!(name: 'Löschangriff - TGL')
    # Feature.create!(name: 'Löschangriff - DIN')
    # Feature.create!(name: 'Sonstiges')
  end
end
