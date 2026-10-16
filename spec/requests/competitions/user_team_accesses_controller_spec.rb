# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Competitions::UserTeamAccessesController do
  let(:competition) { create(:competition) }
  let(:band) { create(:band, competition:) }
  let!(:team) { create(:team, competition:, band:) }
  let!(:user) { competition.users.first }
  let(:other_user) { create(:user, :other) }

  describe 'accesses managements' do
    it 'uses CRUD' do
      sign_in user

      get competition_nested("teams/#{team.id}/accesses")
      expect(response).to match_html_fixture.with_affix('index-one-entry')

      # GET new
      get competition_nested("teams/#{team.id}/access_requests/new")
      expect(response).to match_html_fixture.with_affix('new')

      # POST create with failure
      post competition_nested("teams/#{team.id}/access_requests"),
           params: { user_team_access_request: { email: 'foo' } }
      expect(response).to match_html_fixture.with_affix('new-error').for_status(422)

      expect do
        # POST create an access_request
        post competition_nested("teams/#{team.id}/access_requests"),
             params: { user_team_access_request: { email: 'foo@bar.de', text: 'Hallo' } }
        expect(response).to redirect_to(competition_nested("teams/#{team.id}/accesses"))
        follow_redirect!
      end.to have_enqueued_job.with('CompetitionMailer', 'user_team_access_request', 'deliver_now', any_args)

      # GET index
      expect(response).to match_html_fixture.with_affix('index-two-entries')

      # load request
      req = competition.user_team_access_requests.first
      expect(response.body).not_to include(req.token)

      # GET connect - error same user
      get competition_nested("teams/#{team.id}/access_requests/#{req.id}/connect?token=#{req.token}")
      expect(response).to redirect_to(competition_nested("teams/#{team.id}/accesses"))
      expect(flash[:alert]).to eq 'Du kannst dich nicht selber hinzufügen.'

      sign_out user
      sign_in other_user

      expect do
        expect do
          # GET connect
          get competition_nested("teams/#{team.id}/access_requests/#{req.id}/connect?token=#{req.token}")
          expect(response).to redirect_to(competition_nested("teams/#{team.id}"))
          expect(flash[:notice]).to eq 'Du wurdest erfolgreich mit dieser Mannschaft verbunden.'
        end.not_to change(UserAccess, :count)
      end.to have_enqueued_job.with('CompetitionMailer', 'user_team_access_request_connected', 'deliver_now', any_args)

      # team leaders may only invite while registration is possible
      competition.update!(registration_open_until: Date.current, registration_open: 'open', visible: true)

      # POST create an other access_request
      post competition_nested("teams/#{team.id}/access_requests"),
           params: { user_team_access_request: { email: 'foo@bar.de', text: 'Hallo' } }
      expect(response).to redirect_to(competition_nested("teams/#{team.id}/accesses"))
      follow_redirect!

      sign_out other_user
      sign_in user

      # load request
      req = competition.user_team_access_requests.first

      expect do
        # GET connect
        get competition_nested("teams/#{team.id}/access_requests/#{req.id}/connect?token=#{req.token}")
        expect(response).to redirect_to(competition_nested("teams/#{team.id}"))
        expect(flash[:notice]).to eq 'Du wurdest erfolgreich mit dieser Mannschaft verbunden.'
      end.to change(UserTeamAccess, :count).by(1)

      # create an other request
      req = UserTeamAccessRequest.create!(competition:, sender: other_user, email: 'foo@bar.de', text: 'Hallo', team:)

      # GET connect with error
      get competition_nested("teams/#{team.id}/access_requests/#{req.id}/connect?token=#{req.token}")
      expect(response).to redirect_to(competition_nested("teams/#{team.id}/accesses"))
      expect(flash[:alert]).to eq 'Du hast bereits Zugriff auf diese Mannschaft.'

      expect do
        # DELETE destroy
        delete competition_nested("teams/#{team.id}/access_requests/#{req.id}")
        expect(response).to redirect_to(competition_nested("teams/#{team.id}/accesses"))
        expect(flash[:notice]).to eq :deleted
      end.to change(UserTeamAccessRequest, :count).by(-1)
    end

    it 'destoys access' do
      sign_in user

      access = UserTeamAccess.create(user: other_user, competition:, team:)

      get competition_nested("teams/#{team.id}/accesses")
      expect(response).to be_successful

      expect do
        expect do
          # DELETE destroy
          delete competition_nested("teams/#{team.id}/accesses/#{access.id}")
          expect(response).to redirect_to(competition_nested("teams/#{team.id}/accesses"))
          expect(flash[:notice]).to eq :deleted
        end.to change(UserTeamAccess, :count).by(-1)
      end.to have_enqueued_job.with('CompetitionMailer', 'user_team_access_deleted', 'deliver_now', any_args)
      follow_redirect!

      # try to delete own access
      access = UserTeamAccess.create(user: user, competition:, team:)

      expect do
        # DELETE destroy
        delete competition_nested("teams/#{team.id}/accesses/#{access.id}")
        expect(response).to redirect_to(competition_nested("teams/#{team.id}/accesses"))
      end.not_to change(UserTeamAccess, :count)
    end
  end

  context 'when user has no access to team' do
    let!(:req) { UserTeamAccessRequest.create!(competition:, sender: user, email: 'foo@bar.de', text: 'Hallo', team:) }

    it 'hides accesses and requests' do
      sign_in other_user

      get competition_nested("teams/#{team.id}/accesses")
      expect(response).to redirect_to('/')
      expect(flash[:alert]).to eq 'Zugriff verweigert'
    end

    it 'connects only with valid token' do
      sign_in other_user

      ['', '?token=', '?token=wrong'].each do |query|
        expect do
          get competition_nested("teams/#{team.id}/access_requests/#{req.id}/connect#{query}")
          expect(response).to redirect_to(competition_nested("teams/#{team.id}"))
          expect(flash[:alert]).to eq 'Der Link ist ungültig.'
        end.not_to change(UserTeamAccess, :count)
      end

      expect do
        get competition_nested("teams/#{team.id}/access_requests/#{req.id}/connect?token=#{req.token}")
      end.to change(UserTeamAccess, :count).by(1)
    end
  end

  context 'when invitation is no longer valid' do
    let(:sender) { create(:user, email: 'sender@meier.de') }
    let!(:sender_access) { UserTeamAccess.create!(user: sender, competition:, team:) }
    let!(:req) { UserTeamAccessRequest.create!(competition:, sender:, email: 'foo@bar.de', text: 'Hallo', team:) }
    let(:connect_path) { competition_nested("teams/#{team.id}/access_requests/#{req.id}/connect?token=#{req.token}") }

    before do
      competition.update!(registration_open_until: Date.current, registration_open: 'open', visible: true)
      sign_in other_user
    end

    it 'rejects expired invitations' do
      req.update!(created_at: 31.days.ago)

      expect do
        get connect_path
        expect(response).to redirect_to(competition_nested("teams/#{team.id}"))
        expect(flash[:alert]).to eq :invitation_expired
      end.not_to change(UserTeamAccess, :count)
    end

    it 'rejects invitations of team leaders after registration' do
      competition.update!(registration_open_until: Date.yesterday)

      expect do
        get connect_path
        expect(response).to redirect_to(competition_nested("teams/#{team.id}"))
        expect(flash[:alert]).to eq :invitation_revoked
      end.not_to change(UserTeamAccess, :count)
    end

    it 'deletes invitations when access of sender is removed' do
      sign_in user

      expect do
        delete competition_nested("teams/#{team.id}/accesses/#{sender_access.id}")
      end.to change(UserTeamAccessRequest, :count).by(-1)
    end

    it 'keeps invitations of senders who are still allowed' do
      UserAccess.create!(user: sender, competition:)
      sign_in user

      expect do
        delete competition_nested("teams/#{team.id}/accesses/#{sender_access.id}")
      end.not_to change(UserTeamAccessRequest, :count)
    end
  end

  context 'when user has friends' do
    let!(:other_competition) { create(:competition) }
    let!(:other_access) { UserAccess.create(user: other_user, competition: other_competition) }

    it 'is hinted on new access requests page' do
      sign_in user

      get competition_nested("teams/#{team.id}/access_requests/new")
      expect(response).to match_html_fixture.with_affix('new-with-friends')

      get competition_nested("teams/#{team.id}/access_requests/new?friend_id=#{other_user.id}")
      expect(response).to match_html_fixture.with_affix('new-with-selected-friend')
    end
  end

  context 'when no login performed' do
    it 'fails' do
      get competition_nested("teams/#{team.id}/access_requests/new")
      expect_access_denied
    end
  end
end
