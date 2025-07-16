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

RSpec.describe 'Score::CompetitionResult with same LA' do
  let!(:competition) { create(:competition) }
  let!(:band) { create(:band, :female, competition:) }

  let!(:la) { create(:discipline, :la, competition:) }
  let!(:gs) { create(:discipline, :gs, competition:) }

  let!(:assessment_la) { create(:assessment, competition:, discipline: la, band:) }
  let!(:assessment_gs) { create(:assessment, competition:, discipline: gs, band:) }

  let!(:result_la) { create(:score_result, competition:, assessment: assessment_la) }
  let!(:result_gs) { create(:score_result, competition:, assessment: assessment_gs) }

  let!(:team1) { create(:team, competition:, band:) }
  let!(:team2) { create(:team, competition:, band:) }
  let!(:team3) { create(:team, competition:, band:) }
  let!(:team4) { create(:team, competition:, band:) }

  let!(:list_la) do
    create_score_list(result_la,
                      team1 => 2200, team2 => 2200, team3 => nil, team4 => nil)
  end
  let!(:list_gs) do
    create_score_list(result_gs,
                      team2 => 2200, team1 => 2200, team3 => nil, team4 => nil)
  end
  let!(:competition_result) do
    create(:score_competition_result, competition:, results: [result_la, result_gs], result_type:)
  end
  let(:result_type) { 'places_to_points' }

  it 'calculates correct results' do
    rows = competition_result.rows
    expect(rows[0].points).to eq 3
    expect(rows[0].place).to eq 1
    expect(rows[0].team).to be_in([team1, team2])
    expect(rows[0].assessment_result_from(result_la).points).to eq 1
    expect(rows[0].assessment_result_from(result_gs).points).to eq 2

    expect(rows[1].points).to eq 3
    expect(rows[1].place).to eq 1
    expect(rows[1].team).to be_in([team1, team2])
    expect(rows[1].assessment_result_from(result_la).points).to eq 2
    expect(rows[1].assessment_result_from(result_gs).points).to eq 1

    expect(rows[2].points).to eq 8
    expect(rows[2].place).to eq 3
    expect(rows[2].team).to be_in([team3, team4])
    expect(rows[2].assessment_result_from(result_la).points).to eq 4
    expect(rows[2].assessment_result_from(result_gs).points).to eq 4

    expect(rows[3].points).to eq 8
    expect(rows[3].place).to eq 3
    expect(rows[3].team).to be_in([team3, team4])
    expect(rows[3].assessment_result_from(result_la).points).to eq 4
    expect(rows[3].assessment_result_from(result_gs).points).to eq 4
  end

  context 'when dcup' do
    let(:result_type) { 'dcup' }

    it 'calculates correct results' do
      rows = competition_result.rows
      expect(rows[0].points).to eq 19
      expect(rows[0].place).to eq 1
      expect(rows[0].team).to be_in([team1, team2])
      expect(rows[0].assessment_result_from(result_la).points).to eq 10
      expect(rows[0].assessment_result_from(result_gs).points).to eq 9

      expect(rows[1].points).to eq 19
      expect(rows[1].place).to eq 1
      expect(rows[1].team).to be_in([team1, team2])
      expect(rows[1].assessment_result_from(result_la).points).to eq 9
      expect(rows[1].assessment_result_from(result_gs).points).to eq 10

      expect(rows[2].points).to eq 14
      expect(rows[2].place).to eq 3
      expect(rows[2].team).to be_in([team3, team4])
      expect(rows[2].assessment_result_from(result_la).points).to eq 7
      expect(rows[2].assessment_result_from(result_gs).points).to eq 7

      expect(rows[3].points).to eq 14
      expect(rows[3].place).to eq 3
      expect(rows[3].team).to be_in([team3, team4])
      expect(rows[3].assessment_result_from(result_la).points).to eq 7
      expect(rows[3].assessment_result_from(result_gs).points).to eq 7
    end
  end
end
