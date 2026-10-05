# frozen_string_literal: true

# == Schema Information
#
# Table name: assessments
#
#  id             :uuid             not null, primary key
#  forced_name    :string(100)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  band_id        :uuid             not null
#  competition_id :uuid
#  discipline_id  :uuid             not null
#
# Indexes
#
#  index_assessments_on_band_id         (band_id)
#  index_assessments_on_competition_id  (competition_id)
#  index_assessments_on_discipline_id   (discipline_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
require 'rails_helper'

RSpec.describe Assessment do
  let(:competition) { create(:competition) }
  let(:other_competition) { create(:competition) }
  let(:assessment) { create(:assessment, competition:) }
  let(:discipline) { create(:discipline, :hl, competition: other_competition) }

  describe 'auto registration_open_until' do
    it 'changes automaticly' do
      expect(assessment).to be_valid

      assessment.discipline = discipline
      expect(assessment).not_to be_valid
      expect(assessment.errors.attribute_names).to eq [:discipline]
    end
  end

  describe '#name_with_request_count' do
    let(:band) { create(:band, :female, competition:) }

    context 'when discipline is like fire relay' do
      let(:fs) { create(:discipline, :fs, competition:) }
      let!(:fs_assessment) { create(:assessment, competition:, discipline: fs, band:) }

      it 'counts requests per relay' do
        expect(fs_assessment.name_with_request_count).to eq "#{fs_assessment.name} (0 Starter)"

        team1 = create(:team, competition:, band:)
        create(:team, competition:, band:)
        team1.requests.find_by(assessment: fs_assessment).update!(relay_count: 3)

        expect(fs_assessment.name_with_request_count).to eq "#{fs_assessment.name} (2x A, 2x B, 1x C)"
      end
    end

    context 'when discipline is single discipline' do
      let(:hl) { create(:discipline, :hl, competition:) }
      let!(:hl_assessment) { create(:assessment, competition:, discipline: hl, band:) }

      it 'counts person requests only' do
        person = create(:person, competition:, band:)
        create(:assessment_request, assessment: hl_assessment, entity: person)
        create(:assessment_request, assessment: hl_assessment)

        expect(hl_assessment.related_requests.map(&:entity)).to eq [person]
        expect(hl_assessment.name_with_request_count).to eq "#{hl_assessment.name} (1 Starter)"
      end
    end
  end
end
