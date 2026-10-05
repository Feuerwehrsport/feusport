# frozen_string_literal: true

# == Schema Information
#
# Table name: assessment_requests
#
#  id                      :uuid             not null, primary key
#  assessment_type         :integer          default("group_competitor"), not null
#  competitor_order        :integer          default(0), not null
#  entity_type             :string(100)      not null
#  group_competitor_order  :integer          default(0), not null
#  relay_count             :integer          default(1), not null
#  single_competitor_order :integer          default(0), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  assessment_id           :uuid             not null
#  entity_id               :uuid             not null
#
# Indexes
#
#  index_assessment_requests_on_assessment_id  (assessment_id)
#
# Foreign Keys
#
#  fk_rails_...  (assessment_id => assessments.id)
#
require 'rails_helper'

RSpec.describe AssessmentRequest do
  let(:competition) { create(:competition) }
  let(:band) { create(:band, competition:) }

  describe '#type' do
    let(:gs) { create(:discipline, :gs, competition:) }
    let(:gs_assessment) { create(:assessment, competition:, band:, discipline: gs) }

    it 'returns gs names for gs competitors' do
      request = described_class.new(assessment: gs_assessment, assessment_type: :competitor, competitor_order: 2)
      expect(request.type).to eq '3 C-Schlauch'
    end

    it 'returns 0 without assessment type' do
      expect(described_class.new(assessment_type: nil).type).to eq 0
    end
  end

  describe 'competitor order' do
    let(:hl) { create(:discipline, :hl, competition:) }
    let(:assessment) { create(:assessment, competition:, band:, discipline: hl) }
    let(:team) { create(:team, competition:, band:) }
    let(:people) { create_list(:person, 3, :generated, competition:, band:, team:) }

    it 'assigns next free group competitor order' do
      create(:assessment_request, assessment:, entity: people[0], assessment_type: :group_competitor,
                                  group_competitor_order: 2)

      request = described_class.new(assessment:, entity: people[1], assessment_type: :group_competitor)
      expect(request.group_competitor_order).to eq 1
      request.save!

      request = described_class.new(assessment:, entity: people[2], assessment_type: :group_competitor)
      expect(request.group_competitor_order).to eq 3
    end
  end
end
