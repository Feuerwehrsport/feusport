# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Competitions::AccessesController do
  let!(:competition) { create(:competition) }
  let!(:user) { competition.users.first }
  let(:other_user) { create(:user, :other) }

  describe 'accesses managements' do
    it 'uses CRUD' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/accesses"
      expect(response).to match_html_fixture.with_affix('index-one-entry')

      # GET new
      get "/#{competition.year}/#{competition.slug}/access_requests/new"
      expect(response).to match_html_fixture.with_affix('new')

      # POST create with failure
      post "/#{competition.year}/#{competition.slug}/access_requests", params: { user_access_request: { email: 'foo' } }
      expect(response).to match_html_fixture.with_affix('new-error').for_status(422)

      expect do
        # POST create an access_request
        post "/#{competition.year}/#{competition.slug}/access_requests",
             params: { user_access_request: { email: 'foo@bar.de', text: 'Hallo', drop_myself: true } }
        expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/accesses")
        follow_redirect!
      end.to have_enqueued_job.with('CompetitionMailer', 'access_request', 'deliver_now', any_args)

      # GET index
      expect(response).to match_html_fixture.with_affix('index-two-entries')

      # load request
      req = competition.user_access_requests.first

      # GET connect - error same user
      get "/#{competition.year}/#{competition.slug}/access_requests/#{req.id}/connect"
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/accesses")
      expect(flash[:alert]).to eq 'Du kannst dich nicht selber hinzufügen.'

      sign_out user
      sign_in other_user

      expect do
        expect do
          # GET connect
          get "/#{competition.year}/#{competition.slug}/access_requests/#{req.id}/connect"
          expect(response).to redirect_to("/#{competition.year}/#{competition.slug}")
          expect(flash[:notice]).to eq 'Du wurdest erfolgreich mit dem Wettkampf verbunden.'
        end.not_to change(UserAccess, :count)
      end.to have_enqueued_job.with('CompetitionMailer', 'access_request_connected', 'deliver_now', any_args)

      # POST create an other access_request
      post "/#{competition.year}/#{competition.slug}/access_requests",
           params: { user_access_request: { email: 'foo@bar.de', text: 'Hallo', drop_myself: false } }
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/accesses")

      sign_out other_user
      sign_in user

      # load request
      req = competition.user_access_requests.first

      expect do
        # GET connect
        get "/#{competition.year}/#{competition.slug}/access_requests/#{req.id}/connect"
        expect(response).to redirect_to("/#{competition.year}/#{competition.slug}")
        expect(flash[:notice]).to eq 'Du wurdest erfolgreich mit dem Wettkampf verbunden.'
      end.to change(UserAccess, :count).by(1)

      # create an other request
      req = UserAccessRequest.create!(competition:, sender: other_user, email: 'foo@bar.de', text: 'Hallo')

      # GET connect with error
      get "/#{competition.year}/#{competition.slug}/access_requests/#{req.id}/connect"
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/accesses")
      expect(flash[:alert]).to eq 'Du hast bereits Zugriff auf diesen Wettkampf.'

      # POST create an other access_request
      post "/#{competition.year}/#{competition.slug}/access_requests",
           params: { user_access_request: { email: 'foo@bar.de', text: 'Hallo', drop_myself: false } }
      expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/accesses")

      # load access
      access = competition.user_access_requests.first

      expect do
        # DELETE destroy
        delete "/#{competition.year}/#{competition.slug}/access_requests/#{access.id}"
        expect(response).to redirect_to("/#{competition.year}/#{competition.slug}/accesses")
        expect(flash[:notice]).to eq :deleted
      end.to change(UserAccessRequest, :count).by(-1)
    end

    it 'destoys access' do
      sign_in user

      access = UserAccess.create(user: other_user, competition:)

      get competition_nested('accesses')
      expect(response).to be_successful

      expect do
        expect do
          # DELETE destroy
          delete competition_nested("accesses/#{access.id}")
          expect(response).to redirect_to(competition_nested('accesses'))
          expect(flash[:notice]).to eq :deleted
        end.to change(UserAccess, :count).by(-1)
      end.to have_enqueued_job.with('CompetitionMailer', 'access_deleted', 'deliver_now', any_args)
    end
  end

  context 'when user has friends' do
    let!(:other_competition) { create(:competition) }
    let!(:other_access) { UserAccess.create(user: other_user, competition: other_competition) }

    it 'is hinted on new access requests page' do
      sign_in user

      get "/#{competition.year}/#{competition.slug}/access_requests/new"
      expect(response).to match_html_fixture.with_affix('new-with-friends')

      get "/#{competition.year}/#{competition.slug}/access_requests/new?friend_id=#{other_user.id}"
      expect(response).to match_html_fixture.with_affix('new-with-selected-friend')
    end
  end

  context 'when toggle mail info' do
    it 'toggles registration_mail_info' do
      sign_in user

      get competition_nested('accesses')
      expect(response).to be_successful

      get competition_nested("accesses/#{competition.user_accesses.first.id}/edit?registration_mail_info=false")
      expect(response).to redirect_to(competition_nested('accesses'))

      expect(UserAccess.pluck(:registration_mail_info)).to eq [false]

      get "/#{competition.year}/#{competition.slug}/accesses"
      expect(response).to match_html_fixture.with_affix('index-without-mailinfo')

      get competition_nested("accesses/#{competition.user_accesses.first.id}/edit?registration_mail_info=true")
      expect(response).to redirect_to(competition_nested('accesses'))

      expect(UserAccess.pluck(:registration_mail_info)).to eq [true]
    end
  end
end
