# frozen_string_literal: true

class AddSnapshotReminderSentToCompetitions < ActiveRecord::Migration[7.2]
  def change
    add_column :competitions, :snapshot_reminder_sent, :datetime
  end
end
