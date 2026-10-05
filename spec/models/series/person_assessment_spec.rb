# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Series::PersonAssessment do
  let(:round) { create(:series_round, :with_team_config, :with_person_config) }

  it 'returns matching config' do
    assessment = create(:series_person_assessment, round:)
    expect(assessment.config.key).to eq 'male-hl'
    expect(assessment.name).to eq 'HL-Männer'
  end
end
