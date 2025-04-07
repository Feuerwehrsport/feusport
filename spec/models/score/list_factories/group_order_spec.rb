# frozen_string_literal: true

# == Schema Information
#
# Table name: score_list_factories
#
#  id                       :uuid             not null, primary key
#  best_count               :integer
#  hidden                   :boolean          default(FALSE), not null
#  name                     :string(100)
#  separate_target_times    :boolean
#  shortcut                 :string(50)
#  show_best_of_run         :boolean          default(FALSE), not null
#  single_competitors_first :boolean          default(TRUE), not null
#  status                   :string(50)
#  track                    :integer
#  track_count              :integer
#  type                     :string           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  before_list_id           :uuid
#  before_result_id         :uuid
#  competition_id           :uuid             not null
#  discipline_id            :uuid             not null
#  session_id               :string(200)      not null
#
# Indexes
#
#  index_score_list_factories_on_before_list_id    (before_list_id)
#  index_score_list_factories_on_before_result_id  (before_result_id)
#  index_score_list_factories_on_competition_id    (competition_id)
#  index_score_list_factories_on_discipline_id     (discipline_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
require 'rails_helper'

RSpec.describe Score::ListFactories::GroupOrder do
  let(:competition) { create(:competition) }
  let(:band) { create(:band, :female, competition:) }

  let(:discipline) { create(:discipline, :hl, competition:) }
  let(:assessment) { create(:assessment, competition:, discipline:, band:) }
  let(:result) { create(:score_result, competition:, assessment:) }

  let(:factory) do
    described_class.new(
      competition:, session_id: '1',
      discipline:, assessments: [assessment], name: 'long name',
      shortcut: 'short', track_count: 2, results: [result],
      single_competitors_first: single_competitor_first
    )
  end

  let(:single_competitor_first) { true }

  describe '#perform_rows' do
    let(:list) { build_stubbed(:score_list, assessments: [assessment]) }

    let(:team1) { create(:team, competition:, band:, lottery_number: 3) }
    let(:person1_team1) { create(:person, :generated, competition:, band:, team: team1) }
    let(:person2_team1) { create(:person, :generated, competition:, band:, team: team1) }
    let(:person3_team1) { create(:person, :generated, competition:, band:, team: team1) }
    let(:person4_team1) { create(:person, :generated, competition:, band:, team: team1) }
    let(:person5_team1) { create(:person, :generated, competition:, band:, team: team1) }
    let(:person6_team1) { create(:person, :generated, competition:, band:, team: team1) }

    let(:team2) { create(:team, competition:, band:, lottery_number: 2) }
    let(:person1_team2) { create(:person, :generated, competition:, band:, team: team2) }
    let(:person2_team2) { create(:person, :generated, competition:, band:, team: team2) }
    let(:person3_team2) { create(:person, :generated, competition:, band:, team: team2) }
    let(:person4_team2) { create(:person, :generated, competition:, band:, team: team2) }

    let(:team3) { create(:team, competition:, band:, lottery_number: 1) }
    let(:person1_team3) { create(:person, :generated, competition:, band:, team: team3) }
    let(:person2_team3) { create(:person, :generated, competition:, band:, team: team3) }
    let(:person3_team3) { create(:person, :generated, competition:, band:, team: team3) }

    before do
      create_assessment_request(person1_team1, assessment, 1)
      create_assessment_request(person2_team1, assessment, 2)
      create_assessment_request(person3_team1, assessment, 3)
      create_assessment_request(person4_team1, assessment, 0, 1, :single_competitor)
      create_assessment_request(person5_team1, assessment, 0, 2, :single_competitor)
      create_assessment_request(person6_team1, assessment, 0, 3, :single_competitor)

      create_assessment_request(person1_team2, assessment, 1)
      create_assessment_request(person2_team2, assessment, 2)
      create_assessment_request(person3_team2, assessment, 3)
      create_assessment_request(person4_team2, assessment, 0, 1, :single_competitor)

      create_assessment_request(person1_team3, assessment, 1)
      create_assessment_request(person2_team3, assessment, 2)
      create_assessment_request(person3_team3, assessment, 3)
    end

    it 'returns requests seperated by team and group competitor order' do
      requests = factory.send(:perform_rows)
      expect(requests.count).to eq 13

      expect(requests[0].entity.team).to eq team1
      expect(requests[1].entity.team).to eq team2
      expect(requests[2].entity.team).to eq team3
      expect(requests[3].entity.team).to eq team1

      requests_team1 = requests.select { |r| r.entity.team == team1 }
      expect(requests_team1.map(&:entity)).to eq [
        person4_team1,
        person5_team1,
        person6_team1,
        person1_team1,
        person2_team1,
        person3_team1,
      ]

      requests_team2 = requests.select { |r| r.entity.team == team2 }
      expect(requests_team2.map(&:entity)).to eq [
        person4_team2,
        person1_team2,
        person2_team2,
        person3_team2,
      ]

      requests_team3 = requests.select { |r| r.entity.team == team3 }
      expect(requests_team3.map(&:entity)).to eq [
        person1_team3,
        person2_team3,
        person3_team3,
      ]
    end

    context 'when single competitors last' do
      let(:single_competitor_first) { false }

      it 'returns requests seperated by team and group competitor order and single competitors last' do
        requests = factory.send(:perform_rows)
        expect(requests.count).to eq 13

        requests_team1 = requests.select { |r| r.entity.team == team1 }
        expect(requests_team1.map(&:entity)).to eq [
          person1_team1,
          person2_team1,
          person3_team1,
          person4_team1,
          person5_team1,
          person6_team1,
        ]

        requests_team2 = requests.select { |r| r.entity.team == team2 }
        expect(requests_team2.map(&:entity)).to eq [
          person1_team2,
          person2_team2,
          person3_team2,
          person4_team2,
        ]

        requests_team3 = requests.select { |r| r.entity.team == team3 }
        expect(requests_team3.map(&:entity)).to eq [
          person1_team3,
          person2_team3,
          person3_team3,
        ]
      end
    end

    context 'when lottery_number given' do
      it 'sorts teams' do
        competition.update!(lottery_numbers: true)

        requests = factory.send(:perform_rows)
        expect(requests.count).to eq 13
        expect(requests[0].entity.team).to eq team3
        expect(requests[1].entity.team).to eq team2
        expect(requests[2].entity.team).to eq team1
        expect(requests[3].entity.team).to eq team3
      end
    end
  end
end
