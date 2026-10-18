# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InvitationValidity do
  let(:competition) { create(:competition) }

  describe '#expires_at' do
    it 'is 30 days after creation' do
      request = create(:user_access_request, competition:)
      expect(request.expires_at).to eq request.created_at + 30.days
    end
  end

  describe InvitationValidity::CleanupJob do
    let(:band) { create(:band, competition:) }
    let(:team) { create(:team, competition:, band:) }

    it 'deletes invitations older than twice the validity' do
      old_access = create(:user_access_request, competition:, created_at: 61.days.ago)
      expired_access = create(:user_access_request, competition:, created_at: 59.days.ago)
      old_team = create(:user_team_access_request, competition:, team:, created_at: 61.days.ago)
      expired_team = create(:user_team_access_request, competition:, team:, email: 'neu@request.de',
                                                       created_at: 59.days.ago)

      described_class.perform_now

      expect(UserAccessRequest.where(id: [old_access.id, expired_access.id]).pluck(:id)).to eq [expired_access.id]
      expect(UserTeamAccessRequest.where(id: [old_team.id, expired_team.id]).pluck(:id)).to eq [expired_team.id]
    end
  end
end
