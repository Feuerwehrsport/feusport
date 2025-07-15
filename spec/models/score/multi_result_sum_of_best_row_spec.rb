# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Score::MultiResultSumOfBestRow' do
  let(:competition) { create(:competition) }
  let(:band) { create(:band, :female, competition:) }

  let(:hl) { create(:discipline, :hl, competition:) }
  let(:hb) { create(:discipline, :hb, competition:) }
  let(:assessment_hl) { create(:assessment, competition:, discipline: hl, band:) }
  let(:assessment_hb) { create(:assessment, competition:, discipline: hb, band:) }
  let(:result_zk) do
    Score::Result.create!(competition:, forced_name: 'Zweikampf - Frauen', multi_result_method: :sum_of_best,
                          image_key: :zk, results: [result_hb, result_hl])
  end
  let(:result_hl) { create(:score_result, competition:, assessment: assessment_hl) }
  let(:result_hb) { create(:score_result, competition:, assessment: assessment_hb) }

  describe '.rows' do
    let(:person1) { create(:person, :generated, competition:, band:) }
    let(:person2) { create(:person, :generated, competition:, band:) }
    let(:person3) { create(:person, :generated, competition:, band:) }
    let(:person4) { create(:person, :generated, competition:, band:) }
    let(:person5) { create(:person, :generated, competition:, band:) }
    let(:person6) { create(:person, :generated, competition:, band:) }

    context 'when entries given' do
      let!(:list_hb1) do
        create_score_list(result_hb, person1 => 1912, person2 => 2020, person3 => 2040, person4 => nil,
                                     person5 => 2021, person6 => 2021)
      end
      let!(:list_hb2) do
        create_score_list(result_hb, person1 => 1913, person2 => 2021, person3 => 2041, person4 => nil,
                                     person5 => 2300, person6 => nil)
      end
      let!(:list_hl1) do
        create_score_list(result_hl, person1 => 2020, person2 => 1912, person3 => 1892, person4 => 1999,
                                     person5 => 1910, person6 => 1910)
      end
      let!(:list_hl2) do
        create_score_list(result_hl, person1 => 2021, person2 => 1911, person3 => 1893, person4 => 1998,
                                     person5 => 2400, person6 => nil)
      end

      it 'return results in correct order' do
        rows = result_zk.rows
        expect(rows.count).to eq 6

        expect(rows[0].entity).to eq person2
        expect(rows[0].best_result_entry.time).to eq 3931
        expect(rows[0].calculate(position: 1)).to eq 3933
        expect(rows[0].place).to eq 1

        expect(rows[1].entity).to eq person5
        expect(rows[1].best_result_entry.time).to eq 3931
        expect(rows[1].calculate(position: 1)).to eq 4700
        expect(rows[1].place).to eq 2

        expect(rows[2].entity).to eq person6
        expect(rows[2].best_result_entry.time).to eq 3931
        expect(rows[2].calculate(position: 1)).to eq Firesport::INVALID_TIME
        expect(rows[2].place).to eq 3

        expect(rows[3].entity).to be_in([person1, person3])
        expect(rows[3].best_result_entry.time).to eq 3932
        expect(rows[3].calculate(position: 1)).to eq 3934
        expect(rows[3].place).to eq 4

        expect(rows[4].entity).to be_in([person1, person3])
        expect(rows[4].best_result_entry.time).to eq 3932
        expect(rows[4].calculate(position: 1)).to eq 3934
        expect(rows[4].place).to eq 4

        expect(rows[5].entity).to eq person4
        expect(rows[5].best_result_entry.time).to eq Firesport::INVALID_TIME
        expect(rows[5].calculate(position: 1)).to eq Firesport::INVALID_TIME
        expect(rows[5].place).to eq 6
      end

      describe 'supports Certificates::StorageSupport' do
        it 'supports all keys' do
          rows = result_zk.rows
          check_rows = [rows.first, rows.last]

          [
            {
              team_name: '',
              person_name: person2.full_name,
              person_bib_number: '',
              time_long: '39,31 Sekunden',
              time_short: '39,31 s',
              time_without_seconds: '39,31',
              rank: '1.',
              rank_with_rank: '1. Platz',
              rank_without_dot: '1',
              assessment: 'Zweikampf - Frauen',
              assessment_with_gender: 'Zweikampf - Frauen',
              result_name: 'Zweikampf - Frauen',
              date: '29.02.2024',
              place: 'Rostock',
              competition_name: 'MV-Cup',
              points: '',
              points_with_points: '',
              text: 'foo',
            },
            {
              team_name: '',
              person_name: person4.full_name,
              person_bib_number: '',
              time_long: 'Ungültig',
              time_short: 'o.W.',
              time_without_seconds: '-',
              rank: '6.',
              rank_with_rank: '6. Platz',
              rank_without_dot: '6',
              assessment: 'Zweikampf - Frauen',
              assessment_with_gender: 'Zweikampf - Frauen',
              result_name: 'Zweikampf - Frauen',
              date: '29.02.2024',
              place: 'Rostock',
              competition_name: 'MV-Cup',
              points: '',
              points_with_points: '',
              text: 'foo',
            },
          ].each_with_index do |row_match, index|
            row_match.each do |key, value|
              expect(check_rows[index].storage_support_get(
                Certificates::TextField.new(key:, text: 'foo'),
              ).to_s).to eq value
            end
          end
        end
      end
    end

    context 'when all results are invalid' do
      let!(:list_hb1) do
        create_score_list(result_hb, person1 => 123, person2 => nil, person3 => nil, person4 => nil)
      end
      let!(:list_hl1) do
        create_score_list(result_hl, person1 => nil, person2 => nil, person3 => nil)
      end

      it 'returns an empty result' do
        rows = result_zk.rows
        expect(rows.count).to eq 3

        expect(rows[0].entity).to eq person1
        expect(rows[0].best_result_entry.time).to eq Firesport::INVALID_TIME
        expect(rows[0].calculate(position: 1)).to eq Firesport::INVALID_TIME
        expect(rows[0].place).to eq 3

        expect(rows[1].entity).to be_in([person2, person3])
        expect(rows[1].best_result_entry.time).to eq Firesport::INVALID_TIME
        expect(rows[1].calculate(position: 1)).to eq Firesport::INVALID_TIME
        expect(rows[1].place).to eq 3

        expect(rows[2].entity).to be_in([person2, person3])
        expect(rows[2].best_result_entry.time).to eq Firesport::INVALID_TIME
        expect(rows[2].calculate(position: 1)).to eq Firesport::INVALID_TIME
        expect(rows[2].place).to eq 3
      end
    end
  end
end
