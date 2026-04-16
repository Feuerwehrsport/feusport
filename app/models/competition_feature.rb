# frozen_string_literal: true

class CompetitionFeature < ApplicationRecord
  belongs_to :feature, class_name: 'Feature'
  belongs_to :competition, class_name: 'Competition'

  schema_validations
end
