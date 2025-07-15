# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Score::GroupResult do
  let!(:competition) { create(:competition) }
  let!(:band) { create(:band, :female, competition:) }

  let!(:hl) { create(:discipline, :hl, competition:) }

  let!(:assessment_hl) { create(:assessment, competition:, discipline: hl, band:) }

  let!(:result_hl) do
    create(:score_result, competition:, assessment: assessment_hl,
                          group_run_count: 3, group_score_count: 2, group_assessment: true)
  end

  let!(:team1) { create(:team, competition:, band:) }
  let!(:team1_person1) { create(:person, :generated, competition:, band:, team: team1) }
  let!(:team1_person2) { create(:person, :generated, competition:, band:, team: team1) }
  let!(:team1_a) { TeamRelay.find_or_create_by!(team: team1, number: 1) }
  let!(:team2) { create(:team, competition:, band:) }
  let!(:team2_person1) { create(:person, :generated, competition:, band:, team: team2) }
  let!(:team2_person2) { create(:person, :generated, competition:, band:, team: team2) }
  let!(:team2_person3) { create(:person, :generated, competition:, band:, team: team2) }
  let!(:team2_a) { TeamRelay.find_or_create_by!(team: team2, number: 1) }
  let!(:team3) { create(:team, competition:, band:) }
  let!(:team3_person1) { create(:person, :generated, competition:, band:, team: team3) }
  let!(:team3_person2) { create(:person, :generated, competition:, band:, team: team3) }
  let!(:team3_a) { TeamRelay.find_or_create_by!(team: team3, number: 1) }
  let!(:team3_b) { TeamRelay.find_or_create_by!(team: team3, number: 2) }
  let!(:team4) { create(:team, competition:, band:) }
  let!(:team4_person1) { create(:person, :generated, competition:, band:, team: team4) }
  let!(:list_hl) do
    create_score_list(result_hl,
                      team1_person1 => 1900, team1_person2 => 1950,
                      team2_person1 => 1900, team2_person2 => 2000, team2_person3 => 1999,
                      team3_person1 => 1800, team3_person2 => nil,
                      team4_person1 => 1900)
  end

  describe '.rows' do
    it 'calculates correct results' do
      rows = result_hl.group_result.rows

      expect(rows.first.team).to eq team1
      expect(rows.first.result_entry.time).to eq 3850
      expect(rows.first.rows_in.count).to eq 2
      expect(rows.first.rows_out.count).to eq 0
      expect(rows.first.competition_result_valid?).to be true

      expect(rows.second.team).to eq team2
      expect(rows.second.result_entry.time).to eq 3899
      expect(rows.second.rows_in.count).to eq 2
      expect(rows.second.rows_out.count).to eq 1
      expect(rows.second.competition_result_valid?).to be true

      expect(rows.third.team).to eq team3
      expect(rows.third.result_entry.time).to be_nil
      expect(rows.third.rows_in.count).to eq 2
      expect(rows.third.rows_out.count).to eq 0
      expect(rows.third.competition_result_valid?).to be true

      expect(rows.fourth.team).to eq team4
      expect(rows.fourth.result_entry.time).to be_nil
      expect(rows.fourth.rows_in.count).to eq 0
      expect(rows.fourth.rows_out.count).to eq 0
      expect(rows.fourth.competition_result_valid?).to be false
    end
  end

  describe 'supports Certificates::StorageSupport' do
    it 'supports all keys' do
      rows = result_hl.group_result.rows

      [
        {
          team_name: team1.full_name,
          person_name: team1.full_name,
          person_bib_number: '',
          time_long: '38,50 Sekunden',
          time_short: '38,50 s',
          time_without_seconds: '38,50',
          time_very_long: 'mit einer Zeit von 38,50 Sekunden',
          time_other_long: 'belegte mit einer Zeit von 38,50 Sekunden',
          rank: '1.',
          rank_with_rank: '1. Platz',
          rank_with_rank2: 'den 1. Platz',
          rank_without_dot: '1',
          assessment: 'Hakenleitersteigen',
          assessment_with_gender: 'Hakenleitersteigen - Frauen',
          gender: 'Frauen',
          result_name: 'Hakenleitersteigen - Frauen',
          date: '29.02.2024',
          place: 'Rostock',
          competition_name: 'MV-Cup',
          points: '',
          points_with_points: '',
          text: 'foo',
        },
        {
          team_name: team2.full_name,
          person_name: team2.full_name,
          person_bib_number: '',
          time_long: '38,99 Sekunden',
          time_short: '38,99 s',
          time_without_seconds: '38,99',
          time_very_long: 'mit einer Zeit von 38,99 Sekunden',
          time_other_long: 'belegte mit einer Zeit von 38,99 Sekunden',
          rank: '2.',
          rank_with_rank: '2. Platz',
          rank_with_rank2: 'den 2. Platz',
          rank_without_dot: '2',
          assessment: 'Hakenleitersteigen',
          assessment_with_gender: 'Hakenleitersteigen - Frauen',
          gender: 'Frauen',
          result_name: 'Hakenleitersteigen - Frauen',
          date: '29.02.2024',
          place: 'Rostock',
          competition_name: 'MV-Cup',
          points: '',
          points_with_points: '',
          text: 'foo',
        },
        {
          team_name: team3.full_name,
          person_name: team3.full_name,
          person_bib_number: '',
          time_long: 'Ungültig',
          time_short: 'o.W.',
          time_without_seconds: '-',
          time_very_long: 'mit einer ungültigen Zeit',
          time_other_long: 'belegte mit einer ungültigen Zeit',
          rank: '4.',
          rank_with_rank: '4. Platz',
          rank_with_rank2: 'den 4. Platz',
          rank_without_dot: '4',
          assessment: 'Hakenleitersteigen',
          assessment_with_gender: 'Hakenleitersteigen - Frauen',
          gender: 'Frauen',
          result_name: 'Hakenleitersteigen - Frauen',
          date: '29.02.2024',
          place: 'Rostock',
          competition_name: 'MV-Cup',
          points: '',
          points_with_points: '',
          text: 'foo',
        },
        {
          team_name: team4.full_name,
          person_name: team4.full_name,
          person_bib_number: '',
          time_long: 'Ungültig',
          time_short: 'o.W.',
          time_without_seconds: '-',
          time_very_long: 'mit einer ungültigen Zeit',
          time_other_long: 'belegte mit einer ungültigen Zeit',
          rank: '4.',
          rank_with_rank: '4. Platz',
          rank_with_rank2: 'den 4. Platz',
          rank_without_dot: '4',
          assessment: 'Hakenleitersteigen',
          assessment_with_gender: 'Hakenleitersteigen - Frauen',
          gender: 'Frauen',
          result_name: 'Hakenleitersteigen - Frauen',
          date: '29.02.2024',
          place: 'Rostock',
          competition_name: 'MV-Cup',
          points: '',
          points_with_points: '',
          text: 'foo',
        },
      ].each_with_index do |row_match, index|
        row_match.each do |key, value|
          expect(rows[index].storage_support_get(Certificates::TextField.new(key:, text: 'foo')).to_s).to eq value
        end
      end
    end
  end
end
