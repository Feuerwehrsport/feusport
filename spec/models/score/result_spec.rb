# frozen_string_literal: true

# == Schema Information
#
# Table name: score_results
#
#  id                   :uuid             not null, primary key
#  calculation_help     :boolean          default(FALSE), not null
#  calculation_method   :integer          default("default"), not null
#  date                 :date
#  forced_name          :string(100)
#  group_assessment     :boolean          default(FALSE), not null
#  group_run_count      :integer          default(8), not null
#  group_score_count    :integer          default(6), not null
#  image_key            :string(10)
#  multi_result_method  :integer          default("disabled"), not null
#  person_tags_excluded :string           default([]), is an Array
#  person_tags_included :string           default([]), is an Array
#  team_tags_excluded   :string           default([]), is an Array
#  team_tags_included   :string           default([]), is an Array
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  assessment_id        :uuid
#  competition_id       :uuid             not null
#
# Indexes
#
#  index_score_results_on_assessment_id   (assessment_id)
#  index_score_results_on_competition_id  (competition_id)
#
# Foreign Keys
#
#  fk_rails_...  (assessment_id => assessments.id)
#  fk_rails_...  (competition_id => competitions.id)
#
require 'rails_helper'

RSpec.describe Score::Result do
  let(:competition) { create(:competition) }
  let(:band) { create(:band, competition:, person_tags: tags) }
  let(:assessment) { create(:assessment, competition:, band:) }
  let(:result) { create(:score_result, person_tags_included: tags, competition:, assessment:) }
  let(:tags) { [] }

  describe '.rows' do
    let(:person1) { create(:person, :generated, competition:, band:, tags:) }
    let(:person2) { create(:person, :generated, competition:, band:) }
    let(:person3) { create(:person, :generated, competition:, band:) }
    let(:person4) { create(:person, :generated, competition:, band:) }
    let(:person5) { create(:person, :generated, competition:, band:) }

    context 'when entries given' do
      let(:time4) { 2040 }
      let!(:list1) do
        create_score_list(result, person1 => 1912, person2 => 2020, person3 => 2040, person4 => nil, person5 => 2111)
      end
      let!(:list2) do
        create_score_list(result, person1 => nil, person2 => 1911, person3 => 1912, person4 => time4, person5 => 2233)
      end

      it 'return results in correct order' do
        rows = result.rows
        expect(rows.count).to eq 5

        expect(rows[0].result_entry_from(list1).time).to eq 2020
        expect(rows[0].result_entry_from(list2).time).to eq 1911
        expect(rows[0].best_result_entry.time).to eq 1911

        expect(rows[1].result_entry_from(list1).time).to eq 2040
        expect(rows[1].result_entry_from(list2).time).to eq 1912
        expect(rows[1].best_result_entry.time).to eq 1912

        expect(rows[2].result_entry_from(list1).time).to eq 1912
        expect(rows[2].result_entry_from(list2).time).to be_nil
        expect(rows[2].best_result_entry.time).to eq 1912

        expect(rows[3].result_entry_from(list1).time).to be_nil
        expect(rows[3].result_entry_from(list2).time).to eq 2040
        expect(rows[3].best_result_entry.time).to eq 2040

        expect(rows[4].result_entry_from(list1).time).to eq 2111
        expect(rows[4].result_entry_from(list2).time).to eq 2233
        expect(rows[4].best_result_entry.time).to eq 2111
      end

      context 'when calculation_method is sum_of_two' do
        before { result.update!(calculation_method: 'sum_of_two') }

        it 'return results in other order' do
          rows = result.rows
          expect(rows.count).to eq 5

          expect(rows[0].result_entry_from(list1).time).to eq 2020
          expect(rows[0].result_entry_from(list2).time).to eq 1911
          expect(rows[0].best_result_entry.time).to eq 3931

          expect(rows[1].result_entry_from(list1).time).to eq 2040
          expect(rows[1].result_entry_from(list2).time).to eq 1912
          expect(rows[1].best_result_entry.time).to eq 3952

          expect(rows[2].result_entry_from(list1).time).to eq 2111
          expect(rows[2].result_entry_from(list2).time).to eq 2233
          expect(rows[2].best_result_entry.time).to eq 4344

          expect(rows[3].result_entry_from(list1).time).to eq 1912
          expect(rows[3].result_entry_from(list2).time).to be_nil
          expect(rows[3].best_result_entry.time).to eq 1912

          expect(rows[4].result_entry_from(list1).time).to be_nil
          expect(rows[4].result_entry_from(list2).time).to eq 2040
          expect(rows[4].best_result_entry.time).to eq 2040
        end
      end

      describe 'supports Certificates::StorageSupport' do
        let(:time4) { nil }

        it 'supports all keys' do
          rows = result.rows

          [

            {
              team_name: '',
              person_name: person2.full_name,
              person_bib_number: '',
              time_long: '19,11 Sekunden',
              time_very_long: 'mit einer Zeit von 19,11 Sekunden',
              time_other_long: 'belegte mit einer Zeit von 19,11 Sekunden',
              time_short: '19,11 s',
              time_without_seconds: '19,11',
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
              team_name: '',
              person_name: person3.full_name,
              person_bib_number: '',
              time_long: '19,12 Sekunden',
              time_short: '19,12 s',
              time_without_seconds: '19,12',
              time_very_long: 'mit einer Zeit von 19,12 Sekunden',
              time_other_long: 'belegte mit einer Zeit von 19,12 Sekunden',
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
              team_name: '',
              person_name: person1.full_name,
              person_bib_number: '',
              time_long: '19,12 Sekunden',
              time_short: '19,12 s',
              time_without_seconds: '19,12',
              time_very_long: 'mit einer Zeit von 19,12 Sekunden',
              time_other_long: 'belegte mit einer Zeit von 19,12 Sekunden',
              rank: '3.',
              rank_with_rank: '3. Platz',
              rank_with_rank2: 'den 3. Platz',
              rank_without_dot: '3',
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
              team_name: '',
              person_name: person5.full_name,
              person_bib_number: '',
              time_long: '21,11 Sekunden',
              time_short: '21,11 s',
              time_without_seconds: '21,11',
              time_very_long: 'mit einer Zeit von 21,11 Sekunden',
              time_other_long: 'belegte mit einer Zeit von 21,11 Sekunden',
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
              team_name: '',
              person_name: person4.full_name,
              person_bib_number: '',
              time_long: 'Ungültig',
              time_short: 'o.W.',
              time_without_seconds: '-',
              time_very_long: 'mit einer ungültigen Zeit',
              time_other_long: 'belegte mit einer ungültigen Zeit',
              rank: '5.',
              rank_with_rank: '5. Platz',
              rank_with_rank2: 'den 5. Platz',
              rank_without_dot: '5',
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

      context 'when person tags present' do
        let(:tags) { ['U20'] }

        it 'supports all keys' do
          rows = result.rows
          expect(rows.count).to eq 1

          [
            {
              team_name: '',
              person_name: person1.full_name,
              person_bib_number: '',
              time_long: '19,12 Sekunden',
              time_short: '19,12 s',
              time_without_seconds: '19,12',
              time_very_long: 'mit einer Zeit von 19,12 Sekunden',
              time_other_long: 'belegte mit einer Zeit von 19,12 Sekunden',
              rank: '1.',
              rank_with_rank: '1. Platz',
              rank_with_rank2: 'den 1. Platz',
              rank_without_dot: '1',
              assessment: 'Hakenleitersteigen',
              assessment_with_gender: 'Hakenleitersteigen - Frauen',
              gender: 'Frauen',
              result_name: 'Hakenleitersteigen - Frauen - U20',
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

    context 'when result is a single_discipline' do
      context 'when entries all invalid' do
        let!(:list1) { create_score_list(result, person1 => nil, person2 => nil) }
        let!(:list2) { create_score_list(result, person1 => nil, person2 => nil) }

        it 'get the same place' do
          rows = result.rows
          expect(rows.first <=> rows.second).to eq 0

          # starting time is ignored
          list1.update!(starting_time_string: '00:00')
          list2.update!(starting_time_string: '01:00')

          rows = described_class.find(result.id).rows
          expect(rows.first <=> rows.second).to eq 0
        end
      end

      context 'when first entries similar' do
        let!(:list1) { create_score_list(result, person1 => 1912, person2 => 1912) }
        let!(:list2) { create_score_list(result, person2 => 1913) }

        it 'return results in correct order' do
          rows = result.rows
          expect(rows.count).to eq 2

          expect(rows.first.entity).to eq person2
          expect(rows.first.result_entry_from(list1).time).to eq 1912
          expect(rows.first.result_entry_from(list2).time).to eq 1913

          expect(rows.second.entity).to eq person1
          expect(rows.second.result_entry_from(list1).time).to eq 1912
          expect(rows.second.result_entry_from(list2)).to be_nil
        end
      end

      context 'when all entries similar' do
        let!(:list1) { create_score_list(result, person1 => 1912, person2 => 1913) }
        let!(:list2) { create_score_list(result, person1 => 1913, person2 => 1912) }

        it 'return results in correct order' do
          rows = result.rows
          expect(rows.count).to eq 2
          expect(rows.first <=> rows.second).to eq 0

          # starting time is ignored
          list1.update!(starting_time_string: '00:00')
          list2.update!(starting_time_string: '01:00')

          rows = described_class.find(result.id).rows
          expect(rows.first <=> rows.second).to eq 0
        end
      end
    end

    context 'when result is a group_discipline' do
      let(:la) { create(:discipline, :la, competition:) }
      let(:assessment) { create(:assessment, competition:, band:, discipline: la) }
      let(:result) { create(:score_result, competition:, assessment:) }
      let(:team1) { create(:team, competition:, band:) }
      let(:team2) { create(:team, competition:, band:) }

      context 'when entries all invalid' do
        let!(:list1) { create_score_list(result, team1 => nil, team2 => nil) }
        let!(:list2) { create_score_list(result, team1 => nil, team2 => nil) }

        it 'get the same place' do
          rows = result.rows
          expect(rows.first <=> rows.second).to eq 0
          expect(rows.first.place).to eq 2
          expect(rows.second.place).to eq 2

          # starting time is ignored
          list1.update!(starting_time_string: '00:00')
          list2.update!(starting_time_string: '01:00')

          rows = described_class.find(result.id).rows
          expect(rows.first <=> rows.second).to eq 0
          expect(rows.first.place).to eq 2
          expect(rows.second.place).to eq 2
        end
      end

      context 'when first entries similar' do
        let!(:list1) { create_score_list(result, team1 => 1912, team2 => 1912) }
        let!(:list2) { create_score_list(result, team2 => 1913) }

        it 'return results in correct order' do
          rows = result.rows
          expect(rows.count).to eq 2

          expect(rows.first.entity).to eq team2
          expect(rows.first.place).to eq 1
          expect(rows.first.result_entry_from(list1).time).to eq 1912
          expect(rows.first.result_entry_from(list2).time).to eq 1913

          expect(rows.second.entity).to eq team1
          expect(rows.second.result_entry_from(list1).time).to eq 1912
          expect(rows.second.result_entry_from(list2)).to be_nil
          expect(rows.second.place).to eq 2
        end
      end

      context 'when all entries similar' do
        let!(:list1) { create_score_list(result, team1 => 1912, team2 => 1913) }
        let!(:list2) { create_score_list(result, team1 => 1913, team2 => 1912) }

        it 'return results in correct order' do
          rows = result.rows
          expect(rows.count).to eq 2
          expect(rows.first <=> rows.second).to eq 0
          expect(rows.first.place).to eq 1
          expect(rows.second.place).to eq 1

          # starting time is used
          list1.update!(starting_time_string: '00:00')
          list2.update!(starting_time_string: '01:00')

          rows = described_class.find(result.id).rows
          expect(rows.first <=> rows.second).to eq(-1)

          expect(rows.first.entity).to eq team1
          expect(rows.first.place).to eq 1
          expect(rows.first.result_entry_from(list1).time).to eq 1912
          expect(rows.first.result_entry_from(list2).time).to eq 1913

          expect(rows.second.entity).to eq team2
          expect(rows.second.place).to eq 2
          expect(rows.second.result_entry_from(list1).time).to eq 1913
          expect(rows.second.result_entry_from(list2).time).to eq 1912
        end
      end

      context 'when all entries similar in same list' do
        let!(:list1) { create_score_list(result, team1 => 1912, team2 => 1912) }

        it 'return results in correct order' do
          rows = result.rows
          expect(rows.count).to eq 2
          expect(rows.first <=> rows.second).to eq(-1)

          expect(rows.first.entity).to eq team1
          expect(rows.first.place).to eq 1
          expect(rows.first.result_entry_from(list1).time).to eq 1912

          expect(rows.second.entity).to eq team2
          expect(rows.second.place).to eq 2
          expect(rows.second.result_entry_from(list1).time).to eq 1912
        end
      end
    end

    context 'when result is a fire relay' do
      let(:fs) { create(:discipline, :fs, competition:) }
      let(:assessment) { create(:assessment, competition:, band:, discipline: fs) }
      let(:result) { create(:score_result, competition:, assessment:) }
      let(:team1) { create(:team, competition:, band:) }
      let(:team1_a) { TeamRelay.create!(team: team1, number: 1) }
      let(:team1_b) { TeamRelay.create!(team: team1, number: 2) }
      let(:team2) { create(:team, competition:, band:) }
      let(:team2_a) { TeamRelay.create!(team: team2, number: 1) }
      let(:team2_b) { TeamRelay.create!(team: team2, number: 2) }

      context 'when entries all invalid' do
        let!(:list1) { create_score_list(result, team1_a => nil, team1_b => nil, team2_a => nil, team2_b => nil) }
        let!(:list2) { create_score_list(result, team1_a => nil, team1_b => nil, team2_a => nil, team2_b => nil) }

        it 'get the same place' do
          rows = result.rows
          expect(rows.first <=> rows.second).to eq 0
          expect(rows.first.place).to eq 4
          expect(rows.second.place).to eq 4

          # starting time is ignored
          list1.update!(starting_time_string: '00:00')
          list2.update!(starting_time_string: '01:00')

          rows = described_class.find(result.id).rows
          expect(rows.first <=> rows.second).to eq 0
          expect(rows.first.place).to eq 4
          expect(rows.second.place).to eq 4
        end
      end

      context 'when first entries similar' do
        let!(:list1) { create_score_list(result, team1_a => 1, team1_b => 2, team2_a => 3, team2_b => 4) }
        let!(:list2) { create_score_list(result, team1_a => nil, team1_b => 2, team2_a => 2, team2_b => nil) }

        it 'return results in correct order' do
          rows = result.rows
          expect(rows.count).to eq 4

          expect(rows[0].entity).to eq team1_a
          expect(rows[0].place).to eq 1
          expect(rows[0].result_entry_from(list1).time).to eq 1
          expect(rows[0].result_entry_from(list2).time).to be_nil

          expect(rows[1].entity).to eq team1_b
          expect(rows[1].place).to eq 2
          expect(rows[1].result_entry_from(list1).time).to eq 2
          expect(rows[1].result_entry_from(list2).time).to eq 2

          expect(rows[2].entity).to eq team2_a
          expect(rows[2].place).to eq 3
          expect(rows[2].result_entry_from(list1).time).to eq 3
          expect(rows[2].result_entry_from(list2).time).to eq 2

          expect(rows[3].entity).to eq team2_b
          expect(rows[3].place).to eq 4
          expect(rows[3].result_entry_from(list1).time).to eq 4
          expect(rows[3].result_entry_from(list2).time).to be_nil
        end
      end

      context 'when all entries similar' do
        let!(:list1) { create_score_list(result, team1_a => 1, team1_b => nil) }
        let!(:list2) { create_score_list(result, team1_a => nil, team1_b => 1) }

        it 'return results in correct order' do
          rows = result.rows
          expect(rows.count).to eq 2
          expect(rows.first <=> rows.second).to eq 0
          expect(rows.first.place).to eq 1
          expect(rows.second.place).to eq 1

          # starting time is used
          list1.update!(starting_time_string: '00:00')
          list2.update!(starting_time_string: '01:00')

          rows = described_class.find(result.id).rows
          expect(rows.first <=> rows.second).to eq(-1)

          expect(rows.first.entity).to eq team1_a
          expect(rows.first.place).to eq 1
          expect(rows.first.result_entry_from(list1).time).to eq 1
          expect(rows.first.result_entry_from(list2).time).to be_nil

          expect(rows.second.entity).to eq team1_b
          expect(rows.second.place).to eq 2
          expect(rows.second.result_entry_from(list1).time).to be_nil
          expect(rows.second.result_entry_from(list2).time).to eq 1
        end
      end

      context 'when all entries similar in same list' do
        let!(:list1) { create_score_list(result, team1_a => 1, team1_b => 1) }

        it 'return results in correct order' do
          rows = result.rows
          expect(rows.count).to eq 2
          expect(rows.first <=> rows.second).to eq(-1)

          expect(rows.first.entity).to eq team1_a
          expect(rows.first.place).to eq 1
          expect(rows.first.result_entry_from(list1).time).to eq 1

          expect(rows.second.entity).to eq team1_b
          expect(rows.second.place).to eq 2
          expect(rows.second.result_entry_from(list1).time).to eq 1
        end
      end
    end
  end
end
