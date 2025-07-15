# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Score::MultiResultBestRow' do
  let(:competition) { create(:competition) }
  let(:band) { create(:band, :female, competition:) }

  let(:la) { create(:discipline, :la, competition:) }
  let(:assessment) { create(:assessment, competition:, discipline: la, band:) }
  let(:result) do
    Score::Result.create!(competition:, forced_name: 'DIN oder TGL', multi_result_method: :best,
                          image_key: :la, results: [result_din, result_tgl])
  end
  let(:result_din) { create(:score_result, competition:, assessment:, forced_name: 'DIN') }
  let(:result_tgl) { create(:score_result, competition:, assessment:, forced_name: 'TGL') }

  describe '.rows' do
    let(:team1) { create(:team, competition:, band:) }
    let(:team2) { create(:team, competition:, band:) }
    let(:team3) { create(:team, competition:, band:) }
    let(:team4) { create(:team, competition:, band:) }

    context 'when entries given' do
      let!(:list_din1) do
        create_score_list(result_din, team1 => 1892, team2 => nil, team3 => 2040, team4 => nil)
      end
      let!(:list_din2) do
        create_score_list(result_din, team1 => 1912, team2 => 2021, team3 => 2041, team4 => nil)
      end
      let!(:list_tgl1) do
        create_score_list(result_tgl, team1 => nil, team2 => 1912, team3 => 1892, team4 => 1999)
      end
      let!(:list_tgl2) do
        create_score_list(result_tgl, team1 => 2021, team2 => 1892, team3 => 1893, team4 => 1998)
      end

      context 'when method is best' do
        it 'return results in correct order' do
          rows = result.rows
          expect(rows.count).to eq 4

          expect(rows[0].entity).to eq team3
          expect(rows[0].best_result_entry.time).to eq 1892
          expect(rows[0].calculate(position: 1)).to eq 1893
          expect(rows[0].calculate(position: 2)).to eq 2040
          expect(rows[0].calculate(position: 3)).to eq 2041
          expect(rows[0].place).to eq 1

          expect(rows[1].entity).to be_in([team1, team2])
          expect(rows[1].best_result_entry.time).to eq 1892
          expect(rows[1].calculate(position: 1)).to eq 1912
          expect(rows[1].calculate(position: 2)).to eq 2021
          expect(rows[1].place).to eq 2

          expect(rows[2].entity).to be_in([team1, team2])
          expect(rows[2].best_result_entry.time).to eq 1892
          expect(rows[2].calculate(position: 1)).to eq 1912
          expect(rows[2].calculate(position: 2)).to eq 2021
          expect(rows[2].place).to eq 2

          expect(rows[3].entity).to eq team4
          expect(rows[3].best_result_entry.time).to eq 1998
          expect(rows[3].calculate(position: 1)).to eq 1999
          expect(rows[3].place).to eq 4
        end
      end

      describe 'supports Certificates::StorageSupport' do
        it 'supports all keys' do
          rows = result.rows
          rows = [rows.first, rows.last]

          [
            {
              team_name: team3.full_name,
              person_name: team3.full_name,
              person_bib_number: '',
              time_long: '18,92 Sekunden',
              time_short: '18,92 s',
              time_without_seconds: '18,92',
              rank: '1.',
              rank_with_rank: '1. Platz',
              rank_without_dot: '1',
              assessment: 'DIN oder TGL',
              assessment_with_gender: 'DIN oder TGL',
              result_name: 'DIN oder TGL',
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
              time_long: '19,98 Sekunden',
              time_short: '19,98 s',
              time_without_seconds: '19,98',
              rank: '4.',
              rank_with_rank: '4. Platz',
              rank_without_dot: '4',
              assessment: 'DIN oder TGL',
              assessment_with_gender: 'DIN oder TGL',
              result_name: 'DIN oder TGL',
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

    context 'when all results are invalid' do
      let!(:list_la1) do
        create_score_list(result_din, team1 => 1, team2 => nil, team3 => nil)
      end
      let!(:list_la2) do
        create_score_list(result_tgl, team1 => 2, team2 => nil, team3 => nil)
      end

      context 'when result_method is best' do
        it 'returns an empty result' do
          rows = result.rows
          expect(rows.count).to eq 3

          expect(rows[0].entity).to eq team1
          expect(rows[0].best_result_entry.time).to eq 1
          expect(rows[0].calculate(position: 1)).to eq 2
          expect(rows[0].place).to eq 1

          expect(rows[1].entity).to be_in([team2, team3])
          expect(rows[1].best_result_entry.time).to eq Firesport::INVALID_TIME
          expect(rows[1].calculate(position: 1)).to eq Firesport::INVALID_TIME
          expect(rows[1].place).to eq 3

          expect(rows[2].entity).to be_in([team2, team3])
          expect(rows[2].best_result_entry.time).to eq Firesport::INVALID_TIME
          expect(rows[2].calculate(position: 1)).to eq Firesport::INVALID_TIME
          expect(rows[2].place).to eq 3
        end
      end
    end
  end
end
