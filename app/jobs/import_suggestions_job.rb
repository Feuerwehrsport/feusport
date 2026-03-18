# frozen_string_literal: true

require 'net/http'
require 'json'

class ImportSuggestionsJob < ApplicationJob
  def perform
    ActiveRecord::Base.transaction do
      destroy_old_imports
      import_people
      import_teams
      import_team_members
      import_team_spellings
      import_person_spellings

      import_series_rounds
      import_series_cups
      import_series_team_assessments
      import_series_team_participations
      import_series_person_assessments
      import_series_person_participations
    end
  end

  protected

  def reset_autoincrement_id(klass)
    next_id = (klass.maximum(:id) || 0) + 1
    ActiveRecord::Base.connection.execute("ALTER SEQUENCE #{klass.table_name}_id_seq RESTART WITH #{next_id}")
  end

  def import_people
    fetch(:people, extended: 1) do |person|
      people[person[:id].to_i] = FireSportStatistics::Person.create!(
        id: person[:id],
        last_name: person[:last_name],
        first_name: person[:first_name],
        gender: person[:gender],
        personal_best_hb: person[:best_scores].dig('pb', 'hb', 0),
        personal_best_hb_competition: person[:best_scores].dig('pb', 'hb', 1),
        personal_best_hl: person[:best_scores].dig('pb', 'hl', 0),
        personal_best_hl_competition: person[:best_scores].dig('pb', 'hl', 1),
        personal_best_zk: person[:best_scores].dig('pb', 'zk', 0),
        personal_best_zk_competition: person[:best_scores].dig('pb', 'zk', 1),
        saison_best_hb: person[:best_scores].dig('sb', 'hb', 0),
        saison_best_hb_competition: person[:best_scores].dig('sb', 'hb', 1),
        saison_best_hl: person[:best_scores].dig('sb', 'hl', 0),
        saison_best_hl_competition: person[:best_scores].dig('sb', 'hl', 1),
        saison_best_zk: person[:best_scores].dig('sb', 'zk', 0),
        saison_best_zk_competition: person[:best_scores].dig('sb', 'zk', 1),
      )
    end

    reset_autoincrement_id(FireSportStatistics::Person)
  end

  def import_teams
    fetch(:teams) do |team|
      teams[team[:id].to_i] = FireSportStatistics::Team.create!(
        id: team[:id],
        name: team[:name],
        short: team[:shortcut],
        best_scores: team[:best_scores] || {},
      )
    end

    reset_autoincrement_id(FireSportStatistics::Team)
  end

  def import_team_members
    fetch(:team_members) do |association|
      FireSportStatistics::TeamAssociation.create!(
        person: people[association[:person_id].to_i],
        team: teams[association[:team_id].to_i],
      )
    end

    reset_autoincrement_id(FireSportStatistics::TeamAssociation)
  end

  def import_team_spellings
    fetch(:team_spellings) do |spelling|
      FireSportStatistics::TeamSpelling.create!(
        team: teams[spelling[:team_id].to_i],
        name: spelling[:name],
        short: spelling[:shortcut],
      )
    end

    reset_autoincrement_id(FireSportStatistics::TeamSpelling)
  end

  def import_person_spellings
    fetch(:person_spellings) do |spelling|
      FireSportStatistics::PersonSpelling.create!(
        person: people[spelling[:person_id].to_i],
        last_name: spelling[:last_name],
        first_name: spelling[:first_name],
        gender: spelling[:gender],
      )
    end

    reset_autoincrement_id(FireSportStatistics::PersonSpelling)
  end

  def import_series_rounds
    fetch('series/rounds') do |round|
      Series::Round.create!(
        id: round[:id],
        name: round[:name],
        year: round[:year],
        full_cup_count: round[:full_cup_count],
        team_assessments_config_jsonb: round[:team_assessments_configs],
        person_assessments_config_jsonb: round[:person_assessments_configs],
      )
    end

    reset_autoincrement_id(Series::Round)
  end

  def import_series_cups
    fetch('series/cups') do |cup|
      Series::Cup.create!(
        id: cup[:id],
        round_id: cup[:round_id].to_i,
        competition_place: cup[:place],
        competition_date: cup[:date],
      )
    end

    reset_autoincrement_id(Series::Cup)
  end

  def import_series_team_assessments
    fetch('series/team_assessments') do |assessment|
      discipline = assessment[:discipline].to_sym
      discipline = :hb if discipline == :hw
      discipline = :zk if discipline == :zw

      Series::TeamAssessment.create!(
        id: assessment[:id],
        key: assessment[:key],
        discipline:,
        round_id: assessment[:round_id].to_i,
      )
    end

    reset_autoincrement_id(Series::TeamAssessment)
  end

  def import_series_person_assessments
    fetch('series/person_assessments') do |assessment|
      discipline = assessment[:discipline].to_sym
      discipline = :hb if discipline == :hw
      discipline = :zk if discipline == :zw

      Series::PersonAssessment.create!(
        id: assessment[:id],
        key: assessment[:key],
        discipline:,
        round_id: assessment[:round_id].to_i,
      )
    end

    reset_autoincrement_id(Series::PersonAssessment)
  end

  def import_series_team_participations
    fetch('series/team_participations') do |participation|
      Series::TeamParticipation.create!(
        id: participation[:id],
        points: participation[:points],
        rank: participation[:rank],
        time: participation[:time],
        cup_id: participation[:cup_id].to_i,
        team_assessment_id: participation[:team_assessment_id].to_i,
        team_id: participation[:team_id],
        team_number: participation[:team_number],
        team_gender: participation[:team_gender],
      )
    end

    reset_autoincrement_id(Series::TeamParticipation)
  end

  def import_series_person_participations
    fetch('series/person_participations') do |participation|
      Series::PersonParticipation.create!(
        id: participation[:id],
        points: participation[:points],
        rank: participation[:rank],
        time: participation[:time],
        cup_id: participation[:cup_id].to_i,
        person_assessment_id: participation[:person_assessment_id].to_i,
        person_id: participation[:person_id],
      )
    end

    reset_autoincrement_id(Series::PersonParticipation)
  end

  def people
    @people ||= []
  end

  def teams
    @teams ||= []
  end

  def destroy_old_imports
    Series::PersonParticipation.delete_all
    Series::TeamParticipation.delete_all
    Series::PersonAssessment.delete_all
    Series::TeamAssessment.delete_all
    Series::Cup.delete_all
    Series::Round.delete_all

    FireSportStatistics::TeamAssociation.delete_all
    FireSportStatistics::TeamSpelling.delete_all
    FireSportStatistics::PersonSpelling.delete_all
    FireSportStatistics::Team.delete_all
    FireSportStatistics::Person.delete_all
  end

  def fetch(type, params = nil)
    json_object = handle_response(conn.get("/api/#{type}?#{params&.to_query}"))

    json_object.fetch(type.to_s.tr('/', '_')).each do |entry|
      yield(entry.with_indifferent_access)
    end
  end

  def handle_response(response)
    JSON.parse(response.body)
  end

  def conn
    @conn ||= begin
      http = Net::HTTP.new('feuerwehrsport-statistik.de', 443)
      http.use_ssl = true
      http
    end
  end
end
