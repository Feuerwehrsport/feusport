# frozen_string_literal: true

# == Schema Information
#
# Table name: score_competition_results
#
#  id             :uuid             not null, primary key
#  hidden         :boolean          default(FALSE), not null
#  name           :string(100)      not null
#  result_type    :string(50)       not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  competition_id :uuid             not null
#
# Indexes
#
#  index_score_competition_results_on_competition_id           (competition_id)
#  index_score_competition_results_on_name_and_competition_id  (name,competition_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
require 'rails_helper'

RSpec.describe Score::CompetitionResult do
  let!(:competition) { create(:competition) }
  let!(:band) { create(:band, :female, competition:) }

  let!(:la) { create(:discipline, :la, competition:) }
  let!(:fs) { create(:discipline, :fs, competition:) }
  let!(:hl) { create(:discipline, :hl, competition:) }

  let!(:assessment_la) { create(:assessment, competition:, discipline: la, band:) }
  let!(:assessment_fs) { create(:assessment, competition:, discipline: fs, band:) }
  let!(:assessment_hl) { create(:assessment, competition:, discipline: hl, band:) }

  let!(:result_la) { create(:score_result, competition:, assessment: assessment_la) }
  let!(:result_fs) { create(:score_result, competition:, assessment: assessment_fs) }
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

  let!(:list_la) { create_score_list(result_la, team1 => 2200, team2 => 2300, team3 => nil) }
  let!(:list_hl) do
    create_score_list(result_hl,
                      team1_person1 => 1900, team1_person2 => 1950,
                      team2_person1 => 1900, team2_person2 => 2000, team2_person3 => 1999,
                      team3_person1 => 1800, team3_person2 => nil,
                      team4_person1 => 1900)
  end
  let!(:list_fs) do
    create_score_list(result_fs, team1_a => 6000, team2_a => 6001, team3_a => 60_002, team3_b => 5999)
  end

  let(:result_type) { 'dcup' }
  let!(:competition_result) do
    create(:score_competition_result, competition:, results: [result_la, result_fs, result_hl], result_type:)
  end

  describe '.dcup' do
    it 'calculates correct results' do
      rows = competition_result.send(:dcup)
      expect(rows.first.points).to eq 29
      expect(rows.first.team).to eq team1
      expect(rows.first.assessment_result_from(result_la).points).to eq 10
      expect(rows.first.assessment_result_from(result_hl).points).to eq 10
      expect(rows.first.assessment_result_from(result_hl).row.result_entry.time).to eq 3850
      expect(rows.first.assessment_result_from(result_fs).points).to eq 9

      expect(rows.second.points).to eq 26
      expect(rows.second.team).to eq team2
      expect(rows.second.assessment_result_from(result_la).points).to eq 9
      expect(rows.second.assessment_result_from(result_hl).points).to eq 9
      expect(rows.second.assessment_result_from(result_hl).row.result_entry.time).to eq 3899
      expect(rows.second.assessment_result_from(result_fs).points).to eq 8

      expect(rows.third.points).to eq 26
      expect(rows.third.team).to eq team3
      expect(rows.third.assessment_result_from(result_la).points).to eq 8
      expect(rows.third.assessment_result_from(result_hl).points).to eq 8
      expect(rows.third.assessment_result_from(result_hl).row.result_entry.time).to be_nil
      expect(rows.third.assessment_result_from(result_fs).points).to eq 10

      expect(rows.fourth.points).to eq 0
      expect(rows.fourth.team).to eq team4
      expect(rows.fourth.assessment_result_from(result_la)).to be_nil
      expect(rows.fourth.assessment_result_from(result_hl).points).to eq 0
      expect(rows.fourth.assessment_result_from(result_hl).row.result_entry.time).to be_nil
      expect(rows.fourth.assessment_result_from(result_fs)).to be_nil
    end
  end

  describe '.places_to_points' do
    let(:result_type) { 'places_to_points' }

    it 'calculates correct results' do
      rows = competition_result.send(:places_to_points)
      expect(rows.first.points).to eq 4
      expect(rows.first.team).to eq team1
      expect(rows.first.assessment_result_from(result_la).points).to eq 1
      expect(rows.first.assessment_result_from(result_hl).points).to eq 1
      expect(rows.first.assessment_result_from(result_hl).row.result_entry.time).to eq 3850
      expect(rows.first.assessment_result_from(result_fs).points).to eq 2

      expect(rows.second.points).to eq 7
      expect(rows.second.team).to eq team2
      expect(rows.second.assessment_result_from(result_la).points).to eq 2
      expect(rows.second.assessment_result_from(result_hl).points).to eq 2
      expect(rows.second.assessment_result_from(result_hl).row.result_entry.time).to eq 3899
      expect(rows.second.assessment_result_from(result_fs).points).to eq 3

      expect(rows.third.points).to eq 7
      expect(rows.third.team).to eq team3
      expect(rows.third.assessment_result_from(result_la).points).to eq 3
      expect(rows.third.assessment_result_from(result_hl).points).to eq 3
      expect(rows.third.assessment_result_from(result_hl).row.result_entry.time).to be_nil
      expect(rows.third.assessment_result_from(result_fs).points).to eq 1

      expect(rows.fourth.points).to eq 12
      expect(rows.fourth.team).to eq team4
      expect(rows.fourth.assessment_result_from(result_la).points).to eq 4
      expect(rows.fourth.assessment_result_from(result_hl).points).to eq 4
      expect(rows.fourth.assessment_result_from(result_hl).row.result_entry.time).to be_nil
      expect(rows.fourth.assessment_result_from(result_fs).points).to eq 4
    end
  end

  describe 'some export features' do
    it 'renders PDF' do
      pdf = Exports::Pdf::Score::CompetitionResults.perform([competition_result])
      expect(pdf.bytestream).to start_with '%PDF-1.3'
      expect(pdf.bytestream).to end_with "%%EOF\n"
    end
  end

  describe 'supports Certificates::StorageSupport' do
    it 'supports all keys' do
      rows = competition_result.rows

      [
        {
          team_name: team1.full_name,
          person_name: team1.full_name,
          person_bib_number: '',
          time_long: '',
          time_very_long: '',
          time_other_long: '',
          time_short: '',
          time_without_seconds: '',
          rank: '1.',
          rank_with_rank: '1. Platz',
          rank_with_rank2: 'den 1. Platz',
          rank_without_dot: '1',
          assessment: 'Wettkampf',
          assessment_with_gender: 'Wettkampf',
          gender: '',
          result_name: 'Wettkampf',
          date: '29.02.2024',
          place: 'Rostock',
          competition_name: 'MV-Cup',
          points: '29',
          points_with_points: '29 Punkte',
          text: 'foo',
        },
        {
          team_name: team2.full_name,
          person_name: team2.full_name,
          person_bib_number: '',
          time_long: '',
          time_very_long: '',
          time_other_long: '',
          time_short: '',
          time_without_seconds: '',
          rank: '2.',
          rank_with_rank: '2. Platz',
          rank_with_rank2: 'den 2. Platz',
          rank_without_dot: '2',
          assessment: 'Wettkampf',
          assessment_with_gender: 'Wettkampf',
          gender: '',
          result_name: 'Wettkampf',
          date: '29.02.2024',
          place: 'Rostock',
          competition_name: 'MV-Cup',
          points: '26',
          points_with_points: '26 Punkte',
          text: 'foo',
        },
        {
          team_name: team3.full_name,
          person_name: team3.full_name,
          person_bib_number: '',
          time_long: '',
          time_very_long: '',
          time_other_long: '',
          time_short: '',
          time_without_seconds: '',
          rank: '3.',
          rank_with_rank: '3. Platz',
          rank_with_rank2: 'den 3. Platz',
          rank_without_dot: '3',
          assessment: 'Wettkampf',
          assessment_with_gender: 'Wettkampf',
          gender: '',
          result_name: 'Wettkampf',
          date: '29.02.2024',
          place: 'Rostock',
          competition_name: 'MV-Cup',
          points: '26',
          points_with_points: '26 Punkte',
          text: 'foo',
        },
        {
          team_name: team4.full_name,
          person_name: team4.full_name,
          person_bib_number: '',
          time_long: '',
          time_very_long: '',
          time_other_long: '',
          time_short: '',
          time_without_seconds: '',
          rank: '4.',
          rank_with_rank: '4. Platz',
          rank_with_rank2: 'den 4. Platz',
          rank_without_dot: '4',
          assessment: 'Wettkampf',
          assessment_with_gender: 'Wettkampf',
          gender: '',
          result_name: 'Wettkampf',
          date: '29.02.2024',
          place: 'Rostock',
          competition_name: 'MV-Cup',
          points: '0',
          points_with_points: '0 Punkte',
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
