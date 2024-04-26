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

ActiveRecord::Schema[7.0].define(version: 2024_04_26_063157) do
  # These are extensions that must be enabled in order to support this database
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
    t.uuid "competition_id", null: false
    t.uuid "assessment_id", null: false
    t.string "entity_type", limit: 100, null: false
    t.integer "entity_id", null: false
    t.integer "assessment_type", default: 0, null: false
    t.integer "group_competitor_order", default: 0, null: false
    t.integer "relay_count", default: 1, null: false
    t.integer "single_competitor_order", default: 0, null: false
    t.integer "competitor_order", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_id"], name: "index_assessment_requests_on_assessment_id"
    t.index ["competition_id"], name: "index_assessment_requests_on_competition_id"
  end

  create_table "assessments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "competition_id"
    t.string "name", limit: 100, null: false
    t.uuid "discipline_id", null: false
    t.uuid "band_id", null: false
    t.string "tags", default: [], array: true
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
    t.string "tags", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["competition_id"], name: "index_bands_on_competition_id"
  end

  create_table "certificates_templates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "competition_id", null: false
    t.string "name", limit: 200
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "competitions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "name", limit: 50, null: false
    t.date "date", null: false
    t.string "locality", limit: 50, null: false
    t.string "slug", limit: 50, null: false
    t.integer "year", null: false
    t.boolean "visible", default: false, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_competitions_on_date"
    t.index ["user_id"], name: "index_competitions_on_user_id"
    t.index ["year", "slug"], name: "index_competitions_on_year_and_slug", unique: true
  end

  create_table "delayed_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
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

  create_table "documents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "competition_id"
    t.string "title", limit: 200, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["competition_id"], name: "index_documents_on_competition_id"
  end

  create_table "people", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "competition_id"
    t.uuid "band_id", null: false
    t.string "last_name", limit: 100, null: false
    t.string "first_name", limit: 100, null: false
    t.uuid "team_id"
    t.string "bib_number", limit: 50, default: "", null: false
    t.integer "registration_order", default: 0, null: false
    t.string "tags", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["band_id"], name: "index_people_on_band_id"
    t.index ["competition_id"], name: "index_people_on_competition_id"
    t.index ["team_id"], name: "index_people_on_team_id"
  end

  create_table "score_competition_results", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "competition_id", null: false
    t.uuid "band_id", null: false
    t.string "name", limit: 100
    t.string "result_type", limit: 50
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["band_id"], name: "index_score_competition_results_on_band_id"
    t.index ["competition_id"], name: "index_score_competition_results_on_competition_id"
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
    t.integer "entity_id", null: false
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
    t.boolean "separate_target_times", default: false, null: false
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
    t.string "tags", default: [], array: true
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

  create_table "score_results", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "competition_id", null: false
    t.string "name", limit: 100, default: "", null: false
    t.boolean "group_assessment", default: false, null: false
    t.uuid "assessment_id", null: false
    t.uuid "double_event_result_id"
    t.string "type", limit: 50, default: "Score::Result", null: false
    t.integer "group_score_count"
    t.integer "group_run_count"
    t.date "date"
    t.integer "calculation_method", default: 0, null: false
    t.string "tags", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_id"], name: "index_score_results_on_assessment_id"
    t.index ["competition_id"], name: "index_score_results_on_competition_id"
    t.index ["double_event_result_id"], name: "index_score_results_on_double_event_result_id"
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["band_id"], name: "index_teams_on_band_id"
    t.index ["competition_id"], name: "index_teams_on_competition_id"
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
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "assessment_requests", "assessments"
  add_foreign_key "assessment_requests", "competitions"
  add_foreign_key "assessments", "competitions"
  add_foreign_key "bands", "competitions"
  add_foreign_key "certificates_templates", "competitions"
  add_foreign_key "certificates_text_fields", "certificates_templates", column: "template_id"
  add_foreign_key "competitions", "users"
  add_foreign_key "disciplines", "competitions"
  add_foreign_key "documents", "competitions"
  add_foreign_key "people", "bands"
  add_foreign_key "people", "competitions"
  add_foreign_key "people", "teams"
  add_foreign_key "score_competition_results", "bands"
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
  add_foreign_key "score_lists", "competitions"
  add_foreign_key "score_result_list_factories", "score_list_factories", column: "list_factory_id"
  add_foreign_key "score_result_list_factories", "score_results", column: "result_id"
  add_foreign_key "score_result_lists", "score_lists", column: "list_id"
  add_foreign_key "score_result_lists", "score_results", column: "result_id"
  add_foreign_key "score_results", "assessments"
  add_foreign_key "score_results", "competitions"
  add_foreign_key "score_results", "score_results", column: "double_event_result_id"
  add_foreign_key "teams", "bands"
  add_foreign_key "teams", "competitions"
end
