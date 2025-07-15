# frozen_string_literal: true

Score::CompetitionResultRow = Struct.new(:result, :team) do
  include Score::ResultRowSupport
  delegate :competition, to: :result
  attr_reader :assessment_results

  def add_assessment_result(assessment_result)
    @assessment_results ||= []
    @assessment_results.push(assessment_result)
  end

  def points
    @assessment_results.sum(&:points)
  end

  def assessment_result_from(result)
    @assessment_results.find { |aresult| aresult.result == result }
  end

  def fire_attack_result_entry
    @assessment_results.find do |result|
      result.discipline.key == 'la'
    end.try(:result_entry) || Score::ResultEntry.new(result_valid: false)
  end

  def <=>(other)
    result.result_type.nil? ? 0 : send(:"#{result.result_type}_compare", other)
  end

  def entity
    team
  end

  def valid?
    true
  end

  private

  def dcup_compare(other)
    compare = other.points <=> points
    return fire_attack_result_entry <=> other.fire_attack_result_entry if compare.zero?

    compare
  end

  def places_to_points_compare(other)
    compare = points <=> other.points
    return fire_attack_result_entry <=> other.fire_attack_result_entry if compare.zero?

    compare
  end
end
