# frozen_string_literal: true

# == Schema Information
#
# Table name: score_list_factories
#
#  id                       :uuid             not null, primary key
#  best_count               :integer
#  hidden                   :boolean          default(FALSE), not null
#  name                     :string(100)
#  separate_target_times    :boolean
#  shortcut                 :string(50)
#  show_best_of_run         :boolean          default(FALSE), not null
#  single_competitors_first :boolean          default(TRUE), not null
#  status                   :string(50)
#  track                    :integer
#  track_count              :integer
#  type                     :string           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  before_list_id           :uuid
#  before_result_id         :uuid
#  competition_id           :uuid             not null
#  discipline_id            :uuid             not null
#  session_id               :string(200)      not null
#
# Indexes
#
#  index_score_list_factories_on_before_list_id    (before_list_id)
#  index_score_list_factories_on_before_result_id  (before_result_id)
#  index_score_list_factories_on_competition_id    (competition_id)
#  index_score_list_factories_on_discipline_id     (discipline_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
class Score::ListFactories::Best < Score::ListFactory
  validates :best_count, numericality: { greater_than_or_equal_to: 0 }, if: -> { step_reached?(:finish) }
  validates :before_result, presence: true, if: -> { step_reached?(:finish) }
  validate :result_assessments_match, if: -> { step_reached?(:finish) }

  def self.generator_params
    %i[before_result best_count]
  end

  def preview_entries_count
    [before_result.rows.count, best_count].min
  end

  protected

  def create_list_entry(result_row, run, track)
    any_list = result_row.list_entries.first
    list.entries.create!(
      competition:,
      entity: result_row.entity,
      run:,
      track:,
      assessment_type: any_list.assessment_type,
      assessment: result_row.result.assessment,
    )
  end

  def result_rows
    before_result.rows
  end

  def perform_rows
    all_rows = result_rows.dup
    result_rows = all_rows.shift(best_count.to_i)
    result_rows.push(all_rows.shift) while all_rows.present? && (result_rows.last <=> all_rows.first).zero?
    result_rows.reverse
  end

  private

  def result_assessments_match
    if assessments.length != 1
      errors.add(:before_result, 'Es darf nur eine Wertung ausgewählt werden')
    elsif before_result.present? && before_result.assessment != assessments.first
      errors.add(:before_result, 'muss mit jetziger Wertung übereinstimmen')
    end
  end
end
