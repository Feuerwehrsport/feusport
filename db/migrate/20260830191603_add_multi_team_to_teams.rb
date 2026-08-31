# frozen_string_literal: true

class AddMultiTeamToTeams < ActiveRecord::Migration[7.2]
  def change
    add_column :teams, :multi_team, :boolean, default: false, null: false
  end
end
