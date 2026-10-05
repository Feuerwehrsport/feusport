# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Series::AssessmentCalculation do
  let(:competition) { create(:competition) }
  let(:other_competition) { create(:competition, name: 'Anderer Cup', date: Date.parse('2024-01-15')) }
  let(:female) { create(:band, :female, competition:) }

  let(:base_config) do
    {
      'name' => 'Frauen',
      'calc_participations_count' => 2,
      'points_for_rank' => [10, 8],
      'ranking_logic' => ['points'],
    }
  end
  let(:team_config_extra) { {} }
  let(:person_config_extra) { {} }
  let(:full_cup_count) { 4 }
  let(:round) do
    create(:series_round,
           full_cup_count:,
           team_assessments_config_jsonb: [
             base_config.merge('key' => 'female-la', 'disciplines' => ['la']).merge(team_config_extra),
           ],
           person_assessments_config_jsonb: [
             base_config.merge('key' => 'female-hl', 'disciplines' => ['hl']).merge(person_config_extra),
           ])
  end

  let(:past_cup) { create(:series_cup, round:, competition_date: Date.parse('2024-01-01')) }
  let(:future_cup) { create(:series_cup, round:, competition_date: Date.parse('2024-06-01')) }
  let(:other_dummy_cup) { Series::Cup.find_or_create_today!(round, other_competition) }

  describe 'team assessment' do
    let(:la) { create(:discipline, :la, competition:) }
    let(:assessment) { create(:assessment, competition:, discipline: la, band: female) }
    let(:result) { create(:score_result, competition:, assessment:) }
    let(:fss_team1) { create(:fire_sport_statistics_team, name: 'Adorf', short: 'Adorf') }
    let(:fss_team2) { create(:fire_sport_statistics_team, name: 'Bdorf', short: 'Bdorf') }
    let(:team1) do
      create(:team, band: female, competition:, name: 'Adorf', shortcut: 'Adorf', fire_sport_statistics_team: fss_team1)
    end
    let(:team2) do
      create(:team, band: female, competition:, name: 'Bdorf', shortcut: 'Bdorf', fire_sport_statistics_team: fss_team2)
    end
    let(:team_assessment) { create(:series_team_assessment, round:, discipline: 'la', key: 'female-la') }
    let(:config) { round.team_config_for('female-la') }

    def online_participation(cup, team, fss_team, time:, points:)
      create(:series_team_participation, cup:, team: fss_team, team_number: team.number, team_gender: 0,
                                         team_assessment:, time:, points:, rank: 1)
    end

    before do
      create_score_list(result, team1 => 1200, team2 => 1300)
      result.update!(series_team_round_keys: [config.round_key])

      online_participation(past_cup, team1, fss_team1, time: 2500, points: 5)
      online_participation(future_cup, team2, fss_team2, time: 2000, points: 10)
      online_participation(other_dummy_cup, team2, fss_team2, time: 2000, points: 10)

      Series::TeamPointsCorrection.create!(competition:, round_key: config.round_key, team: fss_team2,
                                           team_number: team2.number, discipline: 'la',
                                           points_correction: 20, points_correction_hint: 'Bonus')
    end

    it 'combines online participations, todays results and corrections' do
      rows = config.rows(competition)
      expect(rows.map { |row| [row.team, row.rank, row.points, row.count] }).to eq [
        [fss_team2, 1, 28, 1],
        [fss_team1, 2, 15, 2],
      ]
      expect(rows.first.participations_for_cup(Series::Cup.find_or_create_today!(round, competition))
                 .map(&:points_with_correction_string)).to eq ['8+20']
    end

    context 'with honor ranking logic' do
      let(:team_config_extra) { { 'honor_ranking_logic' => ['best_time'] } }

      it 'ranks the best three by honor logic' do
        rows = config.rows(competition)
        expect(rows.map { |row| [row.team, row.rank] }).to eq [[fss_team1, 1], [fss_team2, 2]]
      end
    end

    context 'when round is completed' do
      let(:full_cup_count) { 2 }
      let(:team_config_extra) { { 'min_participations_count' => 2 } }

      it 'removes rank for entities with too few participations' do
        rows = config.rows(competition)
        expect(rows.map { |row| [row.team, row.rank] }).to eq [[fss_team2, nil], [fss_team1, 1]]
      end
    end
  end

  describe 'person assessment' do
    let(:hl) { create(:discipline, :hl, competition:) }
    let(:assessment) { create(:assessment, competition:, discipline: hl, band: female) }
    let(:result) { create(:score_result, competition:, assessment:) }
    let(:fss_person1) { create(:fire_sport_statistics_person, first_name: 'Anna', last_name: 'Albers') }
    let(:fss_person2) { create(:fire_sport_statistics_person, first_name: 'Berta', last_name: 'Bauer') }
    let(:person1) do
      create(:person, competition:, band: female, first_name: 'Anna', last_name: 'Albers',
                      fire_sport_statistics_person: fss_person1)
    end
    let(:person2) do
      create(:person, competition:, band: female, first_name: 'Berta', last_name: 'Bauer',
                      fire_sport_statistics_person: fss_person2)
    end
    let(:person_assessment) { create(:series_person_assessment, round:, discipline: 'hl', key: 'female-hl') }
    let(:config) { round.person_config_for('female-hl') }

    def online_participation(cup, fss_person, time:, points:)
      create(:series_person_participation, cup:, person: fss_person, person_assessment:, time:, points:, rank: 1)
    end

    before do
      create_score_list(result, person1 => 1800, person2 => 1900)
      result.update!(series_person_round_keys: [config.round_key])

      online_participation(past_cup, fss_person1, time: 2500, points: 5)
      online_participation(future_cup, fss_person2, time: 1700, points: 10)
      online_participation(other_dummy_cup, fss_person2, time: 1700, points: 10)

      Series::PersonPointsCorrection.create!(competition:, round_key: config.round_key, person: fss_person2,
                                             points_correction: 20, points_correction_hint: 'Bonus')
    end

    it 'combines online participations, todays results and corrections' do
      rows = config.rows(competition)
      expect(rows.map { |row| [row.person, row.rank, row.points, row.count] }).to eq [
        [fss_person2, 1, 28, 1],
        [fss_person1, 2, 15, 2],
      ]
    end
  end
end
