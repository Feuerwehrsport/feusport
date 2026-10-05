# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'competitions/series/person_points_corrections' do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }
  let(:round) { create(:series_round, :with_team_config, :with_person_config) }
  let(:person_round_key) { "#{round.id}-male-hl" }
  let!(:result) { create(:score_result, competition:, series_person_round_keys: [person_round_key]) }
  let(:fss_person) { create(:fire_sport_statistics_person) }
  let(:base_path) { competition_nested('series/person_points_corrections') }
  let(:correction) { Series::PersonPointsCorrection.first }

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
    post base_path, params: { series_person_points_correction: { round_key: person_round_key, points_correction: '' } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(flash[:alert]).to eq :check_errors
    expect(Series::PersonPointsCorrection.count).to eq 0

    # POST create
    post base_path, params: { series_person_points_correction: {
      round_key: person_round_key, person_id: fss_person.id, points_correction: -3, points_correction_hint: 'Strafe'
    } }
    expect(response).to redirect_to(base_path)
    expect(correction.points_correction).to eq(-3)
    expect(correction.person_id).to eq fss_person.id

    get "#{base_path}/#{correction.id}/edit"
    expect(response).to have_http_status(:success)

    # PATCH update with failure
    patch "#{base_path}/#{correction.id}", params: { series_person_points_correction: { points_correction_hint: '' } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(flash[:alert]).to eq :check_errors
    expect(correction.reload.points_correction_hint).to eq 'Strafe'

    # PATCH update
    patch "#{base_path}/#{correction.id}", params: { series_person_points_correction: { points_correction: 2 } }
    expect(response).to redirect_to(base_path)
    expect(correction.reload.points_correction).to eq 2

    # DELETE destroy
    delete "#{base_path}/#{correction.id}"
    expect(response).to redirect_to(base_path)
    expect(flash[:notice]).to eq :deleted
    expect(Series::PersonPointsCorrection.count).to eq 0
  end
end
