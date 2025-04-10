# frozen_string_literal: true

Exports::Json::Score::Result = Struct.new(:result) do
  include Exports::Json::Base
  include Exports::ScoreResults

  def to_hash
    hash = {
      rows: build_data_rows(result, false, export_headers: true),
      gender: result.assessment.band.gender,
      band: result.assessment.band.name,
      discipline: result.discipline_key,
      name: result.name,
    }
    hash[:group_rows] = build_group_data_rows(result) if result.single_group_result?
    hash
  end
end
