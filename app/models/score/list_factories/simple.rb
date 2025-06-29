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
require 'timeout'

class Score::ListFactories::Simple < Score::ListFactory
  NUMBER_OF_THREADS = 10
  TIMEOUT_PER_MODE = 0.2

  def perform
    tracks = (1..list.track_count).to_a
    restriction_check = TeamListRestriction::Check.new(self)

    conditions_hash = list.conditions.group_by(&:track).transform_values do |conditions|
      conditions.flat_map(&:assessment_ids).uniq
    end

    rows = assessment_requests.to_a

    stack = nil
    threads = []

    loop do
      begin
        Timeout.timeout(TIMEOUT_PER_MODE) do
          NUMBER_OF_THREADS.times do |thread_index|
            threads[thread_index] = Thread.new do
              t_rows = rows.dup.shuffle
              t_restriction_check = restriction_check.dup

              thread_stack = try_next_track([], t_rows, tracks, t_restriction_check, 0, 1, conditions_hash)
              if thread_stack
                stack = thread_stack
                threads.each { |t| t.kill unless t == Thread.current }
              end
            end
          end
          threads.each(&:join)
        end
      rescue Timeout::Error
        threads.each(&:kill)
      end

      break unless stack.nil?

      restriction_check.softer_mode += 1

      return false if restriction_check.softer_mode > 10 # something went wrong
    end

    transaction do
      stack.each do |entity, run, track|
        create_list_entry(entity, run, track)
      end
    end
  end

  protected

  def try_next_track(stack, rows, tracks, t_restriction_check, track_index, run, conditions_hash)
    return false unless t_restriction_check.valid_from_factory?(stack)

    return stack if rows.empty?

    if track_index >= tracks.count
      run += 1
      track_index = 0
    end

    return false if run > 1000 # something went wrong

    track = tracks[track_index]

    next_track_rows, this_track_rows = rows.partition do |row|
      condition_assessment_ids = conditions_hash[track] || next
      !row.assessment_id.in?(condition_assessment_ids)
    end

    if this_track_rows.empty?
      new_stack = try_next_track(stack, rows.dup, tracks, t_restriction_check, track_index + 1, run, conditions_hash)
      return new_stack unless new_stack == false

      return false
    end

    this_track_rows.each_with_index do |entity, index|
      stack.push([entity, run, track])

      next_rows = this_track_rows.dup.tap { |i| i.delete_at(index) } + next_track_rows
      new_stack = try_next_track(stack, next_rows, tracks, t_restriction_check, track_index + 1, run, conditions_hash)
      return new_stack unless new_stack == false

      stack.pop
    end

    false
  end
end
