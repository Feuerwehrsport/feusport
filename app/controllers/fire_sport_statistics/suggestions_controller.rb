# frozen_string_literal: true

class FireSportStatistics::SuggestionsController < ApplicationController
  # Das JS fragt bei jeder Eingabe (verzögert) nach, ein leeres Ergebnis blendet die Vorschläge nur aus
  rate_limit to: 100, within: 1.minute, with: -> { render json: [] }

  def people
    name = string_param(:name)
    team_name = string_param(:team_name)
    gender = string_param(:gender)
    real_gender = string_param(:real_gender)

    suggestions = FireSportStatistics::Person.where(dummy: false).limit(10)
    suggestions = suggestions.where_name_like(name) if name
    suggestions = suggestions.order_by_gender(gender) if gender
    suggestions = suggestions.gender(real_gender) if real_gender
    if team_name
      suggestions = suggestions.order_by_teams(FireSportStatistics::Team.where(dummy: false)
        .where_name_like(team_name))
    end

    render json: suggestions.to_json(
      only: %i[id first_name last_name gender],
      include: [{ teams: { only: [:short] } }],
    )
  end

  def teams
    name = string_param(:name)

    suggestions = FireSportStatistics::Team.where(dummy: false).limit(10)
    if name
      suggestions = suggestions.where_name_like(name)
      suggestions = suggestions.order(Arel.sql(<<~SQL.squish, name, name))
        GREATEST(
            similarity(fire_sport_statistics_teams.name, ?),
            similarity(fire_sport_statistics_teams.short, ?)
        ) DESC
      SQL
    end

    render json: suggestions.to_json(
      only: %i[id name short federal_state_id],
    )
  end

  private

  # Nur Strings (Arrays/Hashes führten zu 500), auf 100 Zeichen gekürzt
  def string_param(key)
    value = params[key]
    # Namensspalten sind auf 100 Zeichen begrenzt, längere Eingaben machen die Suche nur teurer
    value[0, 100] if value.is_a?(String)
  end
end
