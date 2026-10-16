# frozen_string_literal: true

# == Schema Information
#
# Table name: user_accesses
#
#  id                     :uuid             not null, primary key
#  registration_mail_info :boolean          default(TRUE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  competition_id         :uuid             not null
#  user_id                :uuid             not null
#
# Indexes
#
#  index_user_accesses_on_competition_id  (competition_id)
#  index_user_accesses_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#  fk_rails_...  (user_id => users.id)
#
class UserAccess < ApplicationRecord
  belongs_to :user
  belongs_to :competition, touch: true

  scope :with_registration_mail_info, -> { where(registration_mail_info: true) }

  schema_validations

  after_destroy :destroy_revoked_invitations

  private

  def destroy_revoked_invitations
    # Über die Klasse laden, damit `competition.user_accesses` nicht aus dem Speicher kommt
    [UserAccessRequest, UserTeamAccessRequest].each do |requests|
      requests.where(competition_id:, sender: user).reject(&:sender_allowed?).each(&:destroy)
    end
  end
end
