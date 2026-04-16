# frozen_string_literal: true

# == Schema Information
#
# Table name: features
#
#  id         :uuid             not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Feature < ApplicationRecord
  has_many :user_features, class_name: 'UserFeature', dependent: :destroy
  has_many :users, class_name: 'User', through: :user_features
  has_many :competition_features, class_name: 'CompetitionFeature', dependent: :destroy
  has_many :competitions, class_name: 'Competition', through: :competition_features

  default_scope { reorder(:name) }

  schema_validations
end
