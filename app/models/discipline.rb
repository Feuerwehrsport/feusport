# frozen_string_literal: true

# == Schema Information
#
# Table name: disciplines
#
#  id                :uuid             not null, primary key
#  key               :string(10)       not null
#  like_fire_relay   :boolean          default(FALSE), not null
#  name              :string(100)      not null
#  short_name        :string(20)       not null
#  single_discipline :boolean          default(FALSE), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  competition_id    :uuid             not null
#
# Indexes
#
#  index_disciplines_on_competition_id  (competition_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
class Discipline < ApplicationRecord
  include SortableByName

  DISCIPLINES = %w[la hl hb gs fs other].freeze
  DEFAULT_NAMES = {
    la: 'Löschangriff Nass',
    hl: 'Hakenleitersteigen',
    hb: '100m-Hindernisbahn',
    gs: 'Gruppenstafette',
    fs: '4x100m-Hindernisstaffel',
    other: 'Andere',
  }.with_indifferent_access.freeze
  DEFAULT_SINGLE_DISCIPLINES = {
    la: false,
    hl: true,
    hb: true,
    gs: false,
    fs: false,
    other: false,
  }.with_indifferent_access.freeze

  belongs_to :competition, touch: true
  has_many :assessments, dependent: :restrict_with_error
  has_many :team_list_restrictions, dependent: :destroy

  scope :single_disciplines, -> { where(single_discipline: true) }
  auto_strip_attributes :name, :short_name

  schema_validations
  validates :key, inclusion: { in: DISCIPLINES }, allow_blank: true

  def destroy_possible?
    assessments.empty?
  end
end
