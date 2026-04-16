# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Band do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }

  let!(:la) { create(:discipline, :la, competition:) }
  let!(:gs) { create(:discipline, :gs, competition:) }

  describe 'bands managements' do
    it 'uses CRUD' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/bands"
      expect(response).to match_html_fixture.with_affix('index-empty')

      # create an other band
      female = create(:band, :female, competition:)
      create(:assessment, band: female, discipline: la, competition:)

      # GET new
      get "/#{competition.year}/#{competition.slug}/bands/new"
      expect(response).to match_html_fixture.with_affix('new')

      # POST create with failure
      post "/#{competition.year}/#{competition.slug}/bands", params: { band: { name: 'Foo' } }
      expect(response).to match_html_fixture.with_affix('new-error').for_status(422)

      # POST create an own band
      post "/#{competition.year}/#{competition.slug}/bands", params: { band: { gender: 'male', name: 'Männer' } }
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/bands")
      follow_redirect!

      # GET index
      expect(response).to match_html_fixture.with_affix('index-two-entries')

      band = described_class.find_by(gender: 'male')
      expect(band.position).to eq 2

      # move Männer up
      get "/#{competition.year}/#{competition.slug}/bands/#{band.id}/edit?move=up"
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/bands")
      expect(band.reload.position).to eq 1

      # move Männer down
      get "/#{competition.year}/#{competition.slug}/bands/#{band.id}/edit?move=down"
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/bands")
      expect(band.reload.position).to eq 2

      # GET index XLSX
      get "/#{competition.year}/#{competition.slug}/bands.xlsx"
      expect(response.content_type).to eq(Mime[:xlsx])
      expect(response.header['Content-Disposition']).to eq(
        "attachment; filename=\"wertungsgruppen.xlsx\"; filename*=UTF-8''wertungsgruppen.xlsx",
      )
      expect(response).to have_http_status(:success)

      # GET index PDF
      get "/#{competition.year}/#{competition.slug}/bands.pdf"
      expect(response).to match_pdf_fixture.with_affix('index-as-pdf')
      expect(response.content_type).to eq(Mime[:pdf])
      expect(response.header['Content-Disposition']).to eq(
        "inline; filename=\"wertungsgruppen.pdf\"; filename*=UTF-8''wertungsgruppen.pdf",
      )
      expect(response).to have_http_status(:success)

      # GET show
      get "/#{competition.year}/#{competition.slug}/bands/#{band.id}"
      expect(response).to match_html_fixture.with_affix('show')

      # GET edit
      get "/#{competition.year}/#{competition.slug}/bands/#{band.id}/edit"
      expect(response).to match_html_fixture.with_affix('edit')

      # PUT update with failure
      put "/#{competition.year}/#{competition.slug}/bands/#{band.id}",
          params: { band: { gender: '' } }
      expect(response).to match_html_fixture.with_affix('edit-error').for_status(422)

      # PUT update
      put "/#{competition.year}/#{competition.slug}/bands/#{band.id}",
          params: { band: { gender: 'indifferent' } }
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/bands")

      expect(band.reload.gender).to eq 'indifferent'

      expect do
        # DELETE destroy
        delete "/#{competition.year}/#{competition.slug}/bands/#{band.id}"
        expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/bands")
      end.to change(described_class, :count).by(-1)
    end
  end

  context 'when no login performed' do
    let!(:band) { create(:band, competition:) }

    it 'fails' do
      get competition_nested('bands/new')
      expect_access_denied

      post competition_nested('bands'), params: { band: { name: 'Foo' } }
      expect_access_denied

      get competition_nested("bands/#{band.id}/edit")
      expect_access_denied

      patch competition_nested("bands/#{band.id}"), params: { band: { name: 'Foo' } }
      expect_access_denied

      delete competition_nested("bands/#{band.id}")
      expect_access_denied
    end
  end
end
