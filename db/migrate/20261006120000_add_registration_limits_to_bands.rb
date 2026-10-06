# frozen_string_literal: true

class AddRegistrationLimitsToBands < ActiveRecord::Migration[8.0]
  def change
    add_column :bands, :max_teams, :integer
    add_column :bands, :max_people, :integer
  end
end
