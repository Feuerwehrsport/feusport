# frozen_string_literal: true

# == Schema Information
#
# Table name: series_person_participations
#
#  id                     :integer          not null, primary key
#  points                 :integer          default(0), not null
#  points_correction      :integer
#  points_correction_hint :string(200)
#  rank                   :integer          not null
#  time                   :integer          not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  cup_id                 :integer          not null
#  person_assessment_id   :integer          not null
#  person_id              :integer          not null
#
# Indexes
#
#  index_series_person_participations_on_cup_id                (cup_id)
#  index_series_person_participations_on_person_assessment_id  (person_assessment_id)
#  index_series_person_participations_on_person_id             (person_id)
#
require 'rails_helper'

RSpec.describe Series::PersonParticipation do
  let(:round) { create(:series_round, :with_team_config, :with_person_config) }
  let(:cup) { create(:series_cup, round:) }

  let(:fss_person) { create(:fire_sport_statistics_person) }
  let(:participation) do
    create(:series_person_participation, cup:, person: fss_person,
                                         person_assessment: create(:series_person_assessment, round:))
  end

  it 'returns person as entity' do
    expect(participation.entity).to eq fss_person
    expect(participation.entity_id).to eq fss_person.id
  end

  it 'shows points with correction' do
    expect(participation.points_with_correction_string).to eq 15
    expect(participation.result_entry_with_points).to eq '18,99 (15)'

    participation.points_correction = 3
    expect(participation.points_with_correction).to eq 18
    expect(participation.points_with_correction_string).to eq '15+3'

    participation.points_correction = -2
    expect(participation.points_with_correction).to eq 13
    expect(participation.points_with_correction_string).to eq '15-2'
  end
end
