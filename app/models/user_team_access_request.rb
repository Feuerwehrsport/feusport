# frozen_string_literal: true

# == Schema Information
#
# Table name: user_team_access_requests
#
#  id             :uuid             not null, primary key
#  email          :string(200)      not null
#  text           :text             not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  competition_id :uuid             not null
#  sender_id      :uuid             not null
#  team_id        :uuid             not null
#
# Indexes
#
#  idx_on_team_id_competition_id_email_8c8e6a5a48     (team_id,competition_id,email) UNIQUE
#  index_user_team_access_requests_on_competition_id  (competition_id)
#  index_user_team_access_requests_on_sender_id       (sender_id)
#  index_user_team_access_requests_on_team_id         (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#  fk_rails_...  (sender_id => users.id)
#  fk_rails_...  (team_id => teams.id)
#
class UserTeamAccessRequest < ApplicationRecord
  belongs_to :competition, touch: true
  belongs_to :team
  belongs_to :sender, class_name: 'User'

  auto_strip_attributes :email, :text

  schema_validations
  validates :email, 'valid_email_2/email': Rails.configuration.x.email_validation
  validates :team, same_competition: true

  def connect(user)
    competition.user_team_accesses.create!(user:, team:)
    destroy
  end
end
