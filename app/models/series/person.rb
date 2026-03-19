# frozen_string_literal: true

class Series::Person
  include Series::EntitySupport

  attr_accessor :person

  delegate :id, to: :person, prefix: true
  delegate :first_name, :last_name, to: :person

  def participation_for_cup(cup)
    @cups ||= {}
    (@cups[cup.id] || []).first
  end

  def points
    @points ||= ordered_participations.sum(&:points_with_correction)
  end

  def best_time
    @best_time ||= @cups.values.flatten.map(&:time).min
  end

  def storage_support_get(position)
    case position.key
    when :person_name
      person&.full_name
    when :team_name, :person_bib_number, :assessment_with_gender, :gender, :date, :place, :competition_name
      ''
    when :assessment
      participations.first&.assessment&.name
    else
      super
    end
  end
end
