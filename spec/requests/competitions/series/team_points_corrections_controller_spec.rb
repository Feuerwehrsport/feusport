# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'competitions/series/team_points_corrections' do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }
  let(:round) { create(:series_round, :with_team_config, :with_person_config) }
  let(:team_round_key) { "#{round.id}-male-la" }
  let!(:result) { create(:score_result, competition:, series_team_round_keys: [team_round_key]) }
  let(:fss_team) { create(:fire_sport_statistics_team) }
  let(:base_path) { competition_nested('series/team_points_corrections') }
  let(:correction) { Series::TeamPointsCorrection.first }

  it 'requires login' do
    get base_path
    expect_access_denied
  end

  it 'uses CRUD' do
    sign_in user

    get base_path
    expect(response).to have_http_status(:success)

    get "#{base_path}/new"
    expect(response).to have_http_status(:success)

    # POST create with failure
    post base_path, params: { series_team_points_correction: { round_key: team_round_key, points_correction: '' } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(flash[:alert]).to eq :check_errors

    # POST create
    post base_path, params: { series_team_points_correction: {
      discipline: 'la', team_number: 1, round_key: team_round_key, team_id: fss_team.id,
      points_correction: -3, points_correction_hint: 'Strafe'
    } }
    expect(response).to redirect_to(base_path)
    expect(correction.points_correction).to eq(-3)
    expect(correction.team_id).to eq fss_team.id

    get "#{base_path}/#{correction.id}/edit"
    expect(response).to have_http_status(:success)

    # PATCH update with failure
    patch "#{base_path}/#{correction.id}", params: { series_team_points_correction: { points_correction: '' } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(flash[:alert]).to eq :check_errors

    # PATCH update
    patch "#{base_path}/#{correction.id}", params: { series_team_points_correction: { points_correction: 2 } }
    expect(response).to redirect_to(base_path)
    expect(correction.reload.points_correction).to eq 2

    # DELETE destroy
    delete "#{base_path}/#{correction.id}"
    expect(response).to redirect_to(base_path)
    expect(flash[:notice]).to eq :deleted
    expect(Series::TeamPointsCorrection.count).to eq 0
  end
end
