# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Competitions::ApiAccessesController do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }

  def nested(path = 'api_accesses')
    "/#{competition.year}/#{competition.slug}/#{path}"
  end

  context 'when signed in' do
    before { sign_in user }

    it 'creates an access and shows its code' do
      get nested('api_accesses/new')
      expect(response).to have_http_status(:ok)

      post nested, params: { api_access: { name: '' } }
      expect(response).to have_http_status(:unprocessable_content)

      expect { post nested, params: { api_access: { name: 'Uhr 1' } } }.to change(ApiAccess, :count).by(1)
      expect(response).to redirect_to(nested('accesses'))
      follow_redirect!
      expect(response.body).to include('Uhr 1', ApiAccess.first.pairing_code)
    end

    it 'shows expired and paired accesses' do
      access = ApiAccess.create!(competition:, name: 'Uhr 1')
      travel_to(16.minutes.from_now) do
        get nested('accesses')
        expect(response.body).to include('Code abgelaufen')
      end

      access.pair('Gerät X')
      access.record_usage
      get nested('accesses')
      expect(response.body).to include('Verbunden (Gerät X)', 'Zuletzt aktiv')
    end

    it 'updates and restricts an access, also next to other paired accesses' do
      access = ApiAccess.create!(competition:, name: 'Uhr 1')
      access.pair(nil)
      other = ApiAccess.create!(competition:, name: 'Uhr 2')
      other.pair(nil)
      list = create(:score_list, competition:, name: 'Liste A')

      get nested("api_accesses/#{access.id}/edit")
      expect(response).to have_http_status(:ok)

      patch nested("api_accesses/#{access.id}"), params: { api_access: { permission: 'selected_results',
                                                                         score_list_ids: [''] } }
      expect(response).to have_http_status(:unprocessable_content)

      patch nested("api_accesses/#{access.id}"), params: { api_access: { permission: 'selected_results',
                                                                         score_list_ids: [list.id] } }
      expect(response).to redirect_to(nested('accesses'))
      follow_redirect!
      expect(response.body).to include('Liste A')
      expect(access.reload.score_list_ids).to eq [list.id]
    end

    it 'regenerates a code without ending the running token' do
      access = ApiAccess.create!(competition:, name: 'Uhr 1')
      access.pair(nil)
      token = access.token

      post nested("api_accesses/#{access.id}/regenerate_code")
      expect(response).to redirect_to(nested('accesses'))
      expect(access.reload).to be_pairing_code_valid
      expect(ApiAccess.authenticate(token)).to eq access
    end

    it 'destroys an access' do
      access = ApiAccess.create!(competition:, name: 'Uhr 1')
      expect { delete nested("api_accesses/#{access.id}") }.to change(ApiAccess, :count).by(-1)
      expect(response).to redirect_to(nested('accesses'))
    end
  end

  it 'denies access without login' do
    get nested('api_accesses/new')
    expect_access_denied
  end
end
