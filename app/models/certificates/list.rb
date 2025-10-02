# frozen_string_literal: true

class Certificates::List
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :competition, :template_id, :score_result_id, :competition_result_id, :group_score_result_id,
                :series_team_round_id, :series_person_assessment_id

  attribute :background_image, :boolean, default: true

  validates :competition, :template, presence: true
  validate :result_present

  def template
    @template ||= competition&.certificates_templates&.find_by(id: template_id)
  end

  def score_result
    @score_result ||= competition&.score_results&.find_by(id: score_result_id)
  end

  def group_score_result
    @group_score_result ||= begin
      result = competition&.score_results&.find_by(id: group_score_result_id)
      Score::GroupResult.new(result) if result
    end
  end

  def competition_result
    @competition_result ||= competition&.score_competition_results&.find_by(id: competition_result_id)
  end

  def series_team_round
    @series_team_round ||= Series::Round::GenderWrapper.find(series_team_round_id)
  end

  def series_person_assessment
    return @series_person_assessment if defined?(@series_person_assessment)

    @series_person_assessment = Series::Assessment.find_by(id: series_person_assessment_id)
  end

  def result
    @result ||= score_result || competition_result || group_score_result ||
                series_team_round || series_person_assessment
  end

  def rows
    @rows ||= result&.rows(competition)
  end

  def save
    valid?
  end

  private

  def result_present
    return if [score_result, competition_result, group_score_result,
               series_team_round, series_person_assessment].one?(&:itself)

    errors.add(:score_result_id, :invalid)
    errors.add(:competition_result_id, :invalid)
    errors.add(:group_score_result_id, :invalid)
    errors.add(:series_team_round_id, :invalid)
    errors.add(:series_person_assessment_id, :invalid)
  end
end
