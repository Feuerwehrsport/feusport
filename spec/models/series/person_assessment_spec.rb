# frozen_string_literal: true

# == Schema Information
#
# Table name: series_person_assessments
#
#  id         :integer          not null, primary key
#  discipline :string(3)        not null
#  key        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  round_id   :integer          not null
#
# Indexes
#
#  index_series_person_assessments_on_discipline  (discipline)
#  index_series_person_assessments_on_key         (key)
#  index_series_person_assessments_on_round_id    (round_id)
#
require 'rails_helper'

RSpec.describe Series::PersonAssessment do
  let(:round) { create(:series_round, :with_team_config, :with_person_config) }

  it 'returns matching config' do
    assessment = create(:series_person_assessment, round:)
    expect(assessment.config.key).to eq 'male-hl'
    expect(assessment.name).to eq 'HL-Männer'
  end
end
