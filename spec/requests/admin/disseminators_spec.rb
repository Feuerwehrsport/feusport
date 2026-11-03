# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'admin/disseminators' do
  let(:user) { create(:user, admin: true) }

  it 'uses CRUD' do
    sign_in user

    get '/admin/disseminators/new'
    expect(response).to match_html_fixture.with_affix('new')

    post '/admin/disseminators', params: { disseminator: { name: '' } }
    expect(response).to have_http_status(:unprocessable_content)

    post '/admin/disseminators', params: { disseminator: { name: 'Alfred Meier', lfv: 'Mecklenburg-Vorpommern',
                                                           position: 'Chef', email_address: 'foo@bar.de',
                                                           phone_number: '0190 123456' } }
    expect(response).to redirect_to('/admin/disseminators')
    disseminator = Disseminator.last

    get '/admin/disseminators'
    expect(response).to match_html_fixture.with_affix('index')

    get "/admin/disseminators/#{disseminator.id}/edit"
    expect(response).to have_http_status(:success)
    expect(response.body).to include('value="Alfred Meier"')

    patch "/admin/disseminators/#{disseminator.id}", params: { disseminator: { position: 'Helfer' } }
    expect(response).to redirect_to('/admin/disseminators')
    expect(disseminator.reload.position).to eq 'Helfer'

    get '/disseminators'
    expect(response.body).to include('Alfred Meier', 'Helfer')

    delete "/admin/disseminators/#{disseminator.id}"
    expect(response).to redirect_to('/admin/disseminators')
    expect(Disseminator.count).to eq 0
  end
end
