# frozen_string_literal: true

# Nicht öffentliche Wettkämpfe werden ein Jahr nach dem Wettkampfdatum gelöscht.
# Die Verantwortlichen werden zwei Wochen vorher informiert. Gelöscht wird nie, bevor
# diese Frist nach der Benachrichtigung abgelaufen ist.
class Competitions::AutoDeletion
  KEEP_FOR = 1.year
  NOTICE_PERIOD = 2.weeks

  def self.to_notify
    Competition.where(visible: false, deletion_notified_at: nil)
               .where(date: ..(Date.current - KEEP_FOR + NOTICE_PERIOD))
  end

  def self.deletable
    Competition.where(visible: false)
               .where(deletion_notified_at: ..(Date.current - NOTICE_PERIOD).end_of_day)
               .where(date: ..(Date.current - KEEP_FOR))
  end

  def self.deletion_date(competition)
    [competition.date + KEEP_FOR, competition.deletion_notified_at.to_date + NOTICE_PERIOD].max
  end

  class Job < ApplicationJob
    def perform
      Competitions::AutoDeletion.deletable.find_each do |competition|
        Competitions::Deletion.new(competition:, confirm: true).save
      end

      Competitions::AutoDeletion.to_notify.find_each do |competition|
        competition.update_column(:deletion_notified_at, Time.current)
        CompetitionMailer.with(competition:).deletion_notice.deliver_later
      end
    end
  end
end
