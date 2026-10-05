# frozen_string_literal: true

class ChangeSeriesPersonPointsCorrectionsNull < ActiveRecord::Migration[7.2]
  def change
    change_column_null :series_person_points_corrections, :competition_id, false
    change_column_null :series_person_points_corrections, :round_key, false
    change_column_null :series_person_points_corrections, :person_id, false
    change_column_null :series_person_points_corrections, :points_correction, false
    change_column_null :series_person_points_corrections, :points_correction_hint, false
  end
end
