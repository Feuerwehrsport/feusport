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
end
