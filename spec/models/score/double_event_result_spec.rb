# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Score::DoubleEventResult' do
  let(:competition) { create(:competition) }
  let(:band) { create(:band, :female, competition:) }
  let(:multi_result_method) { :sum_of_best }

  let(:hl) { create(:discipline, :hl, competition:) }
  let(:hb) { create(:discipline, :hb, competition:) }
  let(:assessment_hl) { create(:assessment, competition:, discipline: hl, band:) }
  let(:assessment_hb) { create(:assessment, competition:, discipline: hb, band:) }
  let(:result_zk) do
    Score::Result.create!(competition:, forced_name: 'Zweikampf - Frauen', multi_result_method:,
                          image_key: :zk, results: [result_hb, result_hl])
  end
  let(:result_hl) { create(:score_result, competition:, assessment: assessment_hl) }
  let(:result_hb) { create(:score_result, competition:, assessment: assessment_hb) }

  describe '.rows' do
    let(:person1) { create(:person, :generated, competition:, band:) }
    let(:person2) { create(:person, :generated, competition:, band:) }
    let(:person3) { create(:person, :generated, competition:, band:) }
    let(:person4) { create(:person, :generated, competition:, band:) }

    context 'when entries given' do
      let!(:list1) { create_score_list(result_hb, person1 => 1912, person2 => 2020, person3 => 2040, person4 => nil) }
      let!(:list2) { create_score_list(result_hl, person1 => 2020, person2 => 1911, person3 => 3030, person4 => 1999) }

      context 'when method is sum_of_best' do
        let(:multi_result_method) { :sum_of_best }

        it 'return results in correct order' do
          rows = result_zk.rows
          expect(rows.count).to eq 3

          expect(rows.first.best_result_entry.time).to eq 3931
          expect(rows.first.entity).to eq person2

          expect(rows.second.best_result_entry.time).to eq 3932
          expect(rows.second.entity).to eq person1

          expect(rows.third.best_result_entry.time).to eq 5070
          expect(rows.third.entity).to eq person3
        end
      end

      context 'when method is best' do
        let(:multi_result_method) { :best }

        it 'return results in correct order' do
          rows = result_zk.rows
          expect(rows.count).to eq 4

          expect(rows.first.best_result_entry.time).to eq 1911
          expect(rows.first.entity).to eq person2

          expect(rows.second.best_result_entry.time).to eq 1912
          expect(rows.second.entity).to eq person1

          expect(rows.third.best_result_entry.time).to eq 1999
          expect(rows.third.entity).to eq person4

          expect(rows.fourth.best_result_entry.time).to eq 2040
          expect(rows.fourth.entity).to eq person3
        end
      end

      describe 'supports Certificates::StorageSupport' do
        it 'supports all keys' do
          rows = result_zk.rows

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
              person_name: person1.full_name,
              person_bib_number: '',
              time_long: '39,32 Sekunden',
              time_short: '39,32 s',
              time_without_seconds: '39,32',
              rank: '2.',
              rank_with_rank: '2. Platz',
              rank_without_dot: '2',
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
              person_name: person3.full_name,
              person_bib_number: '',
              time_long: '50,70 Sekunden',
              time_short: '50,70 s',
              time_without_seconds: '50,70',
              rank: '3.',
              rank_with_rank: '3. Platz',
              rank_without_dot: '3',
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
              expect(rows[index].storage_support_get(Certificates::TextField.new(key:, text: 'foo')).to_s).to eq value
            end
          end
        end
      end
    end
  end
end
