# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Series::TeamAssessment do
  let(:round) { create(:series_round, :with_team_config, :with_person_config) }

  it 'returns matching config' do
    assessment = create(:series_team_assessment, round:)
    expect(assessment.config.key).to eq 'male-la'
    expect(assessment.config.name).to eq 'LA-Männer'
  end
end
