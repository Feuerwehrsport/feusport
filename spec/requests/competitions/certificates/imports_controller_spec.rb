# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'competitions/certificates/imports' do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }
  let!(:template) { create(:certificates_template, competition:, importable_for_me: false) }

  let(:other_user) { create(:user, :other) }
  let(:other_competition) { create(:competition, users: [other_user]) }
  let!(:other_template) { create(:certificates_template, competition: other_competition, name: 'other') }

  describe 'lists and imports template' do
    it 'uses my and other templates' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/certificates/imports/new"
      expect(response).to match_html_fixture.with_affix('new')

      template.update!(importable_for_me: true)
      other_template.update!(importable_for_others: true)

      get "/#{competition.year}/#{competition.slug}/certificates/imports/new"
      expect(response).to match_html_fixture.with_affix('new-with-other')

      other_template.update!(importable_for_others: false)

      post "/#{competition.year}/#{competition.slug}/certificates/imports",
           params: { certificates_import: { template_id: 'other' } }
      expect(response).to match_html_fixture.with_affix('new-with-error').for_status(422)

      expect do
        post "/#{competition.year}/#{competition.slug}/certificates/imports",
             params: { certificates_import: { template_id: template.id } }
      end.to change(Certificates::Template, :count).by(1)

      duplicate = Certificates::Template.where.not(id: [template.id, other_template.id]).first

      expect(response).to redirect_to(
        "/#{competition.year}/#{competition.slug}/certificates/templates/#{duplicate.id}",
      )
    end
  end

  context 'when no login performed' do
    it 'fails' do
      get competition_nested('certificates/imports/new')
      expect_access_denied

      post competition_nested('certificates/imports'),
           params: { certificates_import: { template_id: 'other' } }
      expect_access_denied
    end
  end
end
