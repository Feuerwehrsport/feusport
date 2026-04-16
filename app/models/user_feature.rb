# frozen_string_literal: true

class UserFeature < ApplicationRecord
  belongs_to :feature, class_name: 'Feature'
  belongs_to :user, class_name: 'User'

  schema_validations
end
