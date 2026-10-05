# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::RegistrationsController do
  describe 'POST /users' do
    let(:params) do
      { user: { name: 'Neuer Nutzer', email: 'neu@meier.de', phone_number: '0123',
                password: 'Password', password_confirmation: 'Password' } }
    end

    context 'when hCaptcha verification fails' do
      before { allow(Recaptcha).to receive(:skip_env?).and_return(false) }

      it 'renders form again and does not create user' do
        expect do
          post '/users', params:
        end.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(flash[:alert]).to eq 'hCaptcha-Überprüfung fehlgeschlagen. Versuch es nochmal.'
        expect(response.body).to include('neu@meier.de')
        expect(response.body).not_to include('value="Password"')
      end
    end

    context 'when hCaptcha verification is skipped' do
      it 'creates user with extra params' do
        expect do
          post '/users', params:
        end.to change(User, :count).by(1)

        user = User.find_by(email: 'neu@meier.de')
        expect(user.name).to eq 'Neuer Nutzer'
        expect(user.phone_number).to eq '0123'
      end
    end
  end
end
