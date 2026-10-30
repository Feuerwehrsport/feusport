# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Competitions::SimpleAccessesController do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }

  describe 'accesses managements' do
    it 'uses CRUD' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/accesses"
      expect(response).to match_html_fixture.with_affix('index-empty')

      # GET new
      get "/#{competition.year}/#{competition.slug}/simple_accesses/new"
      expect(response).to match_html_fixture.with_affix('new')

      # POST create with failure
      post "/#{competition.year}/#{competition.slug}/simple_accesses",
           params: { simple_access: { name: 'foo', password: 'secret123', password_confirmation: 'wrong' } }
      expect(response).to match_html_fixture.with_affix('new-error').for_status(422)

      # POST create an access_request
      expect do
        post "/#{competition.year}/#{competition.slug}/simple_accesses",
             params: { simple_access: { name: 'foo', password: 'secret123', password_confirmation: 'secret123' } }
        expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/accesses")
        follow_redirect!
      end.to change(SimpleAccess, :count).by(1)

      # GET index
      expect(response).to match_html_fixture.with_affix('index-one-entries')

      access = SimpleAccess.first
      expect(access).to be_permission_full
      list = create(:score_list, competition:, name: 'Lauf 1')
      other_list = create(:score_list, competition: create(:competition), name: 'Fremd')

      # GET edit
      get "/#{competition.year}/#{competition.slug}/simple_accesses/#{access.id}/edit"
      expect(response).to match_html_fixture.with_affix('edit')

      # PATCH update without selected lists
      patch "/#{competition.year}/#{competition.slug}/simple_accesses/#{access.id}",
            params: { simple_access: { permission: 'selected_results', score_list_ids: [''],
                                       password: '', password_confirmation: '' } }
      expect(response).to match_html_fixture.with_affix('edit-error').for_status(422)

      # PATCH update keeps password and ignores lists of other competitions
      patch "/#{competition.year}/#{competition.slug}/simple_accesses/#{access.id}",
            params: { simple_access: { permission: 'selected_results', score_list_ids: [list.id, other_list.id],
                                       password: '', password_confirmation: '' } }
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/accesses")
      follow_redirect!
      expect(response).to match_html_fixture.with_affix('index-restricted')

      access.reload
      expect(access).to be_permission_selected_results
      expect(access.score_list_ids).to eq [list.id]
      expect(access.authenticate('secret123')).to eq access

      list.destroy!
      get "/#{competition.year}/#{competition.slug}/accesses"
      expect(response.body).to include('Keine Startliste')

      expect do
        # DELETE destroy
        delete "/#{competition.year}/#{competition.slug}/simple_accesses/#{access.id}"
        expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/accesses")
        expect(flash[:notice]).to eq :deleted
      end.to change(SimpleAccess, :count).by(-1)
    end
  end

  context 'when no login performed' do
    it 'fails' do
      get competition_nested('simple_accesses/new')
      expect_access_denied

      post competition_nested('simple_accesses'),
           params: { simple_access: { name: 'foo' } }
      expect_access_denied
    end
  end
end
