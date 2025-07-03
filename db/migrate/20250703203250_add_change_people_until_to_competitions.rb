# frozen_string_literal: true

class AddChangePeopleUntilToCompetitions < ActiveRecord::Migration[7.2]
  def change
    add_column :competitions, :change_people_until, :date
  end
end
