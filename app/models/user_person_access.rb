# frozen_string_literal: true

# == Schema Information
#
# Table name: user_person_accesses
#
#  id             :uuid             not null, primary key
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  competition_id :uuid             not null
#  person_id      :uuid             not null
#  user_id        :uuid             not null
#
# Indexes
#
#  idx_on_user_id_person_id_competition_id_1f5885f0fe  (user_id,person_id,competition_id) UNIQUE
#  index_user_person_accesses_on_competition_id        (competition_id)
#  index_user_person_accesses_on_person_id             (person_id)
#  index_user_person_accesses_on_user_id               (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#  fk_rails_...  (person_id => people.id)
#  fk_rails_...  (user_id => users.id)
#
class UserPersonAccess < ApplicationRecord
  belongs_to :competition, touch: true
  belongs_to :user
  belongs_to :person

  schema_validations
  validates :person, same_competition: true
end
