# frozen_string_literal: true

# == Schema Information
#
# Table name: series_team_points_corrections
#
#  id                     :uuid             not null, primary key
#  discipline             :string           not null
#  points_correction      :integer          not null
#  points_correction_hint :string           not null
#  round_key              :string           not null
#  team_number            :integer          default(1), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  competition_id         :uuid             not null
#  team_id                :bigint           not null
#
# Indexes
#
#  index_series_team_points_corrections_on_competition_id  (competition_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
require 'rails_helper'

RSpec.describe Series::TeamPointsCorrection do
  let(:competition) { create(:competition) }
  let(:band) { result.assessment.band }
  let(:round) { create(:series_round, :with_team_config, :with_person_config) }
  let(:team_round_key) { "#{round.id}-male-la" }
  let(:person_round_key) { "#{round.id}-male-hl" }
  let!(:result) do
    create(:score_result, competition:, series_team_round_keys: [team_round_key, ''],
                          series_person_round_keys: [person_round_key])
  end

  let(:fss_team) { create(:fire_sport_statistics_team) }
  let(:correction) do
    described_class.create!(competition:, team: fss_team, round_key: team_round_key, discipline: 'la',
                            team_number: 2, points_correction: -3, points_correction_hint: 'Strafe')
  end

  it 'finds config for round key' do
    expect(correction.round_key_config.round_key).to eq team_round_key
    expect(correction.round_key_config.name).to eq 'LA-Männer'
  end

  it 'returns possible options' do
    expect(correction.possible_assessment_configs.map(&:round_key)).to eq [team_round_key]
    expect(correction.possible_round_keys).to eq [["D-Cup - #{round.year} - LA-Männer", team_round_key]]
    expect(correction.possible_disciplines).to eq [%w[LA la]]
  end

  it 'returns possible teams' do
    team1 = create(:team, competition:, band:, name: 'Berlin', shortcut: 'B')
    team2 = create(:team, competition:, band:, name: 'Adorf', shortcut: 'A')
    create(:team, competition:, band:, name: 'Berlin', shortcut: 'B')

    expect(correction.possible_teams.map(&:name)).to eq %w[Adorf Berlin]
    expect(correction.possible_teams).to eq [team2, team1].map(&:fire_sport_statistics_team_with_dummy)
  end

  it 'exports hash' do
    expect(correction.to_export_hash).to eq(
      discipline: 'la',
      points_correction: -3,
      points_correction_hint: 'Strafe',
      round_key: team_round_key,
      team_number: 2,
      team_id: fss_team.id,
    )
  end
end
