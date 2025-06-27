# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.

# generated from version 20250626113556

module SchemaValidations
  extend ActiveSupport::Concern

  included do
    class_attribute :schema_validations_excluded_columns, default: %i[id created_at updated_at type]
    class_attribute :schema_validations_called, default: false

    if defined?(Rails::Railtie) && (Rails.env.development? || Rails.env.test?)
      TracePoint.trace(:end) do |t|
        if t.self.respond_to?(:schema_validations_called) && t.self < ApplicationRecord &&
           !t.self.schema_validations_called
          raise "#{t.self}: schema_validations or skip_schema_validations missing"
        end
      end
    end
  end

  class_methods do
    def schema_validations(exclude: [], schema_table_name: table_name)
      self.schema_validations_called = true
      self.schema_validations_excluded_columns += exclude.map(&:to_sym)
      send("dbv_#{schema_table_name}_validations", enums: defined_enums.keys.map(&:to_sym))
    end

    def skip_schema_validations
      self.schema_validations_called = true
    end


    def dbv_active_storage_attachments_validations(enums: [])
      belongs_to_presence_validations_for([:record_id, :blob_id])
      belongs_to_uniqueness_validations_for([["record_type", "record_id", "name", "blob_id"]])
      uniqueness_validations_for([["record_type", "record_id", "name", "blob_id"]])
      validates_with_filter :name, {:presence=>{}}
      validates_with_filter :record_type, {:presence=>{}}
      validates_with_filter :record_id, {:presence=>{}}
      validates_with_filter :blob_id, {:presence=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
    end

    def dbv_active_storage_blobs_validations(enums: [])
      belongs_to_presence_validations_for([:byte_size])
      belongs_to_uniqueness_validations_for([["key"]])
      uniqueness_validations_for([["key"]])
      validates_with_filter :key, {:presence=>{}}
      validates_with_filter :filename, {:presence=>{}}
      validates_with_filter :service_name, {:presence=>{}}
      validates_with_filter :byte_size, {:presence=>{}}
      validates_with_filter :byte_size, {:numericality=>{:allow_nil=>true}} unless enums.include?(:byte_size)
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
    end

    def dbv_active_storage_variant_records_validations(enums: [])
      belongs_to_presence_validations_for([:blob_id])
      belongs_to_uniqueness_validations_for([["blob_id", "variation_digest"]])
      uniqueness_validations_for([["blob_id", "variation_digest"]])
      validates_with_filter :blob_id, {:presence=>{}}
      validates_with_filter :variation_digest, {:presence=>{}}
    end

    def dbv_assessment_requests_validations(enums: [])
      belongs_to_presence_validations_for([:assessment_id, :entity_id, :assessment_type, :group_competitor_order, :relay_count, :single_competitor_order, :competitor_order])
      validates_with_filter :assessment_id, {:presence=>{}}
      validates_with_filter :entity_type, {:presence=>{}}
      validates_with_filter :entity_type, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :entity_id, {:presence=>{}}
      validates_with_filter :assessment_type, {:presence=>{}}
      validates_with_filter :assessment_type, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:assessment_type)
      validates_with_filter :group_competitor_order, {:presence=>{}}
      validates_with_filter :group_competitor_order, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:group_competitor_order)
      validates_with_filter :relay_count, {:presence=>{}}
      validates_with_filter :relay_count, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:relay_count)
      validates_with_filter :single_competitor_order, {:presence=>{}}
      validates_with_filter :single_competitor_order, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:single_competitor_order)
      validates_with_filter :competitor_order, {:presence=>{}}
      validates_with_filter :competitor_order, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:competitor_order)
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_assessments_validations(enums: [])
      belongs_to_presence_validations_for([:discipline_id, :band_id])
      validates_with_filter :forced_name, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :discipline_id, {:presence=>{}}
      validates_with_filter :band_id, {:presence=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_bands_validations(enums: [])
      belongs_to_presence_validations_for([:competition_id, :gender])
      belongs_to_uniqueness_validations_for([["name", "competition_id"]])
      uniqueness_validations_for([["name", "competition_id"]])
      validates_with_filter :competition_id, {:presence=>{}}
      validates_with_filter :gender, {:presence=>{}}
      validates_with_filter :gender, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:gender)
      validates_with_filter :name, {:presence=>{}}
      validates_with_filter :name, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :position, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:position)
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_certificates_templates_validations(enums: [])
      belongs_to_presence_validations_for([:competition_id])
      validates_with_filter :competition_id, {:presence=>{}}
      validates_with_filter :name, {:presence=>{}}
      validates_with_filter :name, {:length=>{:allow_nil=>true, :maximum=>200}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
      validates_with_filter :importable_for_me, {:inclusion=>{:in=>[true, false], :message=>:blank}}
      validates_with_filter :importable_for_others, {:inclusion=>{:in=>[true, false], :message=>:blank}}
    end

    def dbv_certificates_text_fields_validations(enums: [])
      belongs_to_presence_validations_for([:template_id, :size])
      validates_with_filter :template_id, {:presence=>{}}
      validates_with_filter :left, {:presence=>{}}
      validates_with_filter :top, {:presence=>{}}
      validates_with_filter :width, {:presence=>{}}
      validates_with_filter :height, {:presence=>{}}
      validates_with_filter :size, {:presence=>{}}
      validates_with_filter :size, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:size)
      validates_with_filter :key, {:presence=>{}}
      validates_with_filter :key, {:length=>{:allow_nil=>true, :maximum=>50}}
      validates_with_filter :align, {:presence=>{}}
      validates_with_filter :align, {:length=>{:allow_nil=>true, :maximum=>50}}
      validates_with_filter :text, {:length=>{:allow_nil=>true, :maximum=>200}}
      validates_with_filter :font, {:presence=>{}}
      validates_with_filter :font, {:length=>{:allow_nil=>true, :maximum=>20}}
      validates_with_filter :color, {:presence=>{}}
      validates_with_filter :color, {:length=>{:allow_nil=>true, :maximum=>20}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_changelogs_validations(enums: [])
      validates_with_filter :date, {:presence=>{}}
      validates_with_filter :date, {:date_in_db_range=>{}}
      validates_with_filter :title, {:presence=>{}}
      validates_with_filter :title, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :md, {:presence=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_competitions_validations(enums: [])
      belongs_to_presence_validations_for([:year, :registration_open])
      belongs_to_uniqueness_validations_for([["year", "slug"]])
      uniqueness_validations_for([["year", "slug"]])
      validates_with_filter :name, {:presence=>{}}
      validates_with_filter :name, {:length=>{:allow_nil=>true, :maximum=>50}}
      validates_with_filter :date, {:presence=>{}}
      validates_with_filter :date, {:date_in_db_range=>{}}
      validates_with_filter :place, {:presence=>{}}
      validates_with_filter :place, {:length=>{:allow_nil=>true, :maximum=>50}}
      validates_with_filter :slug, {:presence=>{}}
      validates_with_filter :slug, {:length=>{:allow_nil=>true, :maximum=>50}}
      validates_with_filter :year, {:presence=>{}}
      validates_with_filter :year, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:year)
      validates_with_filter :visible, {:inclusion=>{:in=>[true, false], :message=>:blank}}
      validates_with_filter :lottery_numbers, {:inclusion=>{:in=>[true, false], :message=>:blank}}
      validates_with_filter :show_bib_numbers, {:inclusion=>{:in=>[true, false], :message=>:blank}}
      validates_with_filter :preset_ran, {:inclusion=>{:in=>[true, false], :message=>:blank}}
      validates_with_filter :registration_open, {:presence=>{}}
      validates_with_filter :registration_open, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:registration_open)
      validates_with_filter :registration_open_until, {:date_in_db_range=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
      validates_with_filter :locked_at, {:date_time_in_db_range=>{}}
    end

    def dbv_disciplines_validations(enums: [])
      belongs_to_presence_validations_for([:competition_id])
      validates_with_filter :competition_id, {:presence=>{}}
      validates_with_filter :name, {:presence=>{}}
      validates_with_filter :name, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :short_name, {:presence=>{}}
      validates_with_filter :short_name, {:length=>{:allow_nil=>true, :maximum=>20}}
      validates_with_filter :key, {:presence=>{}}
      validates_with_filter :key, {:length=>{:allow_nil=>true, :maximum=>10}}
      validates_with_filter :single_discipline, {:inclusion=>{:in=>[true, false], :message=>:blank}}
      validates_with_filter :like_fire_relay, {:inclusion=>{:in=>[true, false], :message=>:blank}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_disseminators_validations(enums: [])
      validates_with_filter :name, {:presence=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_documents_validations(enums: [])
      validates_with_filter :title, {:presence=>{}}
      validates_with_filter :title, {:length=>{:allow_nil=>true, :maximum=>200}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_fire_sport_statistics_people_validations(enums: [])
      belongs_to_presence_validations_for([:gender])
      validates_with_filter :last_name, {:presence=>{}}
      validates_with_filter :last_name, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :first_name, {:presence=>{}}
      validates_with_filter :first_name, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :gender, {:presence=>{}}
      validates_with_filter :gender, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:gender)
      validates_with_filter :dummy, {:inclusion=>{:in=>[true, false], :message=>:blank}}
      validates_with_filter :personal_best_hb, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:personal_best_hb)
      validates_with_filter :personal_best_hl, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:personal_best_hl)
      validates_with_filter :personal_best_zk, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:personal_best_zk)
      validates_with_filter :saison_best_hb, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:saison_best_hb)
      validates_with_filter :saison_best_hl, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:saison_best_hl)
      validates_with_filter :saison_best_zk, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:saison_best_zk)
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_fire_sport_statistics_person_spellings_validations(enums: [])
      belongs_to_presence_validations_for([:gender, :person_id])
      validates_with_filter :last_name, {:presence=>{}}
      validates_with_filter :last_name, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :first_name, {:presence=>{}}
      validates_with_filter :first_name, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :gender, {:presence=>{}}
      validates_with_filter :gender, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:gender)
      validates_with_filter :person_id, {:presence=>{}}
      validates_with_filter :person_id, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:person_id)
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_fire_sport_statistics_publishings_validations(enums: [])
      belongs_to_presence_validations_for([:competition_id, :user_id])
      validates_with_filter :competition_id, {:presence=>{}}
      validates_with_filter :user_id, {:presence=>{}}
      validates_with_filter :published_at, {:date_time_in_db_range=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_fire_sport_statistics_team_associations_validations(enums: [])
      belongs_to_presence_validations_for([:person_id, :team_id])
      validates_with_filter :person_id, {:presence=>{}}
      validates_with_filter :person_id, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:person_id)
      validates_with_filter :team_id, {:presence=>{}}
      validates_with_filter :team_id, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:team_id)
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_fire_sport_statistics_team_spellings_validations(enums: [])
      belongs_to_presence_validations_for([:team_id])
      validates_with_filter :name, {:presence=>{}}
      validates_with_filter :name, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :short, {:presence=>{}}
      validates_with_filter :short, {:length=>{:allow_nil=>true, :maximum=>50}}
      validates_with_filter :team_id, {:presence=>{}}
      validates_with_filter :team_id, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:team_id)
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_fire_sport_statistics_teams_validations(enums: [])
      validates_with_filter :name, {:presence=>{}}
      validates_with_filter :name, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :short, {:presence=>{}}
      validates_with_filter :short, {:length=>{:allow_nil=>true, :maximum=>50}}
      validates_with_filter :dummy, {:inclusion=>{:in=>[true, false], :message=>:blank}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_information_requests_validations(enums: [])
      belongs_to_presence_validations_for([:competition_id, :user_id])
      validates_with_filter :competition_id, {:presence=>{}}
      validates_with_filter :user_id, {:presence=>{}}
      validates_with_filter :message, {:presence=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_people_validations(enums: [])
      belongs_to_presence_validations_for([:band_id, :registration_order])
      validates_with_filter :band_id, {:presence=>{}}
      validates_with_filter :last_name, {:presence=>{}}
      validates_with_filter :last_name, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :first_name, {:presence=>{}}
      validates_with_filter :first_name, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :bib_number, {:length=>{:allow_nil=>true, :maximum=>50}}
      validates_with_filter :registration_order, {:presence=>{}}
      validates_with_filter :registration_order, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:registration_order)
      validates_with_filter :fire_sport_statistics_person_id, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:fire_sport_statistics_person_id)
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_score_competition_result_references_validations(enums: [])
      belongs_to_presence_validations_for([:result_id, :competition_result_id])
      validates_with_filter :result_id, {:presence=>{}}
      validates_with_filter :competition_result_id, {:presence=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_score_competition_results_validations(enums: [])
      belongs_to_presence_validations_for([:competition_id])
      belongs_to_uniqueness_validations_for([["name", "competition_id"]])
      uniqueness_validations_for([["name", "competition_id"]])
      validates_with_filter :competition_id, {:presence=>{}}
      validates_with_filter :name, {:presence=>{}}
      validates_with_filter :name, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :result_type, {:presence=>{}}
      validates_with_filter :result_type, {:length=>{:allow_nil=>true, :maximum=>50}}
      validates_with_filter :hidden, {:inclusion=>{:in=>[true, false], :message=>:blank}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_score_list_assessments_validations(enums: [])
      belongs_to_presence_validations_for([:assessment_id, :list_id])
      validates_with_filter :assessment_id, {:presence=>{}}
      validates_with_filter :list_id, {:presence=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_score_list_condition_assessments_validations(enums: [])
      belongs_to_presence_validations_for([:condition_id, :assessment_id])
      validates_with_filter :condition_id, {:presence=>{}}
      validates_with_filter :assessment_id, {:presence=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_score_list_conditions_validations(enums: [])
      belongs_to_presence_validations_for([:competition_id, :track])
      validates_with_filter :competition_id, {:presence=>{}}
      validates_with_filter :track, {:presence=>{}}
      validates_with_filter :track, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:track)
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_score_list_entries_validations(enums: [])
      belongs_to_presence_validations_for([:competition_id, :list_id, :entity_id, :track, :run, :assessment_type, :assessment_id])
      validates_with_filter :competition_id, {:presence=>{}}
      validates_with_filter :list_id, {:presence=>{}}
      validates_with_filter :entity_type, {:presence=>{}}
      validates_with_filter :entity_type, {:length=>{:allow_nil=>true, :maximum=>50}}
      validates_with_filter :entity_id, {:presence=>{}}
      validates_with_filter :track, {:presence=>{}}
      validates_with_filter :track, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:track)
      validates_with_filter :run, {:presence=>{}}
      validates_with_filter :run, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:run)
      validates_with_filter :result_type, {:presence=>{}}
      validates_with_filter :result_type, {:length=>{:allow_nil=>true, :maximum=>20}}
      validates_with_filter :assessment_type, {:presence=>{}}
      validates_with_filter :assessment_type, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:assessment_type)
      validates_with_filter :assessment_id, {:presence=>{}}
      validates_with_filter :time, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:time)
      validates_with_filter :time_left_target, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:time_left_target)
      validates_with_filter :time_right_target, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:time_right_target)
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_score_list_factories_validations(enums: [])
      belongs_to_presence_validations_for([:competition_id, :discipline_id])
      validates_with_filter :competition_id, {:presence=>{}}
      validates_with_filter :session_id, {:presence=>{}}
      validates_with_filter :session_id, {:length=>{:allow_nil=>true, :maximum=>200}}
      validates_with_filter :discipline_id, {:presence=>{}}
      validates_with_filter :name, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :shortcut, {:length=>{:allow_nil=>true, :maximum=>50}}
      validates_with_filter :track_count, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:track_count)
      validates_with_filter :type, {:presence=>{}}
      validates_with_filter :best_count, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:best_count)
      validates_with_filter :status, {:length=>{:allow_nil=>true, :maximum=>50}}
      validates_with_filter :track, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:track)
      validates_with_filter :hidden, {:inclusion=>{:in=>[true, false], :message=>:blank}}
      validates_with_filter :single_competitors_first, {:inclusion=>{:in=>[true, false], :message=>:blank}}
      validates_with_filter :show_best_of_run, {:inclusion=>{:in=>[true, false], :message=>:blank}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_score_list_factory_assessments_validations(enums: [])
      belongs_to_presence_validations_for([:list_factory_id, :assessment_id])
      validates_with_filter :list_factory_id, {:presence=>{}}
      validates_with_filter :assessment_id, {:presence=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_score_list_factory_bands_validations(enums: [])
      belongs_to_presence_validations_for([:list_factory_id, :band_id])
      validates_with_filter :list_factory_id, {:presence=>{}}
      validates_with_filter :band_id, {:presence=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_score_list_print_generators_validations(enums: [])
      belongs_to_presence_validations_for([:competition_id])
      validates_with_filter :competition_id, {:presence=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_score_lists_validations(enums: [])
      belongs_to_presence_validations_for([:competition_id, :track_count])
      validates_with_filter :competition_id, {:presence=>{}}
      validates_with_filter :name, {:presence=>{}}
      validates_with_filter :name, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :shortcut, {:presence=>{}}
      validates_with_filter :shortcut, {:length=>{:allow_nil=>true, :maximum=>50}}
      validates_with_filter :track_count, {:presence=>{}}
      validates_with_filter :track_count, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:track_count)
      validates_with_filter :date, {:date_in_db_range=>{}}
      validates_with_filter :show_multiple_assessments, {:inclusion=>{:in=>[true, false], :message=>:blank}}
      validates_with_filter :hidden, {:inclusion=>{:in=>[true, false], :message=>:blank}}
      validates_with_filter :separate_target_times, {:inclusion=>{:in=>[true, false], :message=>:blank}}
      validates_with_filter :show_best_of_run, {:inclusion=>{:in=>[true, false], :message=>:blank}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_score_result_list_factories_validations(enums: [])
      belongs_to_presence_validations_for([:list_factory_id, :result_id])
      validates_with_filter :list_factory_id, {:presence=>{}}
      validates_with_filter :result_id, {:presence=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_score_result_lists_validations(enums: [])
      belongs_to_presence_validations_for([:list_id, :result_id])
      validates_with_filter :list_id, {:presence=>{}}
      validates_with_filter :result_id, {:presence=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_score_result_references_validations(enums: [])
      belongs_to_presence_validations_for([:result_id, :multi_result_id])
      validates_with_filter :result_id, {:presence=>{}}
      validates_with_filter :multi_result_id, {:presence=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_score_result_series_assessments_validations(enums: [])
      belongs_to_presence_validations_for([:result_id, :assessment_id])
      validates_with_filter :result_id, {:presence=>{}}
      validates_with_filter :assessment_id, {:presence=>{}}
      validates_with_filter :assessment_id, {:numericality=>{:allow_nil=>true}} unless enums.include?(:assessment_id)
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_score_results_validations(enums: [])
      belongs_to_presence_validations_for([:competition_id, :group_score_count, :group_run_count, :calculation_method, :multi_result_method])
      validates_with_filter :competition_id, {:presence=>{}}
      validates_with_filter :forced_name, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :group_assessment, {:inclusion=>{:in=>[true, false], :message=>:blank}}
      validates_with_filter :group_score_count, {:presence=>{}}
      validates_with_filter :group_score_count, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:group_score_count)
      validates_with_filter :group_run_count, {:presence=>{}}
      validates_with_filter :group_run_count, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:group_run_count)
      validates_with_filter :date, {:date_in_db_range=>{}}
      validates_with_filter :calculation_method, {:presence=>{}}
      validates_with_filter :calculation_method, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:calculation_method)
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
      validates_with_filter :image_key, {:length=>{:allow_nil=>true, :maximum=>10}}
      validates_with_filter :multi_result_method, {:presence=>{}}
      validates_with_filter :multi_result_method, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:multi_result_method)
      validates_with_filter :calculation_help, {:inclusion=>{:in=>[true, false], :message=>:blank}}
    end

    def dbv_series_assessments_validations(enums: [])
      belongs_to_presence_validations_for([:round_id, :gender])
      validates_with_filter :round_id, {:presence=>{}}
      validates_with_filter :round_id, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:round_id)
      validates_with_filter :discipline, {:presence=>{}}
      validates_with_filter :discipline, {:length=>{:allow_nil=>true, :maximum=>2}}
      validates_with_filter :name, {:presence=>{}}
      validates_with_filter :type, {:presence=>{}}
      validates_with_filter :type, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :gender, {:presence=>{}}
      validates_with_filter :gender, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:gender)
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_series_cups_validations(enums: [])
      belongs_to_presence_validations_for([:round_id])
      validates_with_filter :round_id, {:presence=>{}}
      validates_with_filter :round_id, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:round_id)
      validates_with_filter :competition_place, {:presence=>{}}
      validates_with_filter :competition_place, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :competition_date, {:presence=>{}}
      validates_with_filter :competition_date, {:date_in_db_range=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_series_participations_validations(enums: [])
      belongs_to_presence_validations_for([:assessment_id, :cup_id, :time, :points, :rank])
      validates_with_filter :assessment_id, {:presence=>{}}
      validates_with_filter :assessment_id, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:assessment_id)
      validates_with_filter :cup_id, {:presence=>{}}
      validates_with_filter :cup_id, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:cup_id)
      validates_with_filter :type, {:presence=>{}}
      validates_with_filter :type, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :team_id, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:team_id)
      validates_with_filter :team_number, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:team_number)
      validates_with_filter :person_id, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:person_id)
      validates_with_filter :time, {:presence=>{}}
      validates_with_filter :time, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:time)
      validates_with_filter :points, {:presence=>{}}
      validates_with_filter :points, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:points)
      validates_with_filter :rank, {:presence=>{}}
      validates_with_filter :rank, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:rank)
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_series_rounds_validations(enums: [])
      belongs_to_presence_validations_for([:year, :full_cup_count])
      validates_with_filter :name, {:presence=>{}}
      validates_with_filter :name, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :year, {:presence=>{}}
      validates_with_filter :year, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:year)
      validates_with_filter :aggregate_type, {:presence=>{}}
      validates_with_filter :aggregate_type, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :full_cup_count, {:presence=>{}}
      validates_with_filter :full_cup_count, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:full_cup_count)
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_simple_accesses_validations(enums: [])
      belongs_to_presence_validations_for([:competition_id])
      belongs_to_uniqueness_validations_for([["competition_id", "name"]])
      uniqueness_validations_for([["competition_id", "name"]])
      validates_with_filter :competition_id, {:presence=>{}}
      validates_with_filter :name, {:presence=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_solid_queue_blocked_executions_validations(enums: [])
      belongs_to_presence_validations_for([:job_id, :priority])
      belongs_to_uniqueness_validations_for([["job_id"]])
      uniqueness_validations_for([["job_id"]])
      validates_with_filter :job_id, {:presence=>{}}
      validates_with_filter :job_id, {:numericality=>{:allow_nil=>true}} unless enums.include?(:job_id)
      validates_with_filter :queue_name, {:presence=>{}}
      validates_with_filter :priority, {:presence=>{}}
      validates_with_filter :priority, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:priority)
      validates_with_filter :concurrency_key, {:presence=>{}}
      validates_with_filter :expires_at, {:presence=>{}}
      validates_with_filter :expires_at, {:date_time_in_db_range=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
    end

    def dbv_solid_queue_claimed_executions_validations(enums: [])
      belongs_to_presence_validations_for([:job_id])
      belongs_to_uniqueness_validations_for([["job_id"]])
      uniqueness_validations_for([["job_id"]])
      validates_with_filter :job_id, {:presence=>{}}
      validates_with_filter :job_id, {:numericality=>{:allow_nil=>true}} unless enums.include?(:job_id)
      validates_with_filter :process_id, {:numericality=>{:allow_nil=>true}} unless enums.include?(:process_id)
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
    end

    def dbv_solid_queue_failed_executions_validations(enums: [])
      belongs_to_presence_validations_for([:job_id])
      belongs_to_uniqueness_validations_for([["job_id"]])
      uniqueness_validations_for([["job_id"]])
      validates_with_filter :job_id, {:presence=>{}}
      validates_with_filter :job_id, {:numericality=>{:allow_nil=>true}} unless enums.include?(:job_id)
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
    end

    def dbv_solid_queue_jobs_validations(enums: [])
      belongs_to_presence_validations_for([:priority])
      validates_with_filter :queue_name, {:presence=>{}}
      validates_with_filter :class_name, {:presence=>{}}
      validates_with_filter :priority, {:presence=>{}}
      validates_with_filter :priority, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:priority)
      validates_with_filter :scheduled_at, {:date_time_in_db_range=>{}}
      validates_with_filter :finished_at, {:date_time_in_db_range=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_solid_queue_pauses_validations(enums: [])
      belongs_to_uniqueness_validations_for([["queue_name"]])
      uniqueness_validations_for([["queue_name"]])
      validates_with_filter :queue_name, {:presence=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
    end

    def dbv_solid_queue_processes_validations(enums: [])
      belongs_to_presence_validations_for([:pid])
      belongs_to_uniqueness_validations_for([["name", "supervisor_id"]])
      uniqueness_validations_for([["name", "supervisor_id"]])
      validates_with_filter :kind, {:presence=>{}}
      validates_with_filter :last_heartbeat_at, {:presence=>{}}
      validates_with_filter :last_heartbeat_at, {:date_time_in_db_range=>{}}
      validates_with_filter :supervisor_id, {:numericality=>{:allow_nil=>true}} unless enums.include?(:supervisor_id)
      validates_with_filter :pid, {:presence=>{}}
      validates_with_filter :pid, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:pid)
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :name, {:presence=>{}}
    end

    def dbv_solid_queue_ready_executions_validations(enums: [])
      belongs_to_presence_validations_for([:job_id, :priority])
      belongs_to_uniqueness_validations_for([["job_id"]])
      uniqueness_validations_for([["job_id"]])
      validates_with_filter :job_id, {:presence=>{}}
      validates_with_filter :job_id, {:numericality=>{:allow_nil=>true}} unless enums.include?(:job_id)
      validates_with_filter :queue_name, {:presence=>{}}
      validates_with_filter :priority, {:presence=>{}}
      validates_with_filter :priority, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:priority)
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
    end

    def dbv_solid_queue_recurring_executions_validations(enums: [])
      belongs_to_presence_validations_for([:job_id])
      belongs_to_uniqueness_validations_for([["job_id"], ["task_key", "run_at"]])
      uniqueness_validations_for([["job_id"], ["task_key", "run_at"]])
      validates_with_filter :job_id, {:presence=>{}}
      validates_with_filter :job_id, {:numericality=>{:allow_nil=>true}} unless enums.include?(:job_id)
      validates_with_filter :task_key, {:presence=>{}}
      validates_with_filter :run_at, {:presence=>{}}
      validates_with_filter :run_at, {:date_time_in_db_range=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
    end

    def dbv_solid_queue_recurring_tasks_validations(enums: [])
      belongs_to_uniqueness_validations_for([["key"]])
      uniqueness_validations_for([["key"]])
      validates_with_filter :key, {:presence=>{}}
      validates_with_filter :schedule, {:presence=>{}}
      validates_with_filter :command, {:length=>{:allow_nil=>true, :maximum=>2048}}
      validates_with_filter :priority, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:priority)
      validates_with_filter :static, {:inclusion=>{:in=>[true, false], :message=>:blank}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_solid_queue_scheduled_executions_validations(enums: [])
      belongs_to_presence_validations_for([:job_id, :priority])
      belongs_to_uniqueness_validations_for([["job_id"]])
      uniqueness_validations_for([["job_id"]])
      validates_with_filter :job_id, {:presence=>{}}
      validates_with_filter :job_id, {:numericality=>{:allow_nil=>true}} unless enums.include?(:job_id)
      validates_with_filter :queue_name, {:presence=>{}}
      validates_with_filter :priority, {:presence=>{}}
      validates_with_filter :priority, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:priority)
      validates_with_filter :scheduled_at, {:presence=>{}}
      validates_with_filter :scheduled_at, {:date_time_in_db_range=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
    end

    def dbv_solid_queue_semaphores_validations(enums: [])
      belongs_to_presence_validations_for([:value])
      belongs_to_uniqueness_validations_for([["key"]])
      uniqueness_validations_for([["key"]])
      validates_with_filter :key, {:presence=>{}}
      validates_with_filter :value, {:presence=>{}}
      validates_with_filter :value, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:value)
      validates_with_filter :expires_at, {:presence=>{}}
      validates_with_filter :expires_at, {:date_time_in_db_range=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_team_list_restrictions_validations(enums: [])
      belongs_to_presence_validations_for([:competition_id, :team1_id, :team2_id, :discipline_id, :restriction])
      belongs_to_uniqueness_validations_for([["team1_id", "team2_id", "discipline_id"]])
      uniqueness_validations_for([["team1_id", "team2_id", "discipline_id"]])
      validates_with_filter :competition_id, {:presence=>{}}
      validates_with_filter :team1_id, {:presence=>{}}
      validates_with_filter :team2_id, {:presence=>{}}
      validates_with_filter :discipline_id, {:presence=>{}}
      validates_with_filter :restriction, {:presence=>{}}
      validates_with_filter :restriction, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:restriction)
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_team_marker_values_validations(enums: [])
      belongs_to_presence_validations_for([:team_marker_id, :team_id])
      belongs_to_uniqueness_validations_for([["team_marker_id", "team_id"]])
      uniqueness_validations_for([["team_marker_id", "team_id"]])
      validates_with_filter :team_marker_id, {:presence=>{}}
      validates_with_filter :team_id, {:presence=>{}}
      validates_with_filter :boolean_value, {:inclusion=>{:in=>[true, false], :message=>:blank}}
      validates_with_filter :date_value, {:date_in_db_range=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_team_markers_validations(enums: [])
      belongs_to_presence_validations_for([:value_type])
      validates_with_filter :name, {:presence=>{}}
      validates_with_filter :name, {:length=>{:allow_nil=>true, :maximum=>20}}
      validates_with_filter :value_type, {:presence=>{}}
      validates_with_filter :value_type, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:value_type)
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_team_relays_validations(enums: [])
      belongs_to_presence_validations_for([:team_id, :number])
      validates_with_filter :team_id, {:presence=>{}}
      validates_with_filter :number, {:presence=>{}}
      validates_with_filter :number, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:number)
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_teams_validations(enums: [])
      belongs_to_presence_validations_for([:competition_id, :band_id, :number])
      belongs_to_uniqueness_validations_for([["competition_id", "band_id", "name", "number"]])
      uniqueness_validations_for([["competition_id", "band_id", "name", "number"]])
      validates_with_filter :competition_id, {:presence=>{}}
      validates_with_filter :band_id, {:presence=>{}}
      validates_with_filter :name, {:presence=>{}}
      validates_with_filter :name, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :number, {:presence=>{}}
      validates_with_filter :number, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:number)
      validates_with_filter :shortcut, {:presence=>{}}
      validates_with_filter :shortcut, {:length=>{:allow_nil=>true, :maximum=>50}}
      validates_with_filter :lottery_number, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:lottery_number)
      validates_with_filter :enrolled, {:inclusion=>{:in=>[true, false], :message=>:blank}}
      validates_with_filter :fire_sport_statistics_team_id, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:fire_sport_statistics_team_id)
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_user_access_requests_validations(enums: [])
      belongs_to_presence_validations_for([:competition_id, :sender_id])
      validates_with_filter :competition_id, {:presence=>{}}
      validates_with_filter :sender_id, {:presence=>{}}
      validates_with_filter :email, {:presence=>{}}
      validates_with_filter :email, {:length=>{:allow_nil=>true, :maximum=>200}}
      validates_with_filter :text, {:presence=>{}}
      validates_with_filter :drop_myself, {:inclusion=>{:in=>[true, false], :message=>:blank}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end

    def dbv_user_accesses_validations(enums: [])
      belongs_to_presence_validations_for([:user_id, :competition_id])
      validates_with_filter :user_id, {:presence=>{}}
      validates_with_filter :competition_id, {:presence=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
      validates_with_filter :registration_mail_info, {:inclusion=>{:in=>[true, false], :message=>:blank}}
    end

    def dbv_users_validations(enums: [])
      belongs_to_presence_validations_for([:sign_in_count, :failed_attempts])
      belongs_to_uniqueness_validations_for([["confirmation_token"], ["email"], ["reset_password_token"], ["unlock_token"]])
      uniqueness_validations_for([["confirmation_token"], ["email"], ["reset_password_token"], ["unlock_token"]])
      validates_with_filter :email, {:presence=>{}}
      validates_with_filter :email, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :encrypted_password, {:presence=>{}}
      validates_with_filter :encrypted_password, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :reset_password_token, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :reset_password_sent_at, {:date_time_in_db_range=>{}}
      validates_with_filter :remember_created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :sign_in_count, {:presence=>{}}
      validates_with_filter :sign_in_count, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:sign_in_count)
      validates_with_filter :current_sign_in_at, {:date_time_in_db_range=>{}}
      validates_with_filter :last_sign_in_at, {:date_time_in_db_range=>{}}
      validates_with_filter :current_sign_in_ip, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :last_sign_in_ip, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :confirmation_token, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :confirmed_at, {:date_time_in_db_range=>{}}
      validates_with_filter :confirmation_sent_at, {:date_time_in_db_range=>{}}
      validates_with_filter :unconfirmed_email, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :failed_attempts, {:presence=>{}}
      validates_with_filter :failed_attempts, {:numericality=>{:allow_nil=>true, :only_integer=>true, :greater_than_or_equal_to=>-2147483648, :less_than=>2147483648}} unless enums.include?(:failed_attempts)
      validates_with_filter :unlock_token, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :locked_at, {:date_time_in_db_range=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
      validates_with_filter :name, {:presence=>{}}
      validates_with_filter :name, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :user_manager, {:inclusion=>{:in=>[true, false], :message=>:blank}}
      validates_with_filter :competition_manager, {:inclusion=>{:in=>[true, false], :message=>:blank}}
    end

    def dbv_wkos_validations(enums: [])
      belongs_to_uniqueness_validations_for([["slug"]])
      uniqueness_validations_for([["slug"]])
      validates_with_filter :name, {:presence=>{}}
      validates_with_filter :name, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :slug, {:presence=>{}}
      validates_with_filter :slug, {:length=>{:allow_nil=>true, :maximum=>100}}
      validates_with_filter :subtitle, {:presence=>{}}
      validates_with_filter :description_md, {:presence=>{}}
      validates_with_filter :created_at, {:presence=>{}}
      validates_with_filter :created_at, {:date_time_in_db_range=>{}}
      validates_with_filter :updated_at, {:presence=>{}}
      validates_with_filter :updated_at, {:date_time_in_db_range=>{}}
    end


    def validates_with_filter(attribute, options)
      return if attribute.to_sym.in?(schema_validations_excluded_columns)

      validates attribute, options
    end

    def belongs_to_presence_validations_for(not_null_columns)
      reflect_on_all_associations(:belongs_to).each do |association|
        if not_null_columns.include?(association.foreign_key.to_sym)
          validates association.name, presence: true
          schema_validations_excluded_columns.push(association.foreign_key.to_sym)
        end
      end
    end

    def bad_uniqueness_validations_for(unique_indexes)
      unique_indexes.each do |names|
        names.each do |name|
          next if name.to_sym.in?(schema_validations_excluded_columns)

          raise "Unique index with where clause is outside the scope of this gem.\n\n" \
                "You can exclude this column: `schema_validations exclude: [:#{name}]`"
        end
      end
    end

    def belongs_to_uniqueness_validations_for(unique_indexes)
      reflect_on_all_associations(:belongs_to).each do |association|
        dbv_uniqueness_validations_for(unique_indexes, foreign_key: association.foreign_key.to_s,
                                                       column: association.name)
      end
    end

    def uniqueness_validations_for(unique_indexes)
      unique_indexes.each do |names|
        names.each do |name|
          dbv_uniqueness_validations_for(unique_indexes, foreign_key: name, column: name)
        end
      end
    end

    def dbv_uniqueness_validations_for(unique_indexes, foreign_key:, column:)
      unique_indexes.each do |names|
        next unless foreign_key.in?(names)
        next if column.to_sym.in?(schema_validations_excluded_columns)

        scope = (names - [foreign_key]).map(&:to_sym)
        options = { allow_nil: true }
        options[:scope] = scope if scope.any?
        options[:if] = (proc do |record|
          if scope.all? { |scope_sym| record.public_send(:"#{scope_sym}?") }
            record.public_send(:"#{foreign_key}_changed?")
          else
            false
          end
        end)

        validates column, uniqueness: options
      end
    end
  end

  class DateTimeInDbRangeValidator < ActiveModel::EachValidator
    def validate_each(record, attr_name, value)
      return if value.nil?
      return unless value.is_a?(DateTime) || value.is_a?(Time)
      return if value.year.between?(-4711, 294275) # see https://www.postgresql.org/docs/9.3/datatype-datetime.html

      record.errors.add(attr_name, :invalid, options)
    end
  end

  class DateInDbRangeValidator < ActiveModel::EachValidator
    def validate_each(record, attr_name, value)
      return if value.nil?
      return unless value.is_a?(Date)
      return if value.year.between?(-4711, 5874896) # see https://www.postgresql.org/docs/9.3/datatype-datetime.html

      record.errors.add(attr_name, :invalid, options)
    end
  end
end
