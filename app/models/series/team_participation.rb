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
class Series::TeamParticipation < Series::Participation
  belongs_to :team, class_name: 'FireSportStatistics::Team', inverse_of: :series_participations

  validates :team, :team_number, presence: true

  def entity_id
    "#{team_id}-#{team_number}"
  end
end
