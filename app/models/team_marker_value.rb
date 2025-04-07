# frozen_string_literal: true

# == Schema Information
#
# Table name: team_marker_values
#
#  id             :uuid             not null, primary key
#  boolean_value  :boolean          default(FALSE), not null
#  date_value     :date
#  string_value   :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  team_id        :uuid             not null
#  team_marker_id :uuid             not null
#
# Indexes
#
#  index_team_marker_values_on_team_id                     (team_id)
#  index_team_marker_values_on_team_marker_id              (team_marker_id)
#  index_team_marker_values_on_team_marker_id_and_team_id  (team_marker_id,team_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (team_marker_id => team_markers.id)
#
class TeamMarkerValue < ApplicationRecord
  belongs_to :team_marker
  belongs_to :team

  delegate :competition, :name, :value_type_boolean?, :value_type_date?, :value_type_string?, to: :team_marker

  schema_validations
  validates :team, same_competition: true

  def value
    return I18n.t('a.yes') if value_type_boolean? && boolean_value?
    return I18n.t('a.no') if value_type_boolean? && !boolean_value?
    return I18n.l(date_value) if value_type_date? && date_value.present?

    string_value if value_type_string?
  end

  def value_present?
    return true if value_type_boolean? && boolean_value?
    return true if value_type_date? && date_value.present?
    return true if value_type_string? && string_value.present?

    false
  end
end
