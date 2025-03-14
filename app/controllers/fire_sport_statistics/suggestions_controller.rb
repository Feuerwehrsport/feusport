# frozen_string_literal: true

class FireSportStatistics::SuggestionsController < ApplicationController
  def people
    suggestions = FireSportStatistics::Person.where(dummy: false).limit(10)
    suggestions = suggestions.where_name_like(params[:name]) if params[:name]
    suggestions = suggestions.order_by_gender(params[:gender]) if params[:gender]
    suggestions = suggestions.gender(params[:real_gender]) if params[:real_gender]
    if params[:team_name]
      suggestions = suggestions.order_by_teams(FireSportStatistics::Team.where(dummy: false)
        .where_name_like(params[:team_name]))
    end

    render json: suggestions.to_json(
      only: %i[id first_name last_name gender],
      include: [teams: { only: [:short] }],
    )
  end

  def teams
    suggestions = FireSportStatistics::Team.where(dummy: false).limit(10)
    if params[:name]
      suggestions = suggestions.where_name_like(params[:name])
      suggestions = suggestions.order(Arel.sql(<<~SQL.squish, params[:name], params[:name]))
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
end
