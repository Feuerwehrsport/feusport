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

RSpec.describe Score::ListFactories::FireRelay do
  let(:competition) { create(:competition) }
  let(:band) { create(:band, :female, competition:) }

  let(:discipline) { create(:discipline, :fs, competition:) }
  let(:assessment) { create(:assessment, competition:, discipline:, band:) }
  let(:before_assessment) { create(:assessment, competition:, discipline:, band:) }
  let(:result) { create(:score_result, competition:, assessment:) }
  let(:before_result) { create(:score_result, competition:, assessment:) }

  let(:list) { create(:score_list, competition:, assessments: [assessment], results: [result]) }

  let(:factory) do
    described_class.new(
      competition:, session_id: '1',
      discipline:, assessments: [assessment], name: 'long name',
      shortcut: 'short', track_count: 2, results: [result],
      before_result:, best_count: 2
    )
  end

  describe '#perform_rows' do
    let!(:assessment_request1) { create(:assessment_request, assessment:, relay_count: 2) }
    let!(:assessment_request2) { create(:assessment_request, assessment:, relay_count: 1) }
    let!(:assessment_request3) { create(:assessment_request, assessment:, relay_count: 2) }

    it 'returns created team relays in request structs' do
      team_relay_requests = factory.send(:perform_rows)
      team_relays = team_relay_requests.map(&:entity)
      expect(team_relays.count).to eq 5
      expect(team_relays.map(&:name)).to eq %w[A A A B B]

      team1_requests = team_relays.select { |tr| tr.team == assessment_request1.entity }
      expect(team1_requests.map(&:name)).to eq %w[A B]

      team2_requests = team_relays.select { |tr| tr.team == assessment_request2.entity }
      expect(team2_requests.map(&:name)).to eq ['A']

      team3_requests = team_relays.select { |tr| tr.team == assessment_request3.entity }
      expect(team3_requests.map(&:name)).to eq %w[A B]
    end
  end
end
