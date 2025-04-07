# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_04_07_093450) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "assessment_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "assessment_id", null: false
    t.string "entity_type", limit: 100, null: false
    t.uuid "entity_id", null: false
    t.integer "assessment_type", default: 0, null: false
    t.integer "group_competitor_order", default: 0, null: false
    t.integer "relay_count", default: 1, null: false
    t.integer "single_competitor_order", default: 0, null: false
    t.integer "competitor_order", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_id"], name: "index_assessment_requests_on_assessment_id"
  end

  create_table "assessments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "competition_id"
    t.string "forced_name", limit: 100
    t.uuid "discipline_id", null: false
    t.uuid "band_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["band_id"], name: "index_assessments_on_band_id"
    t.index ["competition_id"], name: "index_assessments_on_competition_id"
    t.index ["discipline_id"], name: "index_assessments_on_discipline_id"
  end

  create_table "bands", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "competition_id", null: false
    t.integer "gender", null: false
    t.string "name", limit: 100, null: false
    t.integer "position"
    t.string "person_tags", default: [], array: true
    t.string "team_tags", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["competition_id"], name: "index_bands_on_competition_id"
    t.index ["name", "competition_id"], name: "index_bands_on_name_and_competition_id", unique: true
  end

  create_table "certificates_templates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "competition_id", null: false
    t.string "name", limit: 200, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "importable_for_me", default: true, null: false
    t.boolean "importable_for_others", default: false, null: false
    t.index ["competition_id"], name: "index_certificates_templates_on_competition_id"
  end

  create_table "certificates_text_fields", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "template_id", null: false
    t.decimal "left", null: false
    t.decimal "top", null: false
    t.decimal "width", null: false
    t.decimal "height", null: false
    t.integer "size", null: false
    t.string "key", limit: 50, null: false
    t.string "align", limit: 50, null: false
    t.string "text", limit: 200
    t.string "font", limit: 20, default: "regular", null: false
    t.string "color", limit: 20, default: "000000", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["template_id"], name: "index_certificates_text_fields_on_template_id"
  end

  create_table "changelogs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.date "date", null: false
    t.string "title", limit: 100, null: false
    t.text "md", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "competitions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", limit: 50, null: false
    t.date "date", null: false
    t.string "place", limit: 50, null: false
    t.string "slug", limit: 50, null: false
    t.integer "year", null: false
    t.boolean "visible", default: false, null: false
    t.text "description"
    t.boolean "lottery_numbers", default: false, null: false
    t.boolean "show_bib_numbers", default: false, null: false
    t.boolean "preset_ran", default: false, null: false
    t.integer "registration_open", default: 0, null: false
    t.date "registration_open_until"
    t.string "flyer_headline"
    t.text "flyer_content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "locked_at"
    t.uuid "wko_id"
    t.index ["date"], name: "index_competitions_on_date"
    t.index ["wko_id"], name: "index_competitions_on_wko_id"
    t.index ["year", "slug"], name: "index_competitions_on_year_and_slug", unique: true
  end

  create_table "disciplines", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "competition_id", null: false
    t.string "name", limit: 100, null: false
    t.string "short_name", limit: 20, null: false
    t.string "key", limit: 10, null: false
    t.boolean "single_discipline", default: false, null: false
    t.boolean "like_fire_relay", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["competition_id"], name: "index_disciplines_on_competition_id"
  end

  create_table "disseminators", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "lfv"
    t.string "position"
    t.string "email_address"
    t.string "phone_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "documents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "competition_id"
    t.string "title", limit: 200, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["competition_id"], name: "index_documents_on_competition_id"
  end

  create_table "fire_sport_statistics_people", force: :cascade do |t|
    t.string "last_name", limit: 100, null: false
    t.string "first_name", limit: 100, null: false
    t.integer "gender", null: false
    t.boolean "dummy", default: false, null: false
    t.integer "personal_best_hb"
    t.string "personal_best_hb_competition"
    t.integer "personal_best_hl"
    t.string "personal_best_hl_competition"
    t.integer "personal_best_zk"
    t.string "personal_best_zk_competition"
    t.integer "saison_best_hb"
    t.string "saison_best_hb_competition"
    t.integer "saison_best_hl"
    t.string "saison_best_hl_competition"
    t.integer "saison_best_zk"
    t.string "saison_best_zk_competition"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "fire_sport_statistics_person_spellings", force: :cascade do |t|
    t.string "last_name", limit: 100, null: false
    t.string "first_name", limit: 100, null: false
    t.integer "gender", null: false
    t.integer "person_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["person_id"], name: "index_fire_sport_statistics_person_spellings_on_person_id"
  end

  create_table "fire_sport_statistics_publishings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "competition_id", null: false
    t.uuid "user_id", null: false
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "hint"
    t.index ["competition_id"], name: "index_fire_sport_statistics_publishings_on_competition_id"
    t.index ["user_id"], name: "index_fire_sport_statistics_publishings_on_user_id"
  end

  create_table "fire_sport_statistics_team_associations", force: :cascade do |t|
    t.integer "person_id", null: false
    t.integer "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["person_id"], name: "index_fire_sport_statistics_team_associations_on_person_id"
    t.index ["team_id"], name: "index_fire_sport_statistics_team_associations_on_team_id"
  end

  create_table "fire_sport_statistics_team_spellings", force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.string "short", limit: 50, null: false
    t.integer "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_fire_sport_statistics_team_spellings_on_team_id"
  end

  create_table "fire_sport_statistics_teams", force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.string "short", limit: 50, null: false
    t.boolean "dummy", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "best_scores", default: {}
  end

  create_table "people", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "competition_id"
    t.uuid "band_id", null: false
    t.string "last_name", limit: 100, null: false
    t.string "first_name", limit: 100, null: false
    t.uuid "team_id"
    t.string "bib_number", limit: 50
    t.integer "registration_order", default: 0, null: false
    t.string "tags", default: [], array: true
    t.integer "fire_sport_statistics_person_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "applicant_id"
    t.text "registration_hint"
    t.index ["band_id"], name: "index_people_on_band_id"
    t.index ["competition_id"], name: "index_people_on_competition_id"
    t.index ["fire_sport_statistics_person_id"], name: "index_people_on_fire_sport_statistics_person_id"
    t.index ["team_id"], name: "index_people_on_team_id"
  end

  create_table "score_competition_result_references", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "result_id", null: false
    t.uuid "competition_result_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["competition_result_id"], name: "index_score_competition_result_references_on_competition_result"
    t.index ["result_id"], name: "index_score_competition_result_references_on_result_id"
  end

  create_table "score_competition_results", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "competition_id", null: false
    t.string "name", limit: 100, null: false
    t.string "result_type", limit: 50, null: false
    t.boolean "hidden", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["competition_id"], name: "index_score_competition_results_on_competition_id"
    t.index ["name", "competition_id"], name: "index_score_competition_results_on_name_and_competition_id", unique: true
  end

  create_table "score_list_assessments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "assessment_id", null: false
    t.uuid "list_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_id"], name: "index_score_list_assessments_on_assessment_id"
    t.index ["list_id"], name: "index_score_list_assessments_on_list_id"
  end

  create_table "score_list_entries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "competition_id", null: false
    t.uuid "list_id", null: false
    t.string "entity_type", limit: 50, null: false
    t.uuid "entity_id", null: false
    t.integer "track", null: false
    t.integer "run", null: false
    t.string "result_type", limit: 20, default: "waiting", null: false
    t.integer "assessment_type", default: 0, null: false
    t.uuid "assessment_id", null: false
    t.integer "time"
    t.integer "time_left_target"
    t.integer "time_right_target"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_id"], name: "index_score_list_entries_on_assessment_id"
    t.index ["competition_id"], name: "index_score_list_entries_on_competition_id"
    t.index ["list_id"], name: "index_score_list_entries_on_list_id"
  end

  create_table "score_list_factories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "competition_id", null: false
    t.string "session_id", limit: 200, null: false
    t.uuid "discipline_id", null: false
    t.string "name", limit: 100
    t.string "shortcut", limit: 50
    t.integer "track_count"
    t.string "type", null: false
    t.uuid "before_result_id"
    t.uuid "before_list_id"
    t.integer "best_count"
    t.string "status", limit: 50
    t.integer "track"
    t.boolean "hidden", default: false, null: false
    t.boolean "separate_target_times"
    t.boolean "single_competitors_first", default: true, null: false
    t.boolean "show_best_of_run", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["before_list_id"], name: "index_score_list_factories_on_before_list_id"
    t.index ["before_result_id"], name: "index_score_list_factories_on_before_result_id"
    t.index ["competition_id"], name: "index_score_list_factories_on_competition_id"
    t.index ["discipline_id"], name: "index_score_list_factories_on_discipline_id"
  end

  create_table "score_list_factory_assessments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "list_factory_id", null: false
    t.uuid "assessment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_id"], name: "index_score_list_factory_assessments_on_assessment_id"
    t.index ["list_factory_id"], name: "index_score_list_factory_assessments_on_list_factory_id"
  end

  create_table "score_list_factory_bands", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "list_factory_id", null: false
    t.uuid "band_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["band_id"], name: "index_score_list_factory_bands_on_band_id"
    t.index ["list_factory_id"], name: "index_score_list_factory_bands_on_list_factory_id"
  end

  create_table "score_list_print_generators", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "competition_id", null: false
    t.text "print_list"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["competition_id"], name: "index_score_list_print_generators_on_competition_id"
  end

  create_table "score_lists", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "competition_id", null: false
    t.string "name", limit: 100, default: "", null: false
    t.string "shortcut", limit: 50, default: "", null: false
    t.integer "track_count", default: 2, null: false
    t.date "date"
    t.boolean "show_multiple_assessments", default: true, null: false
    t.boolean "hidden", default: false, null: false
    t.boolean "separate_target_times", default: false, null: false
    t.boolean "show_best_of_run", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["competition_id"], name: "index_score_lists_on_competition_id"
  end

  create_table "score_result_list_factories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "list_factory_id", null: false
    t.uuid "result_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["list_factory_id"], name: "index_score_result_list_factories_on_list_factory_id"
    t.index ["result_id"], name: "index_score_result_list_factories_on_result_id"
  end

  create_table "score_result_lists", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "list_id", null: false
    t.uuid "result_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["list_id"], name: "index_score_result_lists_on_list_id"
    t.index ["result_id"], name: "index_score_result_lists_on_result_id"
  end

  create_table "score_result_series_assessments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "result_id", null: false
    t.bigint "assessment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_id"], name: "index_score_result_series_assessments_on_assessment_id"
    t.index ["result_id"], name: "index_score_result_series_assessments_on_result_id"
  end

  create_table "score_results", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "competition_id", null: false
    t.string "forced_name", limit: 100
    t.boolean "group_assessment", default: false, null: false
    t.uuid "assessment_id", null: false
    t.uuid "double_event_result_id"
    t.integer "group_score_count", default: 6, null: false
    t.integer "group_run_count", default: 8, null: false
    t.date "date"
    t.integer "calculation_method", default: 0, null: false
    t.string "team_tags_included", default: [], array: true
    t.string "team_tags_excluded", default: [], array: true
    t.string "person_tags_included", default: [], array: true
    t.string "person_tags_excluded", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_id"], name: "index_score_results_on_assessment_id"
    t.index ["competition_id"], name: "index_score_results_on_competition_id"
    t.index ["double_event_result_id"], name: "index_score_results_on_double_event_result_id"
  end

  create_table "series_assessments", force: :cascade do |t|
    t.integer "round_id", null: false
    t.string "discipline", limit: 2, null: false
    t.string "name", default: "", null: false
    t.string "type", limit: 100, null: false
    t.integer "gender", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "series_cups", force: :cascade do |t|
    t.integer "round_id", null: false
    t.string "competition_place", limit: 100, null: false
    t.date "competition_date", null: false
    t.uuid "dummy_for_competition_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "series_participations", force: :cascade do |t|
    t.integer "assessment_id", null: false
    t.integer "cup_id", null: false
    t.string "type", limit: 100, null: false
    t.integer "team_id"
    t.integer "team_number"
    t.integer "person_id"
    t.integer "time", null: false
    t.integer "points", default: 0, null: false
    t.integer "rank", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "series_rounds", force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.integer "year", null: false
    t.string "aggregate_type", limit: 100, null: false
    t.integer "full_cup_count", default: 4, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "simple_accesses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "competition_id", null: false
    t.string "name", null: false
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["competition_id", "name"], name: "index_simple_accesses_on_competition_id_and_name", unique: true
    t.index ["competition_id"], name: "index_simple_accesses_on_competition_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "team_list_restrictions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "competition_id", null: false
    t.uuid "team1_id", null: false
    t.uuid "team2_id", null: false
    t.uuid "discipline_id", null: false
    t.integer "restriction", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["competition_id"], name: "index_team_list_restrictions_on_competition_id"
    t.index ["discipline_id"], name: "index_team_list_restrictions_on_discipline_id"
    t.index ["team1_id", "team2_id", "discipline_id"], name: "index_team_list_restrictions_unique", unique: true
    t.index ["team1_id"], name: "index_team_list_restrictions_on_team1_id"
    t.index ["team2_id"], name: "index_team_list_restrictions_on_team2_id"
  end

  create_table "team_marker_values", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "team_marker_id", null: false
    t.uuid "team_id", null: false
    t.boolean "boolean_value", default: false, null: false
    t.date "date_value"
    t.text "string_value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_team_marker_values_on_team_id"
    t.index ["team_marker_id", "team_id"], name: "index_team_marker_values_on_team_marker_id_and_team_id", unique: true
    t.index ["team_marker_id"], name: "index_team_marker_values_on_team_marker_id"
  end

  create_table "team_markers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "competition_id"
    t.string "name", limit: 20, null: false
    t.integer "value_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["competition_id"], name: "index_team_markers_on_competition_id"
  end

  create_table "team_relays", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "team_id", null: false
    t.integer "number", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_team_relays_on_team_id"
  end

  create_table "teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "competition_id", null: false
    t.uuid "band_id", null: false
    t.string "name", limit: 100, null: false
    t.integer "number", default: 1, null: false
    t.string "shortcut", limit: 50, default: "", null: false
    t.integer "lottery_number"
    t.boolean "enrolled", default: false, null: false
    t.string "tags", default: [], array: true
    t.integer "fire_sport_statistics_team_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "applicant_id"
    t.text "registration_hint"
    t.string "certificate_name"
    t.index ["band_id"], name: "index_teams_on_band_id"
    t.index ["competition_id", "band_id", "name", "number"], name: "index_teams_on_competition_id_and_band_id_and_name_and_number", unique: true
    t.index ["competition_id"], name: "index_teams_on_competition_id"
    t.index ["fire_sport_statistics_team_id"], name: "index_teams_on_fire_sport_statistics_team_id"
  end

  create_table "user_access_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "competition_id", null: false
    t.uuid "sender_id", null: false
    t.string "email", limit: 200, null: false
    t.text "text", null: false
    t.boolean "drop_myself", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["competition_id"], name: "index_user_access_requests_on_competition_id"
    t.index ["sender_id"], name: "index_user_access_requests_on_sender_id"
  end

  create_table "user_accesses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "competition_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "registration_mail_info", default: true, null: false
    t.index ["competition_id"], name: "index_user_accesses_on_competition_id"
    t.index ["user_id"], name: "index_user_accesses_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", limit: 100, null: false
    t.string "encrypted_password", limit: 100, null: false
    t.string "reset_password_token", limit: 100
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip", limit: 100
    t.string "last_sign_in_ip", limit: 100
    t.string "confirmation_token", limit: 100
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email", limit: 100
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token", limit: 100
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", limit: 100, null: false
    t.boolean "user_manager", default: false, null: false
    t.boolean "competition_manager", default: false, null: false
    t.string "phone_number"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "wkos", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.string "slug", limit: 100, null: false
    t.string "subtitle", null: false
    t.text "description_md", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_wkos_on_slug", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "assessment_requests", "assessments"
  add_foreign_key "assessments", "competitions"
  add_foreign_key "bands", "competitions"
  add_foreign_key "certificates_templates", "competitions"
  add_foreign_key "certificates_text_fields", "certificates_templates", column: "template_id"
  add_foreign_key "competitions", "wkos"
  add_foreign_key "disciplines", "competitions"
  add_foreign_key "documents", "competitions"
  add_foreign_key "fire_sport_statistics_publishings", "competitions"
  add_foreign_key "fire_sport_statistics_publishings", "users"
  add_foreign_key "people", "bands"
  add_foreign_key "people", "competitions"
  add_foreign_key "people", "teams"
  add_foreign_key "people", "users", column: "applicant_id"
  add_foreign_key "score_competition_result_references", "score_competition_results", column: "competition_result_id"
  add_foreign_key "score_competition_result_references", "score_results", column: "result_id"
  add_foreign_key "score_competition_results", "competitions"
  add_foreign_key "score_list_assessments", "assessments"
  add_foreign_key "score_list_assessments", "score_lists", column: "list_id"
  add_foreign_key "score_list_entries", "assessments"
  add_foreign_key "score_list_entries", "competitions"
  add_foreign_key "score_list_entries", "score_lists", column: "list_id"
  add_foreign_key "score_list_factories", "competitions"
  add_foreign_key "score_list_factory_assessments", "assessments"
  add_foreign_key "score_list_factory_assessments", "score_list_factories", column: "list_factory_id"
  add_foreign_key "score_list_factory_bands", "bands"
  add_foreign_key "score_list_factory_bands", "score_list_factories", column: "list_factory_id"
  add_foreign_key "score_list_print_generators", "competitions"
  add_foreign_key "score_lists", "competitions"
  add_foreign_key "score_result_list_factories", "score_list_factories", column: "list_factory_id"
  add_foreign_key "score_result_list_factories", "score_results", column: "result_id"
  add_foreign_key "score_result_lists", "score_lists", column: "list_id"
  add_foreign_key "score_result_lists", "score_results", column: "result_id"
  add_foreign_key "score_result_series_assessments", "score_results", column: "result_id"
  add_foreign_key "score_results", "assessments"
  add_foreign_key "score_results", "competitions"
  add_foreign_key "score_results", "score_results", column: "double_event_result_id"
  add_foreign_key "simple_accesses", "competitions"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "team_list_restrictions", "competitions"
  add_foreign_key "team_list_restrictions", "disciplines"
  add_foreign_key "team_list_restrictions", "teams", column: "team1_id"
  add_foreign_key "team_list_restrictions", "teams", column: "team2_id"
  add_foreign_key "team_marker_values", "team_markers"
  add_foreign_key "team_marker_values", "teams"
  add_foreign_key "team_markers", "competitions"
  add_foreign_key "team_relays", "teams"
  add_foreign_key "teams", "bands"
  add_foreign_key "teams", "competitions"
  add_foreign_key "teams", "users", column: "applicant_id"
  add_foreign_key "user_access_requests", "competitions"
  add_foreign_key "user_access_requests", "users", column: "sender_id"
  add_foreign_key "user_accesses", "competitions"
  add_foreign_key "user_accesses", "users"
end
