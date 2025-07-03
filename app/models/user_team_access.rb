# frozen_string_literal: true

# == Schema Information
#
# Table name: user_team_accesses
#
#  id             :uuid             not null, primary key
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  competition_id :uuid             not null
#  team_id        :uuid             not null
#  user_id        :uuid             not null
#
# Indexes
#
#  idx_on_user_id_team_id_competition_id_ea2c8b8bde  (user_id,team_id,competition_id) UNIQUE
#  index_user_team_accesses_on_competition_id        (competition_id)
#  index_user_team_accesses_on_team_id               (team_id)
#  index_user_team_accesses_on_user_id               (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (user_id => users.id)
#
class UserTeamAccess < ApplicationRecord
  belongs_to :competition, touch: true
  belongs_to :user
  belongs_to :team

  schema_validations
  validates :team, same_competition: true
end
