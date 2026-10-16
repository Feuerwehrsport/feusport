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
      # Nur Mannschaften dieser Wertungsgruppe und Spalten dieses Wettkampfs, sonst ließen sich fremde Werte schreiben
      next unless params[:team_marker_id].in?(team_markers.map(&:id))
      next unless params[:team_id].in?(teams.map(&:id))

      value = find_value_by(team_marker_id: params[:team_marker_id], team_id: params[:team_id])
      value.assign_attributes(params.slice(:boolean_value, :date_value, :string_value))
    end
  end

  def save
    TeamMarkerValue.transaction do
      team_marker_values.all?(&:save!)
    end
  rescue ActiveRecord::RecordInvalid
    false
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
