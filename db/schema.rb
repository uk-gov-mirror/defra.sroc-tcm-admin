# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180619073618) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "annual_billing_data_files", force: :cascade do |t|
    t.bigint "regime_id"
    t.string "filename", null: false
    t.string "status", default: "new", null: false
    t.integer "number_of_records", default: 0, null: false
    t.integer "success_count", default: 0, null: false
    t.integer "failed_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["regime_id"], name: "index_annual_billing_data_files_on_regime_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.bigint "user_id"
    t.string "auditable_type"
    t.integer "auditable_id"
    t.string "action", null: false
    t.json "payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "data_upload_errors", force: :cascade do |t|
    t.bigint "annual_billing_data_file_id"
    t.integer "line_number", null: false
    t.string "message", null: false
    t.index ["annual_billing_data_file_id"], name: "index_data_upload_errors_on_annual_billing_data_file_id"
  end

  create_table "exclusion_reasons", force: :cascade do |t|
    t.bigint "regime_id"
    t.string "reason", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["regime_id", "reason"], name: "index_exclusion_reasons_on_regime_id_and_reason", unique: true
    t.index ["regime_id"], name: "index_exclusion_reasons_on_regime_id"
  end

  create_table "permit_categories", force: :cascade do |t|
    t.bigint "regime_id"
    t.string "code", null: false
    t.string "description"
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "valid_from", default: "1819", null: false
    t.string "valid_to"
    t.index ["code", "regime_id", "valid_from"], name: "index_permit_categories_on_code_and_regime_id_and_valid_from", unique: true
    t.index ["regime_id"], name: "index_permit_categories_on_regime_id"
  end

  create_table "permits", force: :cascade do |t|
    t.bigint "regime_id"
    t.string "permit_reference", null: false
    t.string "original_reference"
    t.string "obs_original_reference"
    t.string "version"
    t.string "discharge_reference"
    t.string "operator"
    t.string "permit_category", null: false
    t.datetime "effective_date", null: false
    t.string "status", null: false
    t.boolean "pre_construction", null: false
    t.datetime "pre_construction_end"
    t.boolean "temporary_cessation", null: false
    t.datetime "temporary_cessation_start"
    t.datetime "temporary_cessation_end"
    t.string "compliance_score"
    t.string "compliance_band"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["permit_reference"], name: "index_permits_on_permit_reference"
    t.index ["regime_id"], name: "index_permits_on_regime_id"
  end

  create_table "regime_users", force: :cascade do |t|
    t.bigint "regime_id"
    t.bigint "user_id"
    t.boolean "enabled", default: false, null: false
    t.string "working_region"
    t.index ["regime_id", "user_id"], name: "index_regime_users_on_regime_id_and_user_id", unique: true
    t.index ["regime_id"], name: "index_regime_users_on_regime_id"
    t.index ["user_id"], name: "index_regime_users_on_user_id"
  end

  create_table "regimes", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug", null: false
    t.string "title"
    t.datetime "retrospective_cut_off_date", default: "2018-04-01 00:00:00", null: false
    t.index ["name"], name: "index_regimes_on_name", unique: true
  end

  create_table "sequence_counters", force: :cascade do |t|
    t.bigint "regime_id"
    t.string "region", null: false
    t.integer "file_number", default: 50001, null: false
    t.integer "invoice_number", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["regime_id", "region"], name: "index_sequence_counters_on_regime_id_and_region", unique: true
    t.index ["regime_id"], name: "index_sequence_counters_on_regime_id"
  end

  create_table "system_configs", force: :cascade do |t|
    t.boolean "importing", default: false, null: false
    t.datetime "import_started_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "process_retrospectives", default: true, null: false
  end

  create_table "transaction_details", force: :cascade do |t|
    t.bigint "transaction_header_id"
    t.integer "sequence_number"
    t.string "customer_reference"
    t.datetime "transaction_date"
    t.string "transaction_type"
    t.string "transaction_reference"
    t.string "related_reference"
    t.string "currency_code"
    t.string "header_narrative"
    t.string "header_attr_1"
    t.string "header_attr_2"
    t.string "header_attr_3"
    t.string "header_attr_4"
    t.string "header_attr_5"
    t.string "header_attr_6"
    t.string "header_attr_7"
    t.string "header_attr_8"
    t.string "header_attr_9"
    t.string "header_attr_10"
    t.integer "line_amount"
    t.string "line_vat_code"
    t.string "line_area_code"
    t.string "line_description"
    t.string "line_income_stream_code"
    t.string "line_context_code"
    t.string "line_attr_1"
    t.string "line_attr_2"
    t.string "line_attr_3"
    t.string "line_attr_4"
    t.string "line_attr_5"
    t.string "line_attr_6"
    t.string "line_attr_7"
    t.string "line_attr_8"
    t.string "line_attr_9"
    t.string "line_attr_10"
    t.string "line_attr_11"
    t.string "line_attr_12"
    t.string "line_attr_13"
    t.string "line_attr_14"
    t.string "line_attr_15"
    t.integer "line_quantity"
    t.string "unit_of_measure"
    t.integer "unit_of_measure_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "unbilled", null: false
    t.string "filename"
    t.string "reference_1"
    t.string "reference_2"
    t.string "reference_3"
    t.string "generated_filename"
    t.datetime "generated_file_at"
    t.boolean "temporary_cessation", default: false, null: false
    t.datetime "temporary_cessation_start"
    t.datetime "temporary_cessation_end"
    t.string "category"
    t.json "charge_calculation"
    t.datetime "period_start"
    t.datetime "period_end"
    t.bigint "transaction_file_id"
    t.bigint "tcm_charge"
    t.string "tcm_transaction_type"
    t.string "tcm_transaction_reference"
    t.string "variation"
    t.string "original_filename"
    t.datetime "original_file_date"
    t.string "tcm_financial_year"
    t.boolean "excluded", default: false, null: false
    t.string "excluded_reason"
    t.string "category_description"
    t.index ["customer_reference"], name: "index_transaction_details_on_customer_reference"
    t.index ["sequence_number"], name: "index_transaction_details_on_sequence_number"
    t.index ["transaction_file_id"], name: "index_transaction_details_on_transaction_file_id"
    t.index ["transaction_header_id"], name: "index_transaction_details_on_transaction_header_id"
  end

  create_table "transaction_files", force: :cascade do |t|
    t.bigint "regime_id"
    t.string "region", null: false
    t.string "file_id"
    t.string "state", default: "initialised", null: false
    t.datetime "generated_at"
    t.bigint "invoice_total"
    t.bigint "credit_total"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "retrospective", default: false, null: false
    t.bigint "user_id"
    t.index ["regime_id"], name: "index_transaction_files_on_regime_id"
    t.index ["region"], name: "index_transaction_files_on_region"
    t.index ["state"], name: "index_transaction_files_on_state"
    t.index ["user_id"], name: "index_transaction_files_on_user_id"
  end

  create_table "transaction_headers", force: :cascade do |t|
    t.bigint "regime_id"
    t.string "feeder_source_code"
    t.string "region"
    t.integer "file_sequence_number"
    t.string "bill_run_id"
    t.datetime "generated_at"
    t.integer "transaction_count"
    t.integer "invoice_total"
    t.integer "credit_total"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "file_type_flag"
    t.string "filename"
    t.index ["regime_id"], name: "index_transaction_headers_on_regime_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.boolean "enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.integer "role", default: 0, null: false
    t.integer "active_regime"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_users_on_invitations_count"
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by_type_and_invited_by_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "transaction_files", "users"
end
