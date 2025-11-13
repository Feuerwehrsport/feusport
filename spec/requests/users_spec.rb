# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  let(:user) { create(:user) }

  describe 'GET /users/sign_in' do
    it_renders 'the login form' do
      get '/users/sign_in'
    end
  end

  describe 'POST /users/sign_in' do
    before { user }

    context 'when credentials are wrong' do
      it 'signs in' do
        post '/users/sign_in', params: { user: { email: 'alfred@meier.de', password: 'wrong' } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'when credentials are correct' do
      it 'signs in' do
        post '/users/sign_in', params: { user: { email: 'alfred@meier.de', password: 'Password' } }
        expect(response).to redirect_to root_path
        expect(flash[:notice]).to eq 'Erfolgreich angemeldet.'
      end
    end
  end

  describe 'DELETE /users/sign_out' do
    it 'signs out' do
      sign_in user
      delete '/users/sign_out'
      expect(response).to redirect_to root_path
      expect(flash[:notice]).to eq 'Erfolgreich abgemeldet.'
    end
  end

  describe 'GET /users/password/new' do
    it_renders 'the password forgotten form' do
      get '/users/password/new'
    end
  end

  describe 'GET /users/password/edit' do
    before { user.update!(reset_password_token: 'ABC', reset_password_sent_at: 1.second.ago) }

    it_renders 'the password reset form' do
      get '/users/password/edit', params: { reset_password_token: 'ABC' }
    end
  end

  describe 'PATCH /users/password' do
    before do
      user.update!(updated_at: 1.year.ago,
                   reset_password_token: Devise.token_generator.digest(described_class, :reset_password_token, 'ABC'),
                   reset_password_sent_at: 1.second.ago)
    end

    it 'changes password' do
      patch '/users/password', params: { user: { reset_password_token: 'ABC', password: 'Password1',
                                                 password_confirmation: 'Password1' } }
      expect(response).to redirect_to root_path
      expect(flash[:notice]).to eq 'Dein Passwort wurde geändert. Du bist jetzt angemeldet.'
      expect(user.reload.updated_at).to be > 1.hour.ago
    end
  end

  describe 'POST /users/password' do
    it 'sends mail' do
      post '/users/password', params: { user: { email: user.email } }
      expect(response).to redirect_to new_user_session_path
      expect(flash[:notice]).to eq(
        'Du erhältst in wenigen Minuten eine E-Mail mit der Anleitung, wie Du Dein Passwort zurücksetzen kannst.',
      )
      expect(user.reload.reset_password_sent_at).to be > 1.hour.ago
    end
  end

  describe 'GET /users/sign_up' do
    it_renders 'registration form' do
      get '/users/sign_up'
    end
  end

  describe 'GET /users/edit' do
    it_renders 'user form' do
      sign_in user
      get '/users/edit'
    end
  end

  describe 'PATCH /users' do
    it 'updates user' do
      sign_in user
      patch '/users',
            params: { user: { name: 'Peter Winter', email: user.email, password: '', current_password: 'Password' } }
      expect(response).to redirect_to root_path
      expect(flash[:notice]).to eq 'Deine Daten wurden aktualisiert.'
      expect(user.reload.name).to eq 'Peter Winter'
    end
  end

  describe 'DELETE /users' do
    it 'destroys user' do
      sign_in user
      delete '/users'
      expect(response).to redirect_to root_path
      expect(flash[:notice]).to eq 'Dein Konto wurde gelöscht. Wir hoffen, dass wir Dich bald wiedersehen.'
    end
  end

  describe 'POST /users' do
    it 'creates user' do
      expect do
        post '/users',
             params: { user: { name: 'Frank', email: 'aa@bb.cc', password: 'Password',
                               password_confirmation: 'Password' } }
        expect(response).to redirect_to root_path
        expect(flash[:notice]).to eq(
          'Du erhältst in wenigen Minuten eine E-Mail mit einem Link für die Bestätigung der Registrierung. ' \
          'Klicke auf den Link, um Dein Konto zu aktivieren.',
        )
      end.to change(described_class, :count).by(1)
    end
  end

  describe 'GET /users/confirmation/new' do
    it_renders 'form' do
      get '/users/confirmation/new'
    end
  end

  describe 'GET /users/confirmation' do
    before { user.update!(confirmation_token: 'ABC', confirmation_sent_at: 1.second.ago, confirmed_at: nil) }

    it 'confirms' do
      get '/users/confirmation', params: { confirmation_token: 'ABC' }
      expect(response).to redirect_to new_user_session_path
      expect(flash[:notice]).to eq 'Deine E-Mail-Adresse wurde erfolgreich bestätigt.'
    end
  end

  describe 'POST /users/confirmation' do
    before { user.update!(confirmation_token: 'ABC', confirmation_sent_at: 1.second.ago, confirmed_at: nil) }

    it 'resends mail' do
      post '/users/confirmation', params: { user: { email: user.email } }
      expect(response).to redirect_to new_user_session_path
      expect(flash[:notice]).to eq(
        'Du erhältst in wenigen Minuten eine E-Mail, mit der Du Deine Registrierung bestätigen kannst.',
      )
    end
  end

  describe 'GET /users/unlock/new' do
    it_renders 'form' do
      get '/users/unlock/new'
    end
  end

  describe 'GET /users/unlock' do
    before do
      user.update!(locked_at: 1.hour.ago,
                   unlock_token: Devise.token_generator.digest(described_class, :unlock_token, 'ABC'))
    end

    it 'unlocks' do
      get '/users/unlock', params: { unlock_token: 'ABC' }
      expect(response).to redirect_to new_user_session_path
      expect(flash[:notice]).to eq 'Dein Konto wurde entsperrt. Bitte melde Dich an, um fortzufahren.'
      expect(user.reload.locked_at).to be_nil
    end
  end

  describe 'POST /users/unlock' do
    before do
      user.update!(locked_at: 1.hour.ago)
    end

    it 'sends mail' do
      post '/users/unlock', params: { user: { email: user.email } }
      expect(response).to redirect_to new_user_session_path
      expect(flash[:notice]).to eq(
        'Du erhältst in wenigen Minuten eine E-Mail mit der Anleitung, wie Du Dein Konto entsperren kannst.',
      )
      expect(user.reload.unlock_token).not_to be_nil
    end
  end
end
