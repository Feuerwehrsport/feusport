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
  let!(:team1_a) { TeamRelay.create!(team: team1, number: 1) }
  let!(:team1_b) { TeamRelay.create!(team: team1, number: 2) }
  let!(:team2) { create(:team, competition:, band:) }
  let!(:team2_person1) { create(:person, :generated, competition:, band:, team: team2) }
  let!(:team2_person2) { create(:person, :generated, competition:, band:, team: team2) }
  let!(:team2_person3) { create(:person, :generated, competition:, band:, team: team2) }
  let!(:team2_a) { TeamRelay.create!(team: team2, number: 1) }
  let!(:team3) { create(:team, competition:, band:) }
  let!(:team3_person1) { create(:person, :generated, competition:, band:, team: team3) }
  let!(:team3_person2) { create(:person, :generated, competition:, band:, team: team3) }
  let!(:team3_a) { TeamRelay.create!(team: team3, number: 1) }
  let!(:team3_b) { TeamRelay.create!(team: team3, number: 2) }
  let!(:team4) { create(:team, competition:, band:) }
  let!(:team4_person1) { create(:person, :generated, competition:, band:, team: team4) }

  let!(:list_la1) do
    create_score_list(result_la,
                      team1 => 2200, team2 => 2400, team3 => 2500, team4 => nil)
  end
  let!(:list_la2) do
    create_score_list(result_la,
                      team1 => 2300, team2 => 2200, team3 => nil)
  end

  # Löschangriff sieht so aus:

  # 1. team1 => 2200, 2300
  # 2. team2 => 2200, 2400
  # 3. team3 => 2500, ow
  # 4. team4 => ow

  let!(:list_hl) do
    create_score_list(result_hl,
                      team1_person1 => 1900, team1_person2 => 1950,
                      team2_person1 => 1900, team2_person2 => 2000, team2_person3 => 1999,
                      team3_person1 => 1800, team3_person2 => nil,
                      team4_person1 => 1900)
  end
  let!(:list_fs) do
    create_score_list(result_fs,
                      team1_a => 6002, team2_a => 6000, team3_a => 6002,
                      team3_b => 6000, team1_b => 6000)

    # Wenn Einzelwertung wäre, dann so: (Wegen der Startreihenfolge)

    # 1. team2_a => 6000
    # 2. team3_b => 6000
    # 3. team1_b => 6000
    # 4. team1_a => 6002
    # 5. team3_a => 6002

    # Jetzt ist es aber so:

    # 1. team1 => 6000, 6002
    # 1. team3 => 6000, 6002
    # 3. team2 => 6000
  end

  let(:result_type) { 'dcup' }
  let!(:competition_result) do
    create(:score_competition_result, competition:, results: [result_la, result_fs, result_hl], result_type:)
  end

  describe '.dcup' do
    it 'calculates correct results' do
      rows = competition_result.rows
      expect(rows[0].points).to eq 29
      expect(rows[0].place).to eq 1
      expect(rows[0].team).to eq team1
      expect(rows[0].assessment_result_from(result_la).points).to eq 10
      expect(rows[0].assessment_result_from(result_hl).points).to eq 10
      expect(rows[0].assessment_result_from(result_hl).row.result_entry.time).to eq 3850
      expect(rows[0].assessment_result_from(result_fs).points).to eq 9

      expect(rows[1].points).to eq 26
      expect(rows[1].place).to eq 2
      expect(rows[1].team).to eq team2
      expect(rows[1].assessment_result_from(result_la).points).to eq 9
      expect(rows[1].assessment_result_from(result_hl).points).to eq 9
      expect(rows[1].assessment_result_from(result_hl).row.result_entry.time).to eq 3899
      expect(rows[1].assessment_result_from(result_fs).points).to eq 8

      expect(rows[2].points).to eq 25
      expect(rows[2].place).to eq 3
      expect(rows[2].team).to eq team3
      expect(rows[2].assessment_result_from(result_la).points).to eq 8
      expect(rows[2].assessment_result_from(result_hl).points).to eq 8
      expect(rows[2].assessment_result_from(result_hl).row.result_entry.time).to eq Firesport::INVALID_TIME
      expect(rows[2].assessment_result_from(result_fs).points).to eq 9

      expect(rows[3].points).to eq 7
      expect(rows[3].place).to eq 4
      expect(rows[3].team).to eq team4
      expect(rows[3].assessment_result_from(result_la).points).to eq 7
      expect(rows[3].assessment_result_from(result_hl).points).to eq 0
      expect(rows[3].assessment_result_from(result_hl).row.result_entry.time).to eq Firesport::INVALID_TIME
      expect(rows[3].assessment_result_from(result_fs)).to be_nil
    end
  end

  describe '.places_to_points' do
    let(:result_type) { 'places_to_points' }

    it 'calculates correct results' do
      # Zuerst prüfen, ob die FS richtig als Einzelwertung berechnet wurde
      fs_rows = result_fs.rows
      expect(fs_rows[0].result_entry.time).to eq 6000
      expect(fs_rows[0].entity).to eq team2_a
      expect(fs_rows[0].place).to eq 1
      expect(fs_rows[1].result_entry.time).to eq 6000
      expect(fs_rows[1].entity).to eq team3_b
      expect(fs_rows[1].place).to eq 2
      expect(fs_rows[2].result_entry.time).to eq 6000
      expect(fs_rows[2].entity).to eq team1_b
      expect(fs_rows[2].place).to eq 3
      expect(fs_rows[3].result_entry.time).to eq 6002
      expect(fs_rows[3].entity).to eq team1_a
      expect(fs_rows[3].place).to eq 4
      expect(fs_rows[4].result_entry.time).to eq 6002
      expect(fs_rows[4].entity).to eq team3_a
      expect(fs_rows[4].place).to eq 5

      # Dann die Gesamtwertung prüfen

      rows = competition_result.rows
      expect(rows[0].points).to eq 3
      expect(rows[0].place).to eq 1
      expect(rows[0].team).to eq team1
      expect(rows[0].assessment_result_from(result_la).points).to eq 1
      expect(rows[0].assessment_result_from(result_hl).points).to eq 1
      expect(rows[0].assessment_result_from(result_hl).row.result_entry.time).to eq 3850
      expect(rows[0].assessment_result_from(result_fs).points).to eq 1

      expect(rows[1].points).to eq 7
      expect(rows[1].place).to eq 2
      expect(rows[1].team).to eq team2
      expect(rows[1].assessment_result_from(result_la).points).to eq 2
      expect(rows[1].assessment_result_from(result_hl).points).to eq 2
      expect(rows[1].assessment_result_from(result_hl).row.result_entry.time).to eq 3899
      expect(rows[1].assessment_result_from(result_fs).points).to eq 3

      expect(rows[2].points).to eq 7
      expect(rows[2].place).to eq 3
      expect(rows[2].team).to eq team3
      expect(rows[2].assessment_result_from(result_la).points).to eq 3
      expect(rows[2].assessment_result_from(result_hl).points).to eq 3
      expect(rows[2].assessment_result_from(result_hl).row.result_entry.time).to eq Firesport::INVALID_TIME
      expect(rows[2].assessment_result_from(result_fs).points).to eq 1

      # Punktgleich aber besserer LA

      expect(rows[3].points).to eq 12
      expect(rows[3].place).to eq 4
      expect(rows[3].team).to eq team4
      expect(rows[3].assessment_result_from(result_la).points).to eq 4
      expect(rows[3].assessment_result_from(result_hl).points).to eq 4
      expect(rows[3].assessment_result_from(result_hl).row.result_entry.time).to eq Firesport::INVALID_TIME
      expect(rows[3].assessment_result_from(result_fs).points).to eq 4
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
          points: '25',
          points_with_points: '25 Punkte',
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
          points: '7',
          points_with_points: '7 Punkte',
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
