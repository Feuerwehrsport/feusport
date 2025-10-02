# frozen_string_literal: true

# == Schema Information
#
# Table name: team_markers
#
#  id             :uuid             not null, primary key
#  name           :string(20)       not null
#  value_type     :integer          default("boolean"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  competition_id :uuid
#
# Indexes
#
#  index_team_markers_on_competition_id  (competition_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
class TeamMarker < ApplicationRecord
  include SortableByName

  VALUE_TYPES = { boolean: 0, date: 1, string: 2 }.freeze
  enum :value_type, VALUE_TYPES, scopes: false, default: :boolean, prefix: true

  belongs_to :competition
  has_many :team_marker_values, dependent: :destroy

  schema_validations

  def self.create_example(competition)
    create(competition:, name: 'Angereist?', value_type: :boolean)
  end
end
