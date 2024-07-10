# frozen_string_literal: true

class Person < ApplicationRecord
  include Taggable

  belongs_to :competition, touch: true
  belongs_to :band
  belongs_to :team
  belongs_to :fire_sport_statistics_person, class_name: 'FireSportStatistics::Person', inverse_of: :person
  has_many :requests, class_name: 'AssessmentRequest', as: :entity, dependent: :destroy, inverse_of: :entity
  has_many :list_entries, class_name: 'Score::ListEntry', as: :entity, dependent: :destroy, inverse_of: :entity
  has_many :requested_assessments, through: :requests, source: :assessment

  before_validation :strip_names
  before_validation :create_team_from_name
  before_save :assign_registration_order

  schema_validations
  validate :validate_team_band

  accepts_nested_attributes_for :requests, allow_destroy: true

  default_scope { order(:last_name, :first_name) }
  scope :registration_order, -> { reorder(:registration_order) }

  attr_accessor :create_team_name

  def full_name
    "#{first_name} #{last_name}"
  end

  def full_name_with_band
    "#{full_name} (#{band.name})"
  end

  def request_for(assessment)
    requests.find_by(assessment:)
  end

  def fire_sport_statistics_person_with_dummy
    fire_sport_statistics_person.presence || FireSportStatistics::Person.dummy(self)
  end

  def team_assessment_type_name(name, assessment_type)
    name.push('E') if assessment_type == 'single_competitor'
    name.push('A') if assessment_type == 'out_of_competition'
    name.join(' ')
  end

  def team_shortcut_name(assessment_type = nil)
    team_assessment_type_name([team&.shortcut_name], assessment_type)
  end

  def team_name(assessment_type = nil)
    team_assessment_type_name([team&.full_name], assessment_type)
  end

  def <=>(other)
    sort_by_name = full_name <=> other.full_name
    return sort_by_name unless sort_by_name == 0

    super
  end

  private

  def strip_names
    self.last_name = last_name.try(:strip)
    self.first_name = first_name.try(:strip)
  end

  def validate_team_band
    return if team.blank? || team.band == band

    errors.add(:team, :has_other_band)
    errors.add(:band, :has_other_band)
  end

  def assign_registration_order
    return unless registration_order.zero? && team.present?

    self.registration_order = (team.people.maximum(:registration_order) || 0) + 1
  end

  def create_team_from_name
    return if create_team_name.blank? || team&.persisted?

    self.team = Team.find_by(band:, name: create_team_name)
    return if team&.persisted?

    build_team(competition:, disable_autocreate_assessment_requests: true,
               name: create_team_name, shortcut: create_team_name.first(12), band:)
  end
end
