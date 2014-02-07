# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20140207192024) do

  create_table "accounts", force: true do |t|
    t.integer  "account_number"
    t.integer  "employee_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "accounts", ["employee_id"], name: "index_accounts_on_employee_id"

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority"

  create_table "employees", force: true do |t|
    t.string   "name"
    t.string   "email"
    t.integer  "income"
    t.boolean  "bonus"
    t.integer  "position_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "title"
    t.string   "phone"
    t.integer  "position_category_id"
  end

  add_index "employees", ["position_id"], name: "index_employees_on_position_id"

  create_table "employees_skills", id: false, force: true do |t|
    t.integer  "employee_id"
    t.integer  "skill_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "imports", force: true do |t|
    t.integer  "user_id"
    t.string   "klass",                                       null: false
    t.string   "file_uid",                                    null: false
    t.string   "file_name"
    t.string   "file_mime_type"
    t.integer  "file_size"
    t.string   "report_uid"
    t.string   "report_name"
    t.string   "report_mime_type"
    t.integer  "num_errors",       default: 0,                null: false
    t.integer  "num_imported",     default: 0,                null: false
    t.string   "state",            default: "not_configured", null: false
    t.string   "action_name",      default: "import",         null: false
    t.text     "configuration"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "imports", ["klass", "user_id"], name: "index_imports_on_klass_and_user_id"
  add_index "imports", ["user_id"], name: "index_imports_on_user_id"

  create_table "imports_importables", force: true do |t|
    t.integer "import_id"
    t.integer "importable_id"
    t.string  "importable_type"
  end

  add_index "imports_importables", ["import_id"], name: "index_imports_importables_on_import_id"
  add_index "imports_importables", ["importable_id"], name: "index_imports_importables_on_importable_id"

  create_table "position_categories", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "positions", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position_category_id"
  end

  create_table "projects", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "employee_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deadline"
    t.string   "color"
  end

  add_index "projects", ["employee_id"], name: "index_projects_on_employee_id"

  create_table "skills", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "taggings", force: true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       limit: 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], name: "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", force: true do |t|
    t.string "name"
  end

  create_table "tasks", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status"
    t.integer  "completed_percents"
  end

  add_index "tasks", ["project_id"], name: "index_tasks_on_project_id"

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

end
