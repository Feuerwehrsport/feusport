# frozen_string_literal: true

# == Schema Information
#
# Table name: fire_sport_statistics_team_spellings
#
#  id         :bigint           not null, primary key
#  name       :string(100)      not null
#  short      :string(50)       not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  team_id    :integer          not null
#
# Indexes
#
#  index_fire_sport_statistics_team_spellings_on_team_id  (team_id)
#
class FireSportStatistics::TeamSpelling < ApplicationRecord
  include FireSportStatistics::TeamScopes
  belongs_to :team

  auto_strip_attributes :name, :short
  schema_validations
end
