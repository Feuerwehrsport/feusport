# frozen_string_literal: true

# == Schema Information
#
# Table name: simple_accesses
#
#  id              :uuid             not null, primary key
#  name            :string           not null
#  password_digest :string
#  permission      :integer          default("full"), not null
#  score_list_ids  :uuid             default([]), not null, is an Array
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

  PERMISSIONS = { full: 0, results: 1, selected_results: 2 }.freeze
  enum :permission, PERMISSIONS, scopes: false, prefix: true

  include SelectableScoreLists

  schema_validations
  validates :name, length: { maximum: 50 }
  validates :password, length: { minimum: 8 }, allow_nil: true

  # Gast-Sessions laufen nach einer Stunde ohne Anfrage ab (verlängert wird im Controller)
  SESSION_TIMEOUT = 1.hour

  def self.session_key(competition)
    "simple_access_#{competition.id}"
  end

  # Gastzugang aus der Session, nil wenn keiner da oder abgelaufen
  def self.from_session(session, competition)
    data = session[session_key(competition)]
    return unless data.is_a?(Hash) && Time.zone.at(data['last_seen_at'].to_i) > SESSION_TIMEOUT.ago

    competition.simple_accesses.find_by(id: data['id'])
  end
end
