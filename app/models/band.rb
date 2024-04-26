# frozen_string_literal: true

class Band < ApplicationRecord
  # TODO: include Taggable
  GENDERS = { female: 0, male: 1, indifferent: 2 }.freeze
  GENDER_KEYS = GENDERS.keys.freeze

  enum gender: GENDERS
  scope :gender, ->(gender) { where(gender: GENDERS[gender.to_sym]) }
  default_scope { order(:position) }

  belongs_to :competition
  has_many :assessments, class_name: 'Assessment', dependent: :restrict_with_error
  # TODO: has_many :teams, dependent: :restrict_with_error
  # TODO: has_many :people, dependent: :restrict_with_error
  # TODO: has_and_belongs_to_many :score_list_factories, class_name: 'Score::ListFactory'

  acts_as_list

  schema_validations exclude: [:gender]

  # TODO: after_update do
  # TODO:   TagReference.all.where(taggable_type: 'Person', taggable_id: people).where.not(id: tags).delete_all
  # TODO:   TagReference.all.where(taggable_type: 'Team', taggable_id: teams).where.not(id: tags).delete_all
  # TODO: end

  def tag_names=(names)
    self.tags = names.to_s.split(',').map(&:strip).compact_blank
  end

  def tag_names
    (tags || []).sort.join(', ')
  end

  def translated_gender
    gender.present? ? I18n.t("gender.#{gender}") : ''
  end

  def destroy_possible?
    assessments.empty?
  end
end
