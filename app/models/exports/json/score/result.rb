# frozen_string_literal: true

Exports::Json::Score::Result = Struct.new(:result) do
  include Exports::Json::Base
  include Exports::ScoreResults

  def to_hash
    hash = {
      rows: build_data_rows(result, false, export_headers: true, full: true),
      gender: result.assessment&.band&.gender,
      band: result.assessment&.band&.name,
      discipline: result.discipline_key,
      series_person_round_keys: result.series_person_round_keys,
      series_team_round_keys: result.series_team_round_keys,
      name: result.name,
    }
    hash[:group_rows] = build_group_data_rows(result, full: true) if result.single_group_result?
    hash
  end
end
