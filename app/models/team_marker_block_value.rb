# frozen_string_literal: true

class TeamMarkerBlockValue
  include ActiveModel::Model

  attr_reader :band

  delegate :competition, to: :band

  def initialize(band:)
    @band = band
  end

  def team_marker_values
    @team_marker_values ||= []
  end

  def team_marker_values_attributes=(attributes)
    return unless attributes.is_a?(Hash)

    attributes.each_value do |params|
      next unless params.is_a?(Hash)
      next unless params.key?(:team_marker_id)
      next unless params.key?(:team_id)

      value = find_value_by(team_marker_id: params[:team_marker_id], team_id: params[:team_id])
      value.assign_attributes(params.slice(:boolean_value, :date_value, :string_value))
    end
  end

  def save
    TeamMarkerValue.transaction do
      team_marker_values.all?(&:save!)
    end
  end

  def persisted?
    true
  end

  def teams
    @teams ||= band.teams
  end

  def team_markers
    @team_markers ||= competition.team_markers.reorder(:name)
  end

  def find_value_by(team_id:, team_marker_id:)
    value = team_marker_values.find { |tmv| tmv.team_id == team_id && tmv.team_marker_id == team_marker_id }
    if value.blank?
      value = TeamMarkerValue.find_or_initialize_by(team_marker_id:, team_id:)
      @team_marker_values.push(value)
    end
    value
  end
end
