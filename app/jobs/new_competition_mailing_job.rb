# frozen_string_literal: true

# Informiert Benutzer per E-Mail über neu veröffentlichte, zukünftige Wettkämpfe (je Benutzer eine Sammel-E-Mail).
class NewCompetitionMailingJob < ApplicationJob
  # Erst nach dieser Zeit informieren, damit Veranstalter versehentliche Veröffentlichungen noch korrigieren können
  PUBLISHED_FOR = 1.day

  def perform
    pending = Competition.where(visible: true, new_competition_mailing_sent_at: nil,
                                published_at: ..PUBLISHED_FOR.ago)
    pending_ids = pending.ids
    return if pending_ids.empty?

    upcoming_ids = Competition.where(id: pending_ids, date: Date.tomorrow..).ids
    Competition.where(id: pending_ids).update_all(new_competition_mailing_sent_at: Time.current)
    return if upcoming_ids.empty?

    users.find_each do |user|
      competitions = competitions_for(user, upcoming_ids)
      next if competitions.empty?

      CompetitionMailer.with(user:, competitions:).new_competitions.deliver_later
    end
  end

  def users
    User.where(want_mailing: %i[all by_filter]).where.not(confirmed_at: nil)
  end

  def competitions_for(user, competition_ids)
    competitions = Competition.where(id: competition_ids).where.not(id: user.competition_ids)
    competitions = Competitions::Filter.for_user(user).apply(competitions) if user.by_filter_want_mailing?
    competitions.reorder(:date, :name).to_a
  end
end
