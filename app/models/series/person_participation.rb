# frozen_string_literal: true

# == Schema Information
#
# Table name: series_participations
#
#  id            :bigint           not null, primary key
#  points        :integer          default(0), not null
#  rank          :integer          not null
#  team_number   :integer
#  time          :integer          not null
#  type          :string(100)      not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  assessment_id :integer          not null
#  cup_id        :integer          not null
#  person_id     :integer
#  team_id       :integer
#
class Series::PersonParticipation < Series::Participation
  belongs_to :person, class_name: 'FireSportStatistics::Person', inverse_of: :series_participations

  validates :person, presence: true

  def entity
    person
  end

  def entity_id
    person_id
  end
end
