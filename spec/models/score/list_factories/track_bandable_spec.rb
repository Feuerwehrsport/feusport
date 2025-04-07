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

RSpec.describe Score::ListFactories::TrackBandable do
  let(:competition) { create(:competition) }
  let(:female) { create(:band, :female, competition:) }
  let(:male) { create(:band, :male, competition:) }

  let(:discipline) { create(:discipline, :hl, competition:) }
  let(:assessment_female) { create(:assessment, competition:, discipline:, band: female) }
  let(:assessment_male) { create(:assessment, competition:, discipline:, band: male) }
  let(:result_female) { create(:score_result, competition:, assessment: assessment_female) }
  let(:result_male) { create(:score_result, competition:, assessment: assessment_male) }

  let(:selected_band) { nil }
  let(:track) { 3 }
  let(:factory) do
    described_class.new(
      competition:, session_id: '1',
      discipline:, assessments: [assessment_female, assessment_male], name: 'long name',
      shortcut: 'short', track_count: 2, track:, results: [result_female, result_male], bands: [selected_band].compact
    )
  end

  describe 'validation' do
    it 'validates track and gender' do
      expect(factory).not_to be_valid
      expect(factory.errors.attribute_names).to include(:track)
      expect(factory.errors.attribute_names).to include(:bands)
    end

    context 'with correct values' do
      let(:track) { 1 }
      let(:selected_band) { female }

      it 'is valid' do
        expect(factory).to be_valid
      end
    end
  end

  context 'when assessment requests present' do
    let(:track) { 1 }
    let(:selected_band) { female }

    let(:team1) { create(:team, competition:, band: male) }
    let(:person1_team1) { create(:person, :generated, competition:, team: team1, band: male, last_name: 'Male1') }
    let(:person2_team1) { create(:person, :generated, competition:, team: team1, band: male, last_name: 'Male1') }
    let(:person3_team1) do
      create(:person, :generated, competition:, team: team1, band: male, last_name: 'Male1-Single')
    end

    let(:team2) { create(:team, competition:, band: male) }
    let(:person1_team2) { create(:person, :generated, competition:, team: team2, band: male, last_name: 'Male2') }

    let(:team3) { create(:team, competition:, band: female) }
    let(:person1_team3) { create(:person, :generated, competition:, team: team3, band: female) }
    let(:person2_team3) { create(:person, :generated, competition:, team: team3, band: female) }

    before do
      create_assessment_request(person1_team1, assessment_male, 1)
      create_assessment_request(person2_team1, assessment_male, 2)
      create_assessment_request(person3_team1, assessment_male, 0, 1, :single_competitor)

      create_assessment_request(person1_team2, assessment_male, 1)

      create_assessment_request(person1_team3, assessment_female, 1)
      create_assessment_request(person2_team3, assessment_female, 2)
    end

    describe '#perform_rows' do
      it 'returns requests seperated by team and group competitor order' do
        requests = factory.send(:perform_rows)
        expect(requests.count).to eq 6

        requests_team1 = requests.select { |r| r.entity.team == team1 }
        expect(requests_team1.map(&:entity)).to eq [
          person3_team1,
          person1_team1,
          person2_team1,
        ]

        requests_team2 = requests.select { |r| r.entity.team == team2 }
        expect(requests_team2.map(&:entity)).to eq [
          person1_team2,
        ]

        requests_team3 = requests.select { |r| r.entity.team == team3 }
        expect(requests_team3.map(&:entity)).to eq [
          person1_team3,
          person2_team3,
        ]
      end
    end

    describe '#perform' do
      it 'creates list entries' do
        factory.send(:perform)
        expect(factory.list.entries.count).to eq 6
        expect(factory.list.entries.where(track: 1).order(:run).map(&:entity)).to eq [
          person1_team3,
          person2_team3,
        ]
        males = factory.list.entries.where(track: 2).order(:run).map(&:entity)
        if males.first == person1_team2
          expect(males).to eq [
            person1_team2,
            person3_team1,
            person1_team1,
            person2_team1,
          ]
        else
          expect(males).to eq [
            person3_team1,
            person1_team2,
            person1_team1,
            person2_team1,
          ]
        end
      end
    end
  end
end
