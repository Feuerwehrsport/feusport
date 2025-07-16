# frozen_string_literal: true

Score::GroupResult = Struct.new(:result) do
  include Score::Resultable

  delegate :competition, :assessment, :name, :single_discipline?, to: :result

  def rows(*)
    @rows ||= if single_discipline?
                add_places(calculated_rows.sort)
              else
                add_places(result.generate_rows(group_result: true).sort)
              end
  end

  def calculated_rows
    team_scores = {}
    run_count = result.group_run_count
    score_count = result.group_score_count

    result.rows.each do |result_row|
      next unless result_row.list_entries.first.group_competitor?

      team = result_row.entity.team
      next if team.nil?

      team_scores[team.id] ||= Score::GroupResultRow.new(team, score_count, run_count, self)
      team_scores[team.id].add_result_row(result_row)
    end
    team_scores.values.sort
  end
end
