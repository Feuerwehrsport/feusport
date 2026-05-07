# frozen_string_literal: true

# == Schema Information
#
# Table name: user_features
#
#  id         :uuid             not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  feature_id :uuid             not null
#  user_id    :uuid             not null
#
# Indexes
#
#  index_user_features_on_feature_id  (feature_id)
#  index_user_features_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (feature_id => features.id)
#  fk_rails_...  (user_id => users.id)
#
class UserFeature < ApplicationRecord
  belongs_to :feature, class_name: 'Feature'
  belongs_to :user, class_name: 'User'

  schema_validations
end
