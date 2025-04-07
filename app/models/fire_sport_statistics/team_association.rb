# frozen_string_literal: true

# == Schema Information
#
# Table name: fire_sport_statistics_team_associations
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  person_id  :integer          not null
#  team_id    :integer          not null
#
# Indexes
#
#  index_fire_sport_statistics_team_associations_on_person_id  (person_id)
#  index_fire_sport_statistics_team_associations_on_team_id    (team_id)
#
class FireSportStatistics::TeamAssociation < ApplicationRecord
  belongs_to :person, class_name: 'FireSportStatistics::Person', inverse_of: :team_associations
  belongs_to :team, class_name: 'FireSportStatistics::Team', inverse_of: :team_associations

  schema_validations
end
