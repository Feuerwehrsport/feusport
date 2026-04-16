# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Competition' do
  let(:user) { create(:user) }

  describe 'competition creations' do
    it 'creates competition' do
      sign_in user

      get '/competitions/creations/new'
      expect(response).to match_html_fixture.with_affix('new')

      # POST create with failure
      post '/competitions/creations', params: { competition: { name: 'Foo', date: '', place: '' } }
      expect(response).to match_html_fixture.with_affix('new-error').for_status(422)

      expect do
        post '/competitions/creations', params: { competition: { name: 'Foo', date: '2024-02-29', place: 'Berlin' } }
        expect(response).to redirect_to '/2024/foo'
        follow_redirect!
        expect(response).to match_html_fixture.with_affix('showing')
      end.to change(Competition, :count).by(1)

      create(:discipline, :la, competition: Competition.first)

      get '/2024/foo.pdf'
      expect(response).to match_pdf_fixture.with_affix('flyer')
      expect(response.content_type).to eq(Mime[:pdf])
      expect(response.header['Content-Disposition']).to eq(
        'inline; filename="2024-02-29-foo.pdf"; ' \
        "filename*=UTF-8''2024-02-29-foo.pdf",
      )
      expect(response).to have_http_status(:success)

      expect(Competition.first.users).to eq [user]
    end
  end

  context 'when no login performed' do
    it 'fails' do
      get '/competitions/creations/new'
      expect_access_denied(redirect_to_url: '/users/sign_in?info_hint=competition')

      post '/competitions/creations', params: { competition: { name: 'Foo' } }
      expect_access_denied(redirect_to_url: '/users/sign_in?info_hint=competition')
    end
  end
end
