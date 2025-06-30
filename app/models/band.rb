# frozen_string_literal: true

# == Schema Information
#
# Table name: bands
#
#  id             :uuid             not null, primary key
#  gender         :integer          not null
#  name           :string(100)      not null
#  person_tags    :string           default([]), is an Array
#  position       :integer
#  team_tags      :string           default([]), is an Array
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  competition_id :uuid             not null
#
# Indexes
#
#  index_bands_on_competition_id           (competition_id)
#  index_bands_on_name_and_competition_id  (name,competition_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
class Band < ApplicationRecord
  include SortableByName

  GENDERS = { female: 0, male: 1, indifferent: 2 }.freeze

  enum :gender, GENDERS
  default_scope { order(:position) }

  belongs_to :competition, touch: true
  has_many :assessments, class_name: 'Assessment', dependent: :restrict_with_error
  has_many :teams, dependent: :restrict_with_error
  has_many :people, dependent: :restrict_with_error

  acts_as_list
  auto_strip_attributes :name

  schema_validations

  after_save :clean_tags

  def <=>(other)
    sort_by_position = position <=> other.position
    return sort_by_position unless sort_by_position == 0

    super
  end

  def translated_gender
    gender.present? ? I18n.t("gender.#{gender}") : ''
  end

  def destroy_possible?
    assessments.empty?
  end

  def person_tag_names=(names)
    self.person_tags = names.to_s.split(',').map(&:strip).compact_blank.sort
  end

  def person_tag_names
    (person_tags || []).sort.join(', ')
  end

  def team_tag_names=(names)
    self.team_tags = names.to_s.split(',').map(&:strip).compact_blank.sort
  end

  def team_tag_names
    (team_tags || []).sort.join(', ')
  end

  private

  def clean_tags
    people.each(&:save!) if saved_change_to_attribute?(:person_tags)
    teams.each(&:save!) if saved_change_to_attribute?(:team_tags)

    return unless saved_change_to_attribute?(:team_tags) || saved_change_to_attribute?(:person_tags)

    assessments.each { |assessment| assessment.results.each(&:save!) }
  end
end
