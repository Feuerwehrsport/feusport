# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'competitions/visibilities' do
  let!(:competition) { create(:competition) }
  let!(:user) { competition.users.first }

  describe 'edit visibilities' do
    it 'uses CRUD' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/visibility/edit"
      expect(response).to match_html_fixture.with_affix('edit')

      patch "/#{competition.year}/#{competition.slug}/visibility",
            params: { competition: { slug: '' } }
      expect(response).to match_html_fixture.with_affix('edit-error').for_status(422)

      patch "/#{competition.year}/#{competition.slug}/visibility",
            params: { competition: { slug: 'new-slug' } }
      expect(response).to redirect_to "/#{competition.year}/new-slug"
      expect(competition.reload.slug).to eq 'new-slug'
    end
  end

  context 'when no login performed' do
    it 'fails' do
      get competition_nested('visibility/edit')
      expect_access_denied

      patch competition_nested('visibility'),
            params: { competition: { slug: '' } }
      expect_access_denied
    end
  end
end
