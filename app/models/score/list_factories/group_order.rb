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
class Score::ListFactories::GroupOrder < Score::ListFactory
  validates :single_competitors_first, inclusion: { in: [true, false] }, if: -> { step_reached?(:finish) }

  def self.generator_possible?(discipline)
    discipline.single_discipline?
  end

  def self.generator_params
    %i[single_competitors_first]
  end

  protected

  def perform_rows
    teams = {}
    requests = []
    sorted_assessment_requests = assessment_requests.sort_by do |request|
      if single_competitors_first?
        request.single_competitor_order + ((request.group_competitor_order + 1) * 100)
      else
        ((request.single_competitor_order + 1) * 100) + request.group_competitor_order
      end
    end
    sorted_assessment_requests.each do |request|
      teams[request.entity.team_id] ||= []
      teams[request.entity.team_id].push(request)
    end
    team_requests = sort_or_shuffle(teams)
    loop do
      break if team_requests.blank?

      requests.push(team_requests.first.shift)
      team_requests.rotate!
      team_requests.select!(&:present?)
    end
    requests
  end

  def sort_or_shuffle(hash)
    if team_shuffle?
      # team with most requests first
      hash.values.shuffle.sort_by(&:count).reverse
    else
      Team.where(id: hash.keys).reorder(:lottery_number).pluck(:id).map { |id| hash[id] }
    end
  end
end
