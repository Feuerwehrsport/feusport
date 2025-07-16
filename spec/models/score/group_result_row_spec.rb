# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Score::GroupResultRow' do
  let(:competition) { create(:competition) }
  let(:band) { create(:band, :female, competition:) }

  let(:discipline) { create(:discipline, :hl, competition:) }
  let(:assessment) { create(:assessment, competition:, discipline:, band:) }
  let(:result) { create(:score_result, competition:, assessment:, group_run_count: 3, group_score_count: 2) }
  let(:group_result) { result.group_result }

  context 'with teams' do
    let(:team1) { create(:team, competition:, band:) }
    let(:t1_person1) { create(:person, :generated, team: team1, competition:, band:) }
    let(:t1_person2) { create(:person, :generated, team: team1, competition:, band:) }
    let(:t1_person3) { create(:person, :generated, team: team1, competition:, band:) }

    let(:team2) { create(:team, competition:, band:) }
    let(:t2_person1) { create(:person, :generated, team: team2, competition:, band:) }
    let(:t2_person2) { create(:person, :generated, team: team2, competition:, band:) }
    let(:t2_person3) { create(:person, :generated, team: team2, competition:, band:) }

    let(:team3) { create(:team, competition:, band:) }
    let(:t3_person1) { create(:person, :generated, team: team3, competition:, band:) }
    let(:t3_person2) { create(:person, :generated, team: team3, competition:, band:) }
    let(:t3_person3) { create(:person, :generated, team: team3, competition:, band:) }

    context 'when team has too less or few runners' do
      let(:t1_person4) { create(:person, :generated, team: team1, competition:, band:) }

      let!(:list1) do
        create_score_list(result,
                          t1_person1 => 1, t1_person2 => 1, t1_person3 => 1, t1_person4 => 1,
                          t2_person1 => 1,
                          t3_person1 => nil, t3_person2 => nil)
      end

      it 'return invalid results' do
        rows = group_result.rows
        expect(rows.count).to eq 3

        expect(rows[0].entity).to eq team3
        expect(rows[0].result_entry.time).to eq Firesport::INVALID_TIME
        expect(rows[0].place).to eq 1

        expect(rows[1].entity).to be_in([team1, team2])
        expect(rows[1].result_entry.time).to eq Firesport::INVALID_TIME
        expect(rows[1].place).to eq 3

        expect(rows[2].entity).to be_in([team1, team2])
        expect(rows[2].result_entry.time).to eq Firesport::INVALID_TIME
        expect(rows[2].place).to eq 3
      end
    end

    context 'when team same time in one try' do
      let!(:list1) do
        create_score_list(result,
                          t1_person1 => 1, t1_person2 => 2, t1_person3 => 4,
                          t2_person1 => 2, t2_person2 => 1, t2_person3 => 4,
                          t3_person1 => 3, t3_person2 => 1, t3_person3 => 2)
      end
      let!(:list2) do
        create_score_list(result,
                          t1_person1 => 4, t1_person2 => 5, t1_person3 => 4,
                          t2_person1 => 5, t2_person2 => 4, t2_person3 => 3,
                          t3_person1 => 3, t3_person2 => nil, t3_person3 => 3)
      end

      it 'sorts by second try' do
        rows = group_result.rows
        expect(rows.count).to eq 3

        expect(rows[0].entity).to be_in([team1, team2])
        expect(rows[0].result_entry.time).to eq 3
        expect(rows[0].place).to eq 1

        expect(rows[1].entity).to be_in([team1, team2])
        expect(rows[1].result_entry.time).to eq 3
        expect(rows[1].place).to eq 1

        expect(rows[2].entity).to eq team3
        expect(rows[2].result_entry.time).to eq 3
        expect(rows[2].place).to eq 3
      end
    end
  end
end
