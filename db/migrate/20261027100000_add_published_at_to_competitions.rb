# frozen_string_literal: true

# published_at: Zeitpunkt, an dem ein Wettkampf erstmals sichtbar geschaltet wurde.
# new_competition_mailing_sent_at: Wann über den Wettkampf per E-Mail informiert wurde.
# Bestehende sichtbare Wettkämpfe gelten als veröffentlicht und bereits verschickt.
class AddPublishedAtToCompetitions < ActiveRecord::Migration[8.1]
  def change
    add_column :competitions, :published_at, :datetime
    add_column :competitions, :new_competition_mailing_sent_at, :datetime
    add_index :competitions, :published_at

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE competitions
          SET published_at = created_at, new_competition_mailing_sent_at = CURRENT_TIMESTAMP
          WHERE visible = TRUE
        SQL
      end
    end
  end
end
