# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Certificates after publishing and import hint' do
  let(:user) { create(:user) }
  let(:competition) { create(:competition, users: [user]) }
  let(:assessment) { create(:assessment, competition:) }
  let!(:result) { create(:score_result, competition:, assessment:) }
  let(:old_competition) { create(:competition, name: 'Alt-Cup', users: [user]) }

  describe 'locked competition' do
    let!(:template) { create(:certificates_template, competition:, name: 'Hausurkunde') }

    before { competition.update!(locked_at: Time.current) }

    it 'keeps certificates available for admins' do
      sign_in user

      get competition_nested
      expect(response.body).to include(%(href="#{competition_nested('certificates/templates')}">Urkundenvorlagen))

      get competition_nested('certificates/templates')
      expect(response).to have_http_status(:success)

      expect do
        post competition_nested('certificates/templates'), params: { certificates_template: { name: 'Neue Urkunde' } }
      end.to change(Certificates::Template, :count).by(1)

      get competition_nested('certificates/imports/new')
      expect(response).to have_http_status(:success)

      get competition_nested("certificates/lists/new?score_result_id=#{result.id}")
      expect(response).to have_http_status(:success)

      get competition_nested("score/results/#{result.id}")
      expect(response.body).to include('Urkunden erstellen')
    end

    it 'keeps guest logins out' do
      SimpleAccess.create!(competition:, name: 'Gast', password: 'Gast12345')
      post competition_nested('simple_access_login'),
           params: { simple_access_login: { name: 'Gast', password: 'Gast12345' } }

      get competition_nested('certificates/templates')
      expect_access_denied
    end
  end

  describe 'import hint' do
    let(:hint) { 'Vorlagen aus früheren Wettkämpfen' }

    before do
      Certificates::Template.create_example(competition)
      sign_in user
    end

    it 'is shown while only the example exists and own templates are available elsewhere' do
      get competition_nested('certificates/templates')
      expect(response.body).not_to include(hint)

      own = create(:certificates_template, competition: old_competition, name: 'Meine Urkunde')
      get competition_nested('certificates/templates')
      expect(response.body).to include(hint)
      expect(response.body).to include(%(href="#{competition_nested('certificates/imports/new')}"))

      post competition_nested('certificates/imports'), params: { certificates_import: { template_id: own.id } }
      get competition_nested('certificates/templates')
      expect(response.body).not_to include(hint)
    end

    it 'disappears after creating an own template' do
      create(:certificates_template, competition: old_competition, name: 'Meine Urkunde')
      create(:certificates_template, competition:, name: 'Neu gestaltet')

      get competition_nested('certificates/templates')
      expect(response.body).not_to include(hint)
    end
  end
end
