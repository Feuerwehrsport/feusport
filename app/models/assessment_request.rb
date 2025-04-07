# frozen_string_literal: true

# == Schema Information
#
# Table name: assessment_requests
#
#  id                      :uuid             not null, primary key
#  assessment_type         :integer          default("group_competitor"), not null
#  competitor_order        :integer          default(0), not null
#  entity_type             :string(100)      not null
#  group_competitor_order  :integer          default(0), not null
#  relay_count             :integer          default(1), not null
#  single_competitor_order :integer          default(0), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  assessment_id           :uuid             not null
#  entity_id               :uuid             not null
#
# Indexes
#
#  index_assessment_requests_on_assessment_id  (assessment_id)
#
# Foreign Keys
#
#  fk_rails_...  (assessment_id => assessments.id)
#
class AssessmentRequest < ApplicationRecord
  def self.fs_names
    %w[
      A1 A2 A3 A4
      B1 B2 B3 B4
      C1 C2 C3 C4
      D1 D2 D3 D4
    ]
  end

  def self.la_names
    [
      '1 Maschinist',
      '2 A-Länge',
      '3 Saugkorb',
      '4 B-Schlauch',
      '5 Strahlrohr links',
      '6 Verteiler',
      '7 Strahlrohr rechts',
    ]
  end

  def self.gs_names
    [
      '1 B-Schlauch',
      '2 Verteiler',
      '3 C-Schlauch',
      '4 Knoten',
      '5 D-Schlauch',
      '6 Läufer',
    ]
  end

  def self.short_names
    {
      'la' => [
        ['1', '(Ma)'],
        ['2', '(A)'],
        ['3', '(SK)'],
        ['4', '(B)'],
        ['5', '(SL)'],
        ['6', '(V)'],
        ['7', '(SR)'],
      ],
      'gs' => [
        ['1', '(B)'],
        ['2', '(V)'],
        ['3', '(C)'],
        ['4', '(Kn)'],
        ['5', '(D)'],
        ['6', '(Lä)'],
      ],
    }
  end

  belongs_to :assessment, touch: true
  belongs_to :entity, polymorphic: true
  enum :assessment_type, { group_competitor: 0, single_competitor: 1, out_of_competition: 2, competitor: 3 }

  schema_validations
  validates :group_competitor_order, :single_competitor_order, :relay_count,
            numericality: { greater_than_or_equal_to: 0 }

  after_initialize :assign_next_free_competitor_order
  before_save :set_valid_competitor_order

  scope :assessment_type, ->(type) { where(assessment_type: AssessmentRequest.assessment_types[type]) }
  scope :for_assessment, ->(assessment) do
                           where(entity_type: assessment.discipline.single_discipline? ? 'Person' : 'Team')
                         end

  def self.group_assessment_type_keys
    %i[group_competitor out_of_competition]
  end

  def self.possible_assessment_types(assessment)
    assessment.discipline.single_discipline? ? %i[group_competitor single_competitor out_of_competition] : [:competitor]
  end

  def type
    if group_competitor?
      I18n.t('assessment_types.group_competitor_order', competitor_order: group_competitor_order)
    elsif single_competitor?
      I18n.t('assessment_types.single_competitor_order', competitor_order: single_competitor_order)
    elsif out_of_competition?
      I18n.t('assessment_types.out_of_competition_order')
    elsif competitor?
      case assessment.discipline.key
      when 'fs'
        self.class.fs_names[competitor_order]
      when 'la'
        self.class.la_names[competitor_order]
      when 'gs'
        self.class.gs_names[competitor_order]
      end
    else
      0
    end
  end

  private

  def next_free_competitor_order(type)
    return 0 if entity.nil? || entity.is_a?(Team) || entity.team.nil?

    free = 1
    type_order = :"#{type}_competitor_order"
    assessment.requests.where(
      assessment_type: AssessmentRequest.assessment_types[:"#{type}_competitor"],
      entity: entity.team.people,
    ).where.not(type_order => 0).order(type_order).pluck(type_order).each do |existing|
      return free if free < existing

      free += 1
    end
    free
  end

  def set_valid_competitor_order
    if entity.is_a?(Team) || entity.team.nil?
      self.group_competitor_order = 0
      self.single_competitor_order = 0
    elsif group_competitor?
      self.group_competitor_order = next_free_competitor_order(:group) if group_competitor_order&.zero?
      self.single_competitor_order = 0
    elsif single_competitor?
      self.single_competitor_order = next_free_competitor_order(:single) if single_competitor_order&.zero?
      self.group_competitor_order = 0
    end
  end

  def assign_next_free_competitor_order
    return if persisted?

    self.group_competitor_order = next_free_competitor_order(:group) if group_competitor_order&.zero?
    self.single_competitor_order = next_free_competitor_order(:single) if single_competitor_order&.zero?
  end
end
