# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InformationRequest do
  let(:competition) { create(:competition) }
  let(:user) { competition.users.first }

  describe 'information request creation' do
    it 'uses CRUD' do
      sign_in user

      # GET new
      get "/#{competition.year}/#{competition.slug}/information_requests/new"
      expect(response).to match_html_fixture.with_affix('new')

      # POST create with failure
      post "/#{competition.year}/#{competition.slug}/information_requests",
           params: { information_request: { foo: 'Foo' } }
      expect(response).to match_html_fixture.with_affix('new-error').for_status(422)

      expect do
        # POST create an request
        post "/#{competition.year}/#{competition.slug}/information_requests",
             params: { information_request: { message: 'Message' } }
        expect(response).to redirect_to("/#{competition.year}/#{competition.slug}")
        follow_redirect!
        expect(response).to match_html_fixture.with_affix('show-with-flash')
      end.to have_enqueued_job.with('CompetitionMailer', 'information_request', 'deliver_now', any_args)
    end
  end
end
