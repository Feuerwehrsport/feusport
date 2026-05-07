# frozen_string_literal: true

# == Schema Information
#
# Table name: competition_features
#
#  id             :uuid             not null, primary key
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  competition_id :uuid             not null
#  feature_id     :uuid             not null
#
# Indexes
#
#  index_competition_features_on_competition_id  (competition_id)
#  index_competition_features_on_feature_id      (feature_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#  fk_rails_...  (feature_id => features.id)
#
class CompetitionFeature < ApplicationRecord
  belongs_to :feature, class_name: 'Feature'
  belongs_to :competition, class_name: 'Competition'

  schema_validations
end
