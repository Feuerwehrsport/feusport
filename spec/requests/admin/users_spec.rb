# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'admin/users' do
  let!(:admin) { create(:user, admin: true, email: 'admin@meier.de', name: 'Admin') }
  let!(:other) { create(:user, :other) }

  it 'denies access for other users' do
    sign_in other
    get '/admin/users'
    expect(response).to redirect_to('/')
  end

  it 'lists, searches and paginates users' do
    sign_in admin

    get '/admin/users'
    expect(response).to match_html_fixture
    expect(response.body).not_to include('Seite 1')

    get '/admin/users', params: { q: 'other@' }
    expect(response.body).to include('Other Meier')
    expect(response.body).not_to include('admin@meier.de')

    stub_const('AdminController::PER_PAGE', 1)
    get '/admin/users'
    expect(response.body).to include('Seite 1 von 2')

    get '/admin/users', params: { page: 5 }
    expect(response.body).to include('Seite 2 von 2')
  end

  it 'changes users' do
    sign_in admin
    other.update!(confirmed_at: nil)
    other.lock_access!(send_instructions: false)

    get '/admin/users'
    expect(response.body).to include('Unbestätigt', 'Vorübergehend gesperrt')

    post "/admin/users/#{other.id}/unlock", params: { q: 'other' }
    expect(response).to redirect_to('/admin/users?q=other')
    expect(other.reload.access_locked?).to be false

    post "/admin/users/#{other.id}/confirm"
    expect(other.reload.confirmed?).to be true

    expect do
      post "/admin/users/#{other.id}/reset_password"
    end.to have_enqueued_mail(Devise::Mailer, :reset_password_instructions)
    expect(flash[:notice]).to eq :password_reset_sent

    post "/admin/users/#{admin.id}/disable"
    expect(flash[:alert]).to eq :not_yourself
    expect(admin.reload.disabled?).to be false

    post "/admin/users/#{other.id}/disable"
    expect(other.reload.disabled?).to be true
    get '/admin/users'
    expect(response.body).to include('Deaktiviert', 'Aktivieren')

    post "/admin/users/#{other.id}/enable"
    expect(other.reload.disabled?).to be false
  end

  it 'prevents disabled users from signing in' do
    other.update!(disabled_at: Time.current)
    post '/users/sign_in', params: { user: { email: 'other@meier.de', password: 'Password' } }
    expect(flash[:alert]).to eq 'Dein Konto wurde deaktiviert. Wende dich an den Administrator.'

    other.update!(disabled_at: nil)
    post '/users/sign_in', params: { user: { email: 'other@meier.de', password: 'Password' } }
    expect(flash[:notice]).to eq 'Erfolgreich angemeldet.'

    other.update!(disabled_at: Time.current)
    get '/'
    expect(response).to redirect_to('/users/sign_in')
    expect(flash[:alert]).to eq 'Dein Konto wurde deaktiviert. Wende dich an den Administrator.'
  end
end
