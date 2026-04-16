# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Discipline do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }

  describe 'disciplines managements' do
    it 'uses CRUD' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/disciplines"
      expect(response).to match_html_fixture.with_affix('index-empty')

      # create an other discipline
      hb = create(:discipline, :hb, competition:)
      create(:assessment, discipline: hb, competition:)

      # GET new
      get "/#{competition.year}/#{competition.slug}/disciplines/new"
      expect(response).to match_html_fixture.with_affix('new')

      # POST create with failure
      post "/#{competition.year}/#{competition.slug}/disciplines", params: { discipline: { name: 'Foo' } }
      expect(response).to match_html_fixture.with_affix('new-error').for_status(422)

      # POST create an own discipline
      post "/#{competition.year}/#{competition.slug}/disciplines",
           params: { discipline: { name: 'Löschangriff Nass', short_name: 'LA', key: 'la' } }
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/disciplines")
      follow_redirect!

      # GET index
      expect(response).to match_html_fixture.with_affix('index-two-entries')

      # GET index XLSX
      get "/#{competition.year}/#{competition.slug}/disciplines.xlsx"
      expect(response.content_type).to eq(Mime[:xlsx])
      expect(response.header['Content-Disposition']).to eq(
        "attachment; filename=\"disziplinen.xlsx\"; filename*=UTF-8''disziplinen.xlsx",
      )
      expect(response).to have_http_status(:success)

      # GET index PDF
      get "/#{competition.year}/#{competition.slug}/disciplines.pdf"
      expect(response).to match_pdf_fixture.with_affix('index-as-pdf')
      expect(response.content_type).to eq(Mime[:pdf])
      expect(response.header['Content-Disposition']).to eq(
        "inline; filename=\"disziplinen.pdf\"; filename*=UTF-8''disziplinen.pdf",
      )
      expect(response).to have_http_status(:success)

      discipline = described_class.find_by(short_name: 'LA')

      # GET show
      get "/#{competition.year}/#{competition.slug}/disciplines/#{discipline.id}"
      expect(response).to match_html_fixture.with_affix('show')

      # GET edit
      get "/#{competition.year}/#{competition.slug}/disciplines/#{discipline.id}/edit"
      expect(response).to match_html_fixture.with_affix('edit')

      # PUT update with failure
      put "/#{competition.year}/#{competition.slug}/disciplines/#{discipline.id}",
          params: { discipline: { name: '' } }
      expect(response).to match_html_fixture.with_affix('edit-error').for_status(422)

      # PUT update
      put "/#{competition.year}/#{competition.slug}/disciplines/#{discipline.id}",
          params: { discipline: { name: 'Other' } }
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/disciplines")

      expect(discipline.reload.name).to eq 'Other'

      expect do
        # DELETE destroy
        delete "/#{competition.year}/#{competition.slug}/disciplines/#{discipline.id}"
        expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/disciplines")
      end.to change(described_class, :count).by(-1)
    end
  end

  context 'when no login performed' do
    let!(:discipline) { create(:discipline, :la, competition:) }

    it 'fails' do
      get competition_nested('disciplines/new')
      expect_access_denied

      post competition_nested('disciplines'), params: { discipline: { name: 'Foo' } }
      expect_access_denied

      get competition_nested("disciplines/#{discipline.id}/edit")
      expect_access_denied

      patch competition_nested("disciplines/#{discipline.id}"), params: { discipline: { name: 'Foo' } }
      expect_access_denied

      delete competition_nested("disciplines/#{discipline.id}")
      expect_access_denied
    end
  end
end
