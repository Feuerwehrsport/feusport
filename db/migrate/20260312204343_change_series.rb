# frozen_string_literal: true

class ChangeSeries < ActiveRecord::Migration[7.2]
  def change
    add_column :score_results, :series_team_round_keys, :string, array: true, default: []
    add_column :score_results, :series_person_round_keys, :string, array: true, default: []

    drop_table :score_result_series_assessments
    drop_table :series_assessments
    drop_table :series_participations
    drop_table :series_rounds

    create_table 'series_person_assessments', id: :serial, force: :cascade do |t|
      t.integer 'round_id', null: false
      t.string 'discipline', limit: 3, null: false
      t.string 'key', null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index ['discipline'], name: 'index_series_person_assessments_on_discipline'
      t.index ['key'], name: 'index_series_person_assessments_on_key'
      t.index ['round_id'], name: 'index_series_person_assessments_on_round_id'
    end

    create_table 'series_person_participations', id: :serial, force: :cascade do |t|
      t.integer 'person_assessment_id', null: false
      t.integer 'cup_id', null: false
      t.integer 'person_id', null: false
      t.integer 'time', null: false
      t.integer 'points', default: 0, null: false
      t.integer 'rank', null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index ['cup_id'], name: 'index_series_person_participations_on_cup_id'
      t.index ['person_assessment_id'], name: 'index_series_person_participations_on_person_assessment_id'
      t.index ['person_id'], name: 'index_series_person_participations_on_person_id'
    end

    create_table 'series_rounds', id: :serial, force: :cascade do |t|
      t.string 'name', limit: 100, null: false
      t.integer 'year', null: false
      t.datetime 'created_at', precision: nil, null: false
      t.datetime 'updated_at', precision: nil, null: false
      t.integer 'full_cup_count', default: 4, null: false
      t.bigint 'kind_id'
      t.jsonb 'team_assessments_config_jsonb', default: []
      t.jsonb 'person_assessments_config_jsonb', default: []
      t.index ['kind_id'], name: 'index_series_rounds_on_kind_id'
    end

    create_table 'series_team_assessments', id: :serial, force: :cascade do |t|
      t.integer 'round_id', null: false
      t.string 'discipline', limit: 3, null: false
      t.string 'key', null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index ['discipline'], name: 'index_series_team_assessments_on_discipline'
      t.index ['key'], name: 'index_series_team_assessments_on_key'
      t.index ['round_id'], name: 'index_series_team_assessments_on_round_id'
    end

    create_table 'series_team_participations', id: :serial, force: :cascade do |t|
      t.integer 'team_assessment_id', null: false
      t.integer 'cup_id', null: false
      t.integer 'team_id', null: false
      t.integer 'team_number', null: false
      t.integer 'team_gender', null: false
      t.integer 'time', null: false
      t.integer 'points', default: 0, null: false
      t.integer 'rank', null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.index ['cup_id'], name: 'index_series_team_participations_on_cup_id'
      t.index ['team_assessment_id'], name: 'index_series_team_participations_on_team_assessment_id'
      t.index ['team_id'], name: 'index_series_team_participations_on_team_id'
      t.index ['team_number'], name: 'index_series_team_participations_on_team_number'
    end
  end
end
