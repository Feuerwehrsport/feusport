# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Series::Team do
  let(:round) { create(:series_round, :with_team_config, :with_person_config) }
  let(:config) { round.team_config_for('male-la') }
  let(:team) do
    described_class.new(
      config:, team: fss_team, team_number: 1,
      team_gender: 1, round:
    )
  end
  let(:fss_team) { create(:fire_sport_statistics_team) }
  let!(:team_participation) do
    create(:series_team_participation,
           team_assessment: build(:series_team_assessment, round:),
           cup: build(:series_cup, round:),
           team_gender: 1,
           team: fss_team)
  end

  describe 'supports Certificates::StorageSupport' do
    it 'supports all keys' do
      team.rank = 42
      team.add_participation(team_participation)

      {
        team_name: 'Mecklenburg-Vorpommern',
        person_name: '',
        person_bib_number: '',
        time_long: '',
        time_short: '',
        time_without_seconds: '',
        rank: '42.',
        rank_with_rank: '42. Platz',
        rank_without_dot: '42',
        assessment: 'D-Cup',
        assessment_with_gender: '',
        result_name: 'LA-Männer',
        date: '',
        place: '',
        competition_name: '',
        points: '15',
        points_with_points: '15 Punkte',
        text: 'foo',
      }.each do |key, value|
        expect(team.storage_support_get(Certificates::TextField.new(key:, text: 'foo')).to_s).to eq value
      end
    end
  end

  describe '#full_name' do
    it 'returns team name without number for single team' do
      expect(team.full_name).to eq 'Mecklenburg-Vorpommern'
    end

    it 'adds team number if team has multiple numbers in round' do
      create(:series_team_participation,
             team_assessment: team_participation.team_assessment,
             cup: team_participation.cup,
             team_gender: 1,
             team_number: 2,
             team: fss_team)
      expect(team.full_name).to eq 'Mecklenburg-Vorpommern 1'
    end
  end

  describe '#points' do
    before do
      create(:series_cup, round:)
      create(:series_cup, round:)
      team.add_participation(team_participation)
    end

    it 'sums points without penalty' do
      expect(team.points).to eq 15
    end

    it 'adds penalty points for missing cups' do
      config.penalty_points = -5
      expect(team.points).to eq 15 - 10
    end
  end
end
