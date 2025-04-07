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
class Score::ListFactories::TrackBandable < Score::ListFactories::GroupOrder
  validates :track, :bands, presence: true, if: -> { step_reached?(:finish) }
  validates :track, numericality: { only_integer: true, graeter_than: 0, less_than_or_equal_to: :track_count },
                    if: -> { step_reached?(:finish) }

  def self.generator_params
    %i[track bands single_competitors_first]
  end

  def perform
    band_rows = []
    other_rows = []
    perform_rows.each do |row|
      if row.entity.band.in?(bands)
        band_rows.push(row)
      else
        other_rows.push(row)
      end
    end
    for_run_and_track_for(band_rows, [track])
    for_run_and_track_for(other_rows, (1..list.track_count).to_a - [track])
  end
end
