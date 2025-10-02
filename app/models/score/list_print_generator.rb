# frozen_string_literal: true

# == Schema Information
#
# Table name: score_list_print_generators
#
#  id             :uuid             not null, primary key
#  print_list     :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  competition_id :uuid             not null
#
# Indexes
#
#  index_score_list_print_generators_on_competition_id  (competition_id)
#
# Foreign Keys
#
#  fk_rails_...  (competition_id => competitions.id)
#
class Score::ListPrintGenerator < ApplicationRecord
  include SortableByName

  belongs_to :competition, touch: true

  schema_validations
  validate :check_print_list

  def possible_lists
    @possible_lists ||= competition.score_lists
  end

  def print_list_extended
    print_list_lines.map do |line|
      case line
      when /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i
        possible_lists.find_by(id: line)
      when 'column', 'page'
        line
      end
    end.compact_blank
  end

  def name
    print_list_extended.select { |i| i.is_a?(Score::List) }.map(&:name).join(', ')
  end

  protected

  def print_list_lines
    print_list.to_s.lines.map(&:strip).compact_blank
  end

  def check_print_list
    lines = print_list_lines.select do |line|
      case line
      when /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i
        possible_lists.exists?(id: line)
      when 'column', 'page'
        true
      else
        errors.add(:print_list, :invalid)
      end
    end
    self.print_list = lines.join("\n")
  end
end
