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
        expect(rows[0].rank).to eq 1

        expect(rows[1].entity).to be_in([team1, team2])
        expect(rows[1].result_entry.time).to eq Firesport::INVALID_TIME
        expect(rows[1].rank).to eq 3

        expect(rows[2].entity).to be_in([team1, team2])
        expect(rows[2].result_entry.time).to eq Firesport::INVALID_TIME
        expect(rows[2].rank).to eq 3
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
        expect(rows[0].rank).to eq 1

        expect(rows[1].entity).to be_in([team1, team2])
        expect(rows[1].result_entry.time).to eq 3
        expect(rows[1].rank).to eq 1

        expect(rows[2].entity).to eq team3
        expect(rows[2].result_entry.time).to eq 3
        expect(rows[2].rank).to eq 3
      end
    end
  end

  context 'with incomplete teams rated' do
    let(:result) do
      create(:score_result, competition:, assessment:, group_run_count: 4, group_score_count: 3,
                            group_assessment: true, group_incomplete_rated: true)
    end

    let(:complete) { create(:team, competition:, band:) }
    let(:two_starters) { create(:team, competition:, band:) }
    let(:one_starter) { create(:team, competition:, band:) }
    let(:two_valid) { create(:team, competition:, band:) }
    let(:no_valid) { create(:team, competition:, band:) }
    let(:too_many) { create(:team, competition:, band:) }
    let!(:list) do
      c = people(complete, 3)
      t = people(two_starters, 2)
      o = people(one_starter, 1)
      v = people(two_valid, 3)
      n = people(no_valid, 2)
      m = people(too_many, 5)
      create_score_list(result,
                        c[0] => 10, c[1] => 10, c[2] => 10,
                        t[0] => 12, t[1] => 12,
                        o[0] => 5,
                        v[0] => 10, v[1] => 10, v[2] => nil,
                        n[0] => nil, n[1] => nil,
                        m[0] => 1, m[1] => 1, m[2] => 1, m[3] => 1, m[4] => 1)
    end

    def people(team, count)
      Array.new(count) { create(:person, :generated, team:, competition:, band:) }
    end

    it 'places teams by count of valid times and then by time' do
      rows = group_result.rows
      expect(rows.map(&:entity)).to eq [complete, two_valid, two_starters, one_starter, no_valid, too_many]
      expect(rows.map(&:rank)).to eq [1, 2, 3, 4, 5, 6]

      expect(rows[0].result_entry.time).to eq 30
      expect(rows[1].result_entry.time).to eq Firesport::INVALID_TIME
      expect(rows.map(&:competition_result_valid?)).to eq [true, true, true, true, true, false]
    end

    it 'exports validity for statistics' do
      group_rows = Exports::Json::Score::Result.new(result).to_hash[:group_rows]
      valid_index = group_rows.first.index('competition_result_valid')
      expect(group_rows.drop(1).pluck(valid_index)).to eq [true, true, true, true, true, false]
    end

    it 'keeps old behaviour without option' do
      result.update!(group_incomplete_rated: false)
      rows = Score::Result.find(result.id).group_result.rows
      expect(rows.map(&:competition_result_valid?).count(true)).to eq 2
      expect(rows.first.entity).to eq complete
      expect(rows.first.rank).to eq 1
      expect(rows.second.entity).to eq two_valid
    end
  end
end
