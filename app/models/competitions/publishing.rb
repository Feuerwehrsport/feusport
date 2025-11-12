# frozen_string_literal: true

class Competitions::Publishing
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :competition, :user, :hint

  attribute :confirm, :boolean, default: false
  validates :confirm, acceptance: true
  validates :competition, :user, presence: true

  def save
    return false unless valid?

    Competition.transaction do
      competition.update!(locked_at: Time.current)
      FireSportStatistics::Publishing.create!(competition:, user:, hint:)
    end
  end

  class ReminderJob < ApplicationJob
    discard_on ActiveJob::DeserializationError

    def perform
      competitions.find_each do |competition|
        CompetitionMailer.with(competition:).publishing_reminder.deliver_later
      end
    end

    def competitions
      Competition.where(locked_at: nil, visible: true).where(Competition.arel_table[:date].lt(Date.current))
    end
  end
end
