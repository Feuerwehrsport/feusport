# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'competitions/snapshots' do
  let!(:competition) { create(:competition) }
  let!(:user) { competition.users.first }

  before do
    view_sanitizer.gsub(%r{active_storage/blobs/redirect/[^/]+/}, 'BLOBID')
    view_sanitizer.gsub(%r{active_storage/representations/redirect/[^/]+/[^/]+/}, 'BLOBID')
  end

  describe 'edit snapshots' do
    it 'uses CRUD' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/snapshots/new"
      expect(response).to match_html_fixture.with_affix('new')

      post "/#{competition.year}/#{competition.slug}/snapshots",
           params: { snapshot: { title: 'Foo' } }
      expect(response).to match_html_fixture.with_affix('new-error').for_status(422)

      expect do
        post "/#{competition.year}/#{competition.slug}/snapshots",
             params: { snapshot: { title: 'Foo', file: fixture_file_upload('pixel.jpg') } }
        expect(response).to redirect_to "/#{competition.year}/#{competition.slug}"
      end.to change(Snapshot, :count).by(1)

      new_id = Snapshot.first.id

      get "/#{competition.year}/#{competition.slug}/snapshots/#{new_id}/edit"
      expect(response).to match_html_fixture.with_affix('edit')

      patch "/#{competition.year}/#{competition.slug}/snapshots/#{new_id}",
            params: { snapshot: { title: '' } }
      expect(response).to match_html_fixture.with_affix('edit-error').for_status(422)

      patch "/#{competition.year}/#{competition.slug}/snapshots/#{new_id}",
            params: { snapshot: { title: 'Foo2' } }
      expect(response).to redirect_to "/#{competition.year}/#{competition.slug}"
      expect(Snapshot.find(new_id).title).to eq 'Foo2'

      follow_redirect!
      expect(response).to match_html_fixture.with_affix('gallery')

      expect do
        delete "/#{competition.year}/#{competition.slug}/snapshots/#{new_id}"
        expect(response).to redirect_to "/#{competition.year}/#{competition.slug}"
      end.to change(Snapshot, :count).by(-1)
    end
  end
end
