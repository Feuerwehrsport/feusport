# frozen_string_literal: true

# == Schema Information
#
# Table name: fire_sport_statistics_person_spellings
#
#  id         :bigint           not null, primary key
#  first_name :string(100)      not null
#  gender     :integer          not null
#  last_name  :string(100)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  person_id  :integer          not null
#
# Indexes
#
#  index_fire_sport_statistics_person_spellings_on_person_id  (person_id)
#
class FireSportStatistics::PersonSpelling < ApplicationRecord
  include Genderable

  belongs_to :person, class_name: 'FireSportStatistics::Person', inverse_of: :spellings

  auto_strip_attributes :first_name, :last_name

  schema_validations
end
