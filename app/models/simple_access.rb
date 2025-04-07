# frozen_string_literal: true

# == Schema Information
#
# Table name: simple_accesses
#
#  id              :uuid             not null, primary key
#  name            :string           not null
#  password_digest :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  competition_id  :uuid             not null
#
# Indexes
#
#  index_simple_accesses_on_competition_id           (competition_id)
#  index_simple_accesses_on_competition_id_and_name  (competition_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
class SimpleAccess < ApplicationRecord
  include SortableByName

  belongs_to :competition
  has_secure_password

  schema_validations
end
