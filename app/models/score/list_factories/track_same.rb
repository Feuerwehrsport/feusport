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
class Score::ListFactories::TrackSame < Score::ListFactory
  validates :before_list, presence: true, if: -> { step_reached?(:finish) }
  validate :before_list_assessments_match, if: -> { step_reached?(:finish) }

  def self.generator_params
    [:before_list]
  end

  def perform
    transaction do
      before_list.entries.each do |entry|
        create_list_entry(entry, entry.run, entry.track)
      end
    end
  end

  private

  def before_list_assessments_match
    return unless before_list.blank? || before_list.assessment_ids.sort != assessment_ids.sort

    errors.add(:before_list, 'muss mit jetziger Wertung übereinstimmen')
  end
end
