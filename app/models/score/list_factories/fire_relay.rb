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
class Score::ListFactories::FireRelay < Score::ListFactory
  RelayRequest = Struct.new(:entity, :assessment_type, :assessment)

  def self.generator_possible?(discipline)
    discipline.like_fire_relay?
  end

  def preview_entries_count
    assessment_requests.sum(&:relay_count)
  end

  protected

  def perform_rows
    number_requests = {}
    assessment_requests.each do |request|
      (1..request.relay_count).each do |number|
        number_requests[number] ||= []
        relay = TeamRelay.find_or_create_by!(team: request.entity, number:)
        number_requests[number].push(
          RelayRequest.new(relay, request.assessment_type, request.assessment),
        )
      end
    end
    number_requests.values.flatten
  end
end
