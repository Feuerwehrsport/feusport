# frozen_string_literal: true

class Team < ApplicationRecord
  include Taggable

  belongs_to :competition
  belongs_to :band
  belongs_to :fire_sport_statistics_team, class_name: 'FireSportStatistics::Team'
  has_many :people, dependent: :nullify
  has_many :requests, class_name: 'AssessmentRequest', as: :entity, dependent: :destroy, inverse_of: :entity
  has_many :list_entries, class_name: 'Score::ListEntry', as: :entity, dependent: :destroy, inverse_of: :entity
  has_many :requested_assessments, through: :requests, source: :assessment
  has_many :team_relays, dependent: :destroy

  schema_validations
  validates :number, numericality: { greater_than: 0 }
  validates :shortcut, length: { maximum: 12 }

  auto_strip_attributes :name, :shortcut, squish: true, convert_non_breaking_spaces: true
  accepts_nested_attributes_for :requests, allow_destroy: true

  default_scope { order(:name, :number) }

  after_create :create_assessment_requests
  attr_accessor :disable_autocreate_assessment_requests

  def group_assessment_validator
    @group_assessment_validator ||= GroupAssessmentValidator.new(self)
  end

  def full_name
    multi_team? ? "#{name} #{number}" : name
  end

  def full_name_with_band
    "#{full_name} #{band.name}"
  end

  def shortcut_name
    multi_team? ? "#{shortcut} #{number}" : shortcut
  end

  def request_for(assessment)
    requests.find_by(assessment:)
  end

  def list_entries_group_competitor(assessment)
    @list_entries_group_competitor = {} if @list_entries_group_competitor.nil?
    @list_entries_group_competitor[assessment.id] ||= people.includes(:list_entries).count do |person|
      person.list_entries.select { |l| l.assessment_id == assessment.id }.find(&:group_competitor?).present?
    end
  end

  def people_assessments
    @people_assessments ||= Assessment.where(id: Score::ListEntry.where(entity: people).distinct.select(:assessment_id))
  end

  def fire_sport_statistics_team_with_dummy
    fire_sport_statistics_team.presence || FireSportStatistics::Team.dummy(self)
  end

  def assessment_request_group_competitor_valid?
    @assessment_request_group_competitor_valid ||= Assessment.no_double_event.all.all? do |assessment|
      people.count do |person|
        person.requests.assessment_type(:group_competitor).exists?(assessment:)
      end <= Competition.one.group_run_count
    end
  end

  def <=>(other)
    sort_by_name = full_name <=> other.full_name
    return sort_by_name unless sort_by_name == 0

    super
  end

  private

  def create_assessment_requests
    return if disable_autocreate_assessment_requests.present?

    Assessment.requestable_for_team(band).each do |assessment|
      count = assessment.like_fire_relay? ? 2 : 1
      requests.create!(assessment:, relay_count: count)
    end
  end

  def multi_team?
    Team.where(band:).where(name:).where.not(id:).exists?
  end

  class GroupAssessmentValidator
    def initialize(team)
      @team = team
      @bad_results = []

      return unless @team.people.exists?

      Score::Result.where(group_assessment: true, assessment: @team.band.assessments.single_disciplines)
                   .find_each do |result|
        requests = AssessmentRequest.where(entity: team.people, assessment_type: 'group_competitor',
                                           assessment: result.assessment).count
        @bad_results.push([result, requests, result.group_run_count]) if requests > result.group_run_count
      end
    end

    def valid?
      @bad_results.empty?
    end

    def messages
      @bad_results.map { |result, requests, run_count| "#{result.name}: #{requests} von #{run_count}" }.join(', ')
    end
  end
end
