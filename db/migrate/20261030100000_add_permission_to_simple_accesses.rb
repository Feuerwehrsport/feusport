# frozen_string_literal: true

# permission: Was ein Gastzugang darf (alles, nur Zeiten oder nur Zeiten in ausgewählten Startlisten).
# score_list_ids: Freigegebene Startlisten bei selected_results. Eine leere Liste gibt keine Startliste frei.
class AddPermissionToSimpleAccesses < ActiveRecord::Migration[8.1]
  def change
    add_column :simple_accesses, :permission, :integer, default: 0, null: false
    add_column :simple_accesses, :score_list_ids, :uuid, array: true, default: [], null: false
  end
end
