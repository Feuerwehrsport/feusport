# frozen_string_literal: true

# == Schema Information
#
# Table name: score_competition_results
#
#  id             :uuid             not null, primary key
#  hidden         :boolean          default(FALSE), not null
#  name           :string(100)      not null
#  result_type    :string(50)       not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  competition_id :uuid             not null
#
# Indexes
#
#  index_score_competition_results_on_competition_id           (competition_id)
#  index_score_competition_results_on_name_and_competition_id  (name,competition_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
class Score::CompetitionResult < ApplicationRecord
  AssessmentResult = Struct.new(:points, :result, :result_entry, :team, :row) do
    delegate :assessment, to: :result
    delegate :discipline, to: :assessment
  end

  include Score::Resultable
  include SortableByName

  belongs_to :competition, touch: true
  has_many :result_references, class_name: 'Score::CompetitionResultReference', dependent: :destroy
  has_many :results, through: :result_references, class_name: 'Score::Result'

  auto_strip_attributes :name

  schema_validations
  validates :results, same_competition: true

  def rows(*)
    @rows ||= result_type.present? ? send(result_type) : []
  end

  def self.result_types
    {
      dcup: 'D-Cup',
      places_to_points: 'Plätze zu Punkte',
    }
  end

  private

  def for_results
    results.each do |result|
      discipline = result.assessment.discipline
      result_rows = if discipline.single_discipline?
                      Score::GroupResult.new(result).rows
                    else
                      result.group_result_rows
                    end

      ranks = {}
      result_rows.each do |row|
        result_rows.each_with_index do |rank_row, rank|
          if (row <=> rank_row).zero?
            ranks[row] = (rank + 1)
            break
          end
        end
      end

      yield result, result_rows, ranks
    end
  end

  def dcup
    teams = {}
    for_results do |result, result_rows, ranks|
      points = 11
      result_rows.each do |row|
        rank = ranks[row]
        double_rank_count = ranks.values.count { |v| v == rank } - 1
        points = [(11 - ranks[row] - double_rank_count), 0].max
        points = 0 unless row.competition_result_valid?

        assessment_result = AssessmentResult.new(points, result, row.result_entry, row.entity, row)
        teams[row.entity.id] ||= Score::CompetitionResultRow.new(self, row.entity)
        teams[row.entity.id].add_assessment_result(assessment_result)
      end
    end
    teams.values.sort
  end

  def places_to_points
    teams = {}
    for_results do |result, result_rows, ranks|
      result_rows.each do |row|
        points = ranks[row]
        assessment_result = AssessmentResult.new(points, result, row.result_entry, row.entity, row)
        teams[row.entity.id] ||= Score::CompetitionResultRow.new(self, row.entity)
        teams[row.entity.id].add_assessment_result(assessment_result)
      end
    end
    for_results do |result, result_rows, _ranks|
      next if result_rows.empty?

      points = teams.count
      teams.each_key do |team_id|
        next if teams[team_id].assessment_result_from(result).present?

        assessment_result = AssessmentResult.new(points, result, Score::ResultEntry.invalid,
                                                 Team.find(team_id), nil)
        teams[team_id].add_assessment_result(assessment_result)
      end
    end
    teams.values.sort
  end
end
