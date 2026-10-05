# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Exports::Pdf::Series::Round do
  let(:competition) { create(:competition) }
  let(:female) { create(:band, :female, competition:) }
  let(:la) { create(:discipline, :la, competition:) }
  let(:assessment) { create(:assessment, competition:, discipline: la, band: female) }
  let(:result) { create(:score_result, competition:, assessment:) }
  let(:round) { create(:series_round, :with_team_config) }
  let(:config) { round.team_config_for('male-la') }
  let(:past_cup) { create(:series_cup, round:, competition_date: Date.parse('2024-01-01'), competition_place: 'Adorf') }
  let(:fss_team) { create(:fire_sport_statistics_team, name: 'Adorf', short: 'Adorf') }
  let(:team1) do
    create(:team, band: female, competition:, name: 'Adorf', shortcut: 'Adorf', fire_sport_statistics_team: fss_team)
  end
  let(:team2) { create(:team, band: female, competition:, name: 'Bdorf', shortcut: 'Bdorf') }

  before do
    create_score_list(result, team1 => 1200, team2 => 1300)
    result.update!(series_team_round_keys: [config.round_key])
    create(:series_team_participation, cup: past_cup, team: fss_team, team_number: team1.number, team_gender: 0,
                                       team_assessment: create(:series_team_assessment, round:),
                                       time: 2500, points: 30, rank: 1)
  end

  it 'leaves cells empty for cups without participation' do
    export = described_class.perform(round, competition)
    expect(export.bytestream).to start_with('%PDF')

    data = export.send(:index_export_data, config, config.rows(competition))
    expect(data.first).to eq %w[Platz Team Adorf Rostock Teil. Punkte]
    expect(data.pluck(1)).to eq %w[Team Adorf Bdorf]
    expect(data[1][2]).to be_a(Prawn::Table)
    expect(data[2][2]).to eq ''
    expect(data[2][3]).to be_a(Prawn::Table)
  end
end
