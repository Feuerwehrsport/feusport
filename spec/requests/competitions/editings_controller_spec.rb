# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'competitions/editings' do
  let!(:competition) { create(:competition) }
  let!(:user) { competition.users.first }
  let!(:wko) { create(:wko) }

  describe 'edit competition' do
    it 'uses CRUD' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/editing/edit"
      expect(response).to match_html_fixture.with_affix('edit')

      patch "/#{competition.year}/#{competition.slug}/editing",
            params: { competition: { name: 'Foo', date: '', place: '', description: 'new-description' } }
      expect(response).to match_html_fixture.with_affix('edit-error').for_status(422)

      patch "/#{competition.year}/#{competition.slug}/editing",
            params: { competition: { name: 'Foo', date: '2024-02-29', place: 'Berlin',
                                     description: 'new-description', wko_id: wko.id } }

      expect(competition.reload.description).to eq 'new-description'
      expect(competition.wko).to eq wko
    end

    context 'when no login performed' do
      it 'fails' do
        get competition_nested('editing/edit')
        expect_access_denied

        patch competition_nested('editing'),
              params: { competition: { name: 'Foo' } }
        expect_access_denied
      end
    end
  end
end
