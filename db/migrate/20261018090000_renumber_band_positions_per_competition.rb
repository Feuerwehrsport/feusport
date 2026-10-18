# frozen_string_literal: true

# Band#position war über alle Wettkämpfe durchnummeriert (acts_as_list ohne scope).
# Jetzt gilt sie je Wettkampf, die bisherige Reihenfolge innerhalb eines Wettkampfs bleibt erhalten.
class RenumberBandPositionsPerCompetition < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE bands SET position = numbered.new_position
      FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY competition_id ORDER BY position NULLS LAST, created_at, id) AS new_position
        FROM bands
      ) AS numbered
      WHERE bands.id = numbered.id
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
