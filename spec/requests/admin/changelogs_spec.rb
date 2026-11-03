# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'admin/changelogs' do
  let(:user) { create(:user) }

  it 'denies access for other users' do
    sign_in user
    get '/admin/changelogs'
    expect(response).to redirect_to('/')
  end

  it 'uses CRUD' do
    user.update!(admin: true)
    sign_in user

    get '/admin/changelogs/new'
    expect(response).to match_html_fixture.with_affix('new')
    expect(response.body).to include('value="2024-02-29"')

    post '/admin/changelogs', params: { changelog: { date: '2024-02-28', title: '', md: 'Text' } }
    expect(response).to match_html_fixture.with_affix('new-error').for_status(422)

    post '/admin/changelogs', params: { changelog: { date: '2024-02-28', title: 'Neues', md: '*Text*' } }
    expect(response).to redirect_to('/admin/changelogs')
    changelog = Changelog.last
    expect(changelog).to have_attributes(title: 'Neues', md: '*Text*', date: Date.parse('2024-02-28'))

    get '/admin/changelogs'
    expect(response).to match_html_fixture.with_affix('index')

    get "/admin/changelogs/#{changelog.id}/edit"
    expect(response).to match_html_fixture.with_affix('edit')

    patch "/admin/changelogs/#{changelog.id}", params: { changelog: { title: '' } }
    expect(response).to have_http_status(:unprocessable_content)

    patch "/admin/changelogs/#{changelog.id}", params: { changelog: { title: 'Geändert' } }
    expect(response).to redirect_to('/admin/changelogs')
    expect(changelog.reload.title).to eq 'Geändert'

    get '/changelogs'
    expect(response.body).to include('Geändert', '<em>Text</em>')

    delete "/admin/changelogs/#{changelog.id}"
    expect(response).to redirect_to('/admin/changelogs')
    expect(Changelog.count).to eq 0
  end
end
