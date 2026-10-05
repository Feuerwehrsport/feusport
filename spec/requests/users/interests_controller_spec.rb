# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'users/interests' do
  let(:user) { create(:user) }
  let!(:feature) { create(:feature) }

  it 'requires login' do
    get '/users/interests/edit'
    expect_access_denied
  end

  it 'edits interests' do
    sign_in user

    get '/users/interests/edit'
    expect(response).to have_http_status(:success)
    expect(response.body).to include('Benutzerkonto bearbeiten')

    patch '/users/interests', params: { user: { distance: 0 } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(flash[:alert]).to eq :check_errors

    patch '/users/interests', params: { user: { distance: 50, lat: '54.08', lng: '12.13', feature_ids: [feature.id] } }
    expect(response).to redirect_to('/')
    expect(user.reload.distance).to eq 50
    expect(user.features).to eq [feature]
  end
end
