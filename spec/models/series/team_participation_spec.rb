# frozen_string_literal: true

# == Schema Information
#
# Table name: series_team_participations
#
#  id                     :integer          not null, primary key
#  points                 :integer          default(0), not null
#  points_correction      :integer
#  points_correction_hint :string(200)
#  rank                   :integer          not null
#  team_gender            :integer          not null
#  team_number            :integer          not null
#  time                   :integer          not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  cup_id                 :integer          not null
#  team_assessment_id     :integer          not null
#  team_id                :integer          not null
#
# Indexes
#
#  index_series_team_participations_on_cup_id              (cup_id)
#  index_series_team_participations_on_team_assessment_id  (team_assessment_id)
#  index_series_team_participations_on_team_id             (team_id)
#  index_series_team_participations_on_team_number         (team_number)
#
require 'rails_helper'

RSpec.describe Series::TeamParticipation do
  let(:round) { create(:series_round, :with_team_config, :with_person_config) }
  let(:cup) { create(:series_cup, round:) }

  let(:fss_team) { create(:fire_sport_statistics_team) }
  let(:participation) do
    create(:series_team_participation, cup:, team: fss_team, team_number: 2, team_gender: 1,
                                       team_assessment: create(:series_team_assessment, round:))
  end

  it 'returns entity id' do
    expect(participation.entity_id).to eq "#{fss_team.id}-2"
  end

  it 'shows points with correction' do
    expect(participation.points_with_correction_string).to eq 15

    participation.points_correction = 3
    expect(participation.points_with_correction).to eq 18
    expect(participation.points_with_correction_string).to eq '15+3'
    expect(participation.result_entry_with_points).to eq '18,99 (15+3)'

    participation.points_correction = -2
    expect(participation.points_with_correction_string).to eq '15-2'
  end
end
