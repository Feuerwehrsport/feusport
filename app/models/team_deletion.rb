# frozen_string_literal: true

class TeamDeletion
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :competition, :team

  attribute :confirm, :boolean, default: false
  validates :confirm, acceptance: true, if: :scores_present?

  attribute :delete_people, :boolean, default: false

  validate do
    if delete_people && @team.people.any? { |person| person.list_entries.not_waiting.exists? }
      errors.add(:delete_people, :scores_present)
    end
  end

  def save
    return false unless valid?

    Team.transaction do
      if delete_people
        @team.people.destroy_all
      elsif people_present? && @team.users.exists?
        @team.people.each do |person|
          @team.users.each do |user|
            person.user_person_accesses.build(user:, competition:)
          end
          person.save
        end
      end

      @team.destroy
    end
  end

  def people_present?
    @team.people.present?
  end

  def scores_present?
    @team.list_entries.present?
  end
end
