# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Series::PersonPointsCorrection do
  let(:competition) { create(:competition) }
  let(:band) { result.assessment.band }
  let(:round) { create(:series_round, :with_team_config, :with_person_config) }
  let(:team_round_key) { "#{round.id}-male-la" }
  let(:person_round_key) { "#{round.id}-male-hl" }
  let!(:result) do
    create(:score_result, competition:, series_team_round_keys: [team_round_key, ''],
                          series_person_round_keys: [person_round_key])
  end

  let(:fss_person) { create(:fire_sport_statistics_person) }
  let(:correction) do
    described_class.create!(competition:, person: fss_person, round_key: person_round_key,
                            points_correction: 2, points_correction_hint: 'Bonus')
  end

  it 'finds config for round key' do
    expect(correction.round_key_config.round_key).to eq person_round_key
    expect(correction.round_key_config.name).to eq 'HL-Männer'
  end

  it 'returns possible options' do
    expect(correction.possible_assessment_configs.map(&:round_key)).to eq [person_round_key]
    expect(correction.possible_round_keys).to eq [["D-Cup - #{round.year} - HL-Männer", person_round_key]]
  end

  it 'returns possible people' do
    person1 = create(:person, competition:, band:, first_name: 'Max', last_name: 'Zander')
    person2 = create(:person, competition:, band:, first_name: 'Anna', last_name: 'Albers')

    expect(correction.possible_people).to eq(
      [person1, person2].map(&:fire_sport_statistics_person_with_dummy).sort,
    )
    expect(correction.possible_people.size).to eq 2
  end

  it 'exports hash' do
    expect(correction.to_export_hash).to eq(
      points_correction: 2,
      points_correction_hint: 'Bonus',
      round_key: person_round_key,
      person_id: fss_person.id,
    )
  end
end
