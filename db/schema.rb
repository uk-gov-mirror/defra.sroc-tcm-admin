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

ActiveRecord::Schema.define(version: 20171214104155) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "permit_categories", force: :cascade do |t|
    t.bigint "regime_id"
    t.string "code", null: false
    t.string "description"
    t.string "status", null: false
    t.integer "display_order", default: 1000, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code", "regime_id"], name: "index_permit_categories_on_code_and_regime_id", unique: true
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

  create_table "regimes", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug", null: false
    t.string "title"
    t.index ["name"], name: "index_regimes_on_name", unique: true
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
    t.index ["regime_id"], name: "index_transaction_files_on_regime_id"
    t.index ["region"], name: "index_transaction_files_on_region"
    t.index ["state"], name: "index_transaction_files_on_state"
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
    t.index ["regime_id"], name: "index_transaction_headers_on_regime_id"
  end

end
