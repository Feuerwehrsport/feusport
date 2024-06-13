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
      import_series_assessments
      import_series_participations

      translate_old_aggregate_types
    end
  end

  def translate_old_aggregate_types
    {
      'MVCup' => 'MvCup',
      'MVHindernisCup' => 'MvHindernisCup',
      'MVSteigerCup' => 'MvSteigerCup',
      'KPBautzen' => 'KpBautzen',
    }.each do |old_type, new_type|
      Series::Round.where(aggregate_type: old_type).update_all(aggregate_type: new_type)
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
        aggregate_type: round[:aggregate_type],
        full_cup_count: round[:full_cup_count],
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

  def import_series_assessments
    fetch('series/assessments') do |assessment|
      discipline = assessment[:discipline].to_sym
      discipline = :hb if discipline == :hw
      discipline = :zk if discipline == :zw

      Series::Assessment.create!(
        id: assessment[:id],
        name: assessment[:name],
        discipline:,
        round_id: assessment[:round_id].to_i,
        gender: assessment[:gender],
        type: assessment[:type],
      )
    end

    reset_autoincrement_id(Series::Assessment)
  end

  def import_series_participations
    fetch('series/participations') do |participation|
      Series::Participation.create!(
        id: participation[:id],
        points: participation[:points],
        rank: participation[:rank],
        time: participation[:time],
        cup_id: participation[:cup_id].to_i,
        assessment_id: participation[:assessment_id].to_i,
        type: participation[:type],
        team_id: participation[:team_id],
        team_number: participation[:team_number],
        person_id: participation[:person_id],
      )
    end

    reset_autoincrement_id(Series::Participation)
  end

  def people
    @people ||= []
  end

  def teams
    @teams ||= []
  end

  def destroy_old_imports
    Series::Participation.delete_all
    Series::Assessment.delete_all
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
