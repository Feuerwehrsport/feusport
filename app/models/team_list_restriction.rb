# frozen_string_literal: true

# == Schema Information
#
# Table name: team_list_restrictions
#
#  id             :uuid             not null, primary key
#  restriction    :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  competition_id :uuid             not null
#  discipline_id  :uuid             not null
#  team1_id       :uuid             not null
#  team2_id       :uuid             not null
#
# Indexes
#
#  index_team_list_restrictions_on_competition_id  (competition_id)
#  index_team_list_restrictions_on_discipline_id   (discipline_id)
#  index_team_list_restrictions_on_team1_id        (team1_id)
#  index_team_list_restrictions_on_team2_id        (team2_id)
#  index_team_list_restrictions_unique             (team1_id,team2_id,discipline_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#  fk_rails_...  (discipline_id => disciplines.id)
#  fk_rails_...  (team1_id => teams.id)
#  fk_rails_...  (team2_id => teams.id)
#
class TeamListRestriction < ApplicationRecord
  RESTRICTIONS = { not_same_run: 0, same_run: 1, before: 2, after: 3, distance1: 4, distance2: 5 }.freeze
  enum :restriction, RESTRICTIONS, scopes: false, default: :not_same_run, prefix: true

  belongs_to :competition
  belongs_to :team1, class_name: 'Team'
  belongs_to :team2, class_name: 'Team'
  belongs_to :discipline

  scope :team, ->(team_id) { where(arel_table[:team1_id].eq(team_id).or(arel_table[:team2_id].eq(team_id))) }

  schema_validations
  validates :team1, :team2, :discipline, same_competition: true
  validates :team1, comparison: { other_than: :team2, allow_nil: true, message: ->(object, _data) {
    "darf nicht gleich #{object.team2.full_name_with_band} sein"
  } }

  def short_restriction_name
    I18n.t("team_list_restriction.restrictions_short.#{restriction}")
  end

  def restriction_name
    I18n.t("team_list_restriction.restrictions.#{restriction}")
  end

  def <=>(other)
    sort_by_name = team1.full_name <=> other.team1.full_name
    return sort_by_name unless sort_by_name == 0

    sort_by_name = team2.full_name <=> other.team2.full_name
    return sort_by_name unless sort_by_name == 0

    sort_by_restriction = restriction <=> other.restriction
    return sort_by_restriction unless sort_by_restriction == 0

    to_key <=> other.to_key
  end

  def list_entries_valid?(entries, softer_mode)
    team1_runs = entries.select { |e| e[0] == team1_id }.map(&:second)
    return true if team1_runs.empty?

    team2_runs = entries.select { |e| e[0] == team2_id }.map(&:second)
    return true if team2_runs.empty?

    case softer_mode
    when 0
      softer_mode_0_valid?(team1_runs, team2_runs)
    when 1
      softer_mode_1_valid?(team1_runs, team2_runs)
    when 2
      softer_mode_2_valid?(team1_runs, team2_runs)
    when 3
      softer_mode_3_valid?(team1_runs, team2_runs)
    when 4
      softer_mode_4_valid?(team1_runs, team2_runs)
    else
      true
    end
  end

  def softer_mode_0_valid?(team1_runs, team2_runs)
    return team1_runs == team2_runs if restriction_same_run?

    team1_runs.each do |team1_run|
      team2_runs.each do |team2_run|
        return false if restriction_not_same_run? && team1_run == team2_run
        return false if restriction_before? && team1_run >= team2_run
        return false if restriction_after? && team1_run <= team2_run
        return false if restriction_distance1? && !(team1_run + 1 < team2_run || team1_run - 1 > team2_run)
        return false if restriction_distance2? && !(team1_run + 2 < team2_run || team1_run - 2 > team2_run)
      end
    end
    true
  end

  def softer_mode_1_valid?(team1_runs, team2_runs)
    return team1_runs == team2_runs if restriction_same_run?

    team1_runs.each do |team1_run|
      team2_runs.each do |team2_run|
        return false if restriction_not_same_run? && team1_run == team2_run
        return false if restriction_before? && team1_run >= team2_run
        return false if restriction_after? && team1_run <= team2_run
        return false if restriction_distance1? && !(team1_run + 1 < team2_run || team1_run - 1 > team2_run)
        return false if restriction_distance2? && !(team1_run + 1 < team2_run || team1_run - 1 > team2_run)
      end
    end
    true
  end

  def softer_mode_2_valid?(team1_runs, team2_runs)
    return team1_runs == team2_runs if restriction_same_run?

    team1_runs.each do |team1_run|
      team2_runs.each do |team2_run|
        return false if restriction_not_same_run? && team1_run == team2_run
        return false if restriction_before? && team1_run >= team2_run
        return false if restriction_after? && team1_run <= team2_run
      end
    end
    true
  end

  def softer_mode_3_valid?(team1_runs, team2_runs)
    team1_runs.each do |team1_run|
      team2_runs.each do |team2_run|
        return false if restriction_not_same_run? && team1_run == team2_run
        return false if restriction_before? && team1_run >= team2_run
        return false if restriction_after? && team1_run <= team2_run
      end
    end
    true
  end

  def softer_mode_4_valid?(team1_runs, team2_runs)
    team1_runs.each do |team1_run|
      team2_runs.each do |team2_run|
        return false if restriction_not_same_run? && team1_run == team2_run
      end
    end
    true
  end

  class Check
    attr_reader :restrictions, :errors
    attr_accessor :softer_mode

    def initialize(object)
      @errors = []
      @softer_mode = 0
      @restrictions = object.competition.team_list_restrictions.where(discipline: object.discipline).to_a
    end

    def valid_from_list?(entries)
      valid?(entries.map { |entry| [entry.entity_id, entry.run] })
    end

    def valid_from_factory?(rows)
      valid?(rows.map { |row, run, _track| [row.entity_id, run] })
    end

    def valid?(list_entries)
      @errors = []
      restrictions.each do |r|
        @errors.push(r) unless r.list_entries_valid?(list_entries, softer_mode)
      end
      @errors.empty?
    end
  end
end
