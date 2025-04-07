# frozen_string_literal: true

# == Schema Information
#
# Table name: user_accesses
#
#  id             :uuid             not null, primary key
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  competition_id :uuid             not null
#  user_id        :uuid             not null
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

  schema_validations
end
