# frozen_string_literal: true

class Series::Team
  include Series::EntitySupport

  attr_accessor :team, :team_number, :team_gender

  delegate :id, to: :team, prefix: true

  def full_name
    if multi_team?
      "#{team&.name} #{team_number}"
    else
      team&.name.to_s
    end
  end

  def multi_team?
    round.team_participations.where(team_id:).where.not(team_number:).exists?
  end

  def participations_for_cup(cup)
    @cups ||= {}
    (@cups[cup.id] || []).sort_by(&:team_assessment)
  end

  def points
    @points ||= begin
      sum = ordered_participations.sum(&:points_with_correction)
      if config.penalty_points.nil?
        sum
      else
        fail_points = (config.round.cups.count - count) * config.penalty_points
        sum + fail_points
      end
    end
  end

  def best_time
    @best_time ||= begin
      scores = @cups.values.flatten
      scores.select! { |p| p.team_assessment.discipline == 'la' } if config.disciplines.include?('la')
      scores.map(&:time).min
    end
  end

  def storage_support_get(position)
    case position.key
    when :team_name
      full_name
    when :person_name, :person_bib_number, :assessment_with_gender, :gender, :date, :place, :competition_name
      ''
    when :assessment
      round.name
    else
      super
    end
  end
end
