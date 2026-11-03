# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'admin/competitions' do
  let!(:competition) { create(:competition, visible: false) }
  let!(:admin) { create(:user, admin: true, email: 'admin@meier.de', name: 'Admin') }

  it 'lists, searches and joins competitions' do
    create(:competition, name: 'Alt-Cup', place: 'Wismar', date: Date.parse('2019-05-01'), locked_at: Time.current,
                         users: competition.users)
    sign_in admin

    get '/admin/competitions'
    expect(response).to match_html_fixture
    expect(response.body).to include('Nicht öffentlich', 'Abgeschlossen')

    get '/admin/competitions', params: { q: 'wismar' }
    expect(response.body).to include('Alt-Cup')
    expect(response.body).not_to include('MV-Cup')

    get '/admin/competitions', params: { q: '2024' }
    expect(response.body).to include('MV-Cup')
    expect(response.body).not_to include('Alt-Cup')

    get "/#{competition.year}/#{competition.slug}"
    expect(response).to redirect_to('/')

    post "/admin/competitions/#{competition.id}/join"
    expect(response).to redirect_to("/#{competition.year}/#{competition.slug}")
    expect(competition.user_accesses.find_by(user: admin).registration_mail_info).to be false
    get "/#{competition.year}/#{competition.slug}"
    expect(response).to have_http_status(:success)

    get '/admin/competitions'
    expect(response.body).to include('Mich entfernen')

    delete "/admin/competitions/#{competition.id}/leave", params: { q: 'mv' }
    expect(response).to redirect_to('/admin/competitions?q=mv')
    expect(competition.users.reload).not_to include(admin)
  end
end
