# frozen_string_literal: true

class Series::AssessmentCalculation
  attr_reader :config, :competition

  delegate :entity_key, :key, :round, :round_key, :points_for_rank, :sort, :ranking_logic, :honor_ranking_logic,
           :min_participations_count, to: :config
  delegate :showable_cups, :team_assessments, :person_assessments, :full_cup_count, to: :round

  def initialize(config, competition)
    @config = config
    @competition = competition
  end

  def rows
    @rows ||= begin
      # Sortieren nach Config
      rows = entities.values.sort

      # Plätze vergeben
      calculate_ranks!(rows)

      # Besondere Beachtung der ersten drei Plätze und erneut vergeben
      if honor_ranking_logic.present?
        honor_rows = rows.select { |row| row.rank.present? && row.rank <= 3 }
                         .sort { |row, other| sort(row, other, logic_array: honor_ranking_logic) }
        calculate_ranks!(honor_rows, logic_array: honor_ranking_logic)
        rows.sort! { |row, other| sort(row, other, with_rank: true) }
      end
      rows
    end
  end

  protected

  def completed?
    @completed ||= full_cup_count == showable_cups(competition).count
  end

  def calculate_ranks!(rows, logic_array: ranking_logic)
    current_rank = 1
    last_row = nil
    rank = 1

    rows.each do |row|
      if completed? && row.participation_count < min_participations_count
        row.rank = nil
        next
      end

      current_rank = rank unless last_row && sort(row, last_row, logic_array:).zero?
      row.rank = current_rank

      last_row = row
      rank += 1
    end

    rows
  end

  def entities
    entity_key == :team ? teams : people
  end

  def people
    people = {}

    # Online-Einträge hinzufügen
    Series::PersonParticipation.where(person_assessment: person_assessments.where(key:)).find_each do |participation|
      next if participation.cup.dummy_for_competition.present?
      next unless participation.cup.in?(showable_cups(competition))

      people[participation.person_id] ||= Series::Person.new(
        config:, person: participation.person, round:,
      )
      people[participation.person_id].add_participation(participation)
    end

    # Einträge von heute hinzufügen
    results = competition.score_results.where("'#{round_key}' = ANY(series_person_round_keys)")
    results.each do |result|
      cup = Series::Cup.find_or_create_today!(round, competition)
      next unless cup.in?(showable_cups(competition))

      rows = result.rows
      convert_result_rows(rows) do |row, time, points, rank|
        participation = Series::PersonParticipation.new(
          cup:,
          person: row.entity.fire_sport_statistics_person_with_dummy,
          time:,
          points:,
          rank:,
        )

        people[participation.person_id] ||= Series::Person.new(
          config:, person: participation.person, round:,
        )
        people[participation.person_id].add_participation(participation)
      end
    end

    people
  end

  def teams
    teams = {}

    # Online-Einträge hinzufügen
    Series::TeamParticipation.where(team_assessment: team_assessments.where(key:)).find_each do |participation|
      next if participation.cup.dummy_for_competition.present?
      next unless participation.cup.in?(showable_cups(competition))

      teams[participation.entity_id] ||= Series::Team.new(
        config:, team: participation.team, team_number: participation.team_number,
        team_gender: participation.team_gender, round:
      )
      teams[participation.entity_id].add_participation(participation)
    end

    # Einträge von heute hinzufügen
    results = competition.score_results.where("'#{round_key}' = ANY(series_team_round_keys)")
    results.each do |result|
      cup = Series::Cup.find_or_create_today!(round, competition)
      next unless cup.in?(showable_cups(competition))

      rows = result.group_result.rows

      team_assessment = Series::TeamAssessment.find_or_initialize_by(
        discipline: result.discipline_key,
        round:,
      )

      convert_result_rows(rows) do |row, time, points, rank|
        participation = Series::TeamParticipation.new(
          cup:,
          team: row.entity.fire_sport_statistics_team_with_dummy,
          team_number: row.entity.number,
          time:,
          points:,
          rank:,
          team_assessment:,
        )

        teams[participation.entity_id] ||= Series::Team.new(
          config:, team: participation.team, team_number: participation.team_number,
          team_gender: participation.team_gender, round:
        )
        teams[participation.entity_id].add_participation(participation)
      end
    end
    teams
  end

  def convert_result_rows(result_rows)
    ranks = {}
    result_rows.each do |row|
      result_rows.each_with_index do |rank_row, rank|
        if (row <=> rank_row).zero?
          ranks[row] = (rank + 1)
          break
        end
      end
    end

    result_rows.each do |row|
      rank              = ranks[row]
      time              = row.result_entry.compare_time.try(:to_i) || Firesport::INVALID_TIME
      points            = points_for_rank[rank - 1] || 0
      yield(row, time, points, rank)
    end
  end
end
