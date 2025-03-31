# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'competitions/documents' do
  let!(:competition) { create(:competition) }
  let!(:user) { competition.users.first }

  describe 'edit documents' do
    it 'uses CRUD' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/documents/new"
      expect(response).to match_html_fixture.with_affix('new')

      post "/#{competition.year}/#{competition.slug}/documents",
           params: { document: { title: 'Foo' } }
      expect(response).to match_html_fixture.with_affix('new-error').for_status(422)

      expect do
        post "/#{competition.year}/#{competition.slug}/documents",
             params: { document: { title: 'Foo', file: fixture_file_upload('doc.pdf') } }
        expect(response).to redirect_to "/#{competition.year}/#{competition.slug}"
      end.to change(Document, :count).by(1)

      new_id = Document.first.id

      get "/#{competition.year}/#{competition.slug}/documents/#{new_id}/edit"
      expect(response).to match_html_fixture.with_affix('edit')

      patch "/#{competition.year}/#{competition.slug}/documents/#{new_id}",
            params: { document: { title: '' } }
      expect(response).to match_html_fixture.with_affix('edit-error').for_status(422)

      patch "/#{competition.year}/#{competition.slug}/documents/#{new_id}",
            params: { document: { title: 'Foo2' } }
      expect(response).to redirect_to "/#{competition.year}/#{competition.slug}"
      expect(Document.find(new_id).title).to eq 'Foo2'

      expect do
        delete "/#{competition.year}/#{competition.slug}/documents/#{new_id}"
        expect(response).to redirect_to "/#{competition.year}/#{competition.slug}"
      end.to change(Document, :count).by(-1)
    end
  end

  describe 'download' do
    it 'redirects to' do
      get "/#{competition.year}/#{competition.slug}/dd/foo"
      expect(response).to have_http_status(:not_found)

      document = competition.documents.create!(title: 'Foo', file: fixture_file_upload('doc.pdf'))

      get "/#{competition.year}/#{competition.slug}/dd/#{document.idpart}"
      expect(response).to redirect_to(%r{active_storage/blobs})

      competition.update!(visible: false)

      get "/#{competition.year}/#{competition.slug}/dd/#{document.idpart}"
      expect(response).to redirect_to('/users/sign_in')

      sign_in user

      get "/#{competition.year}/#{competition.slug}/dd/#{document.idpart}"
      expect(response).to redirect_to(%r{active_storage/blobs})
    end
  end
end
