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

ActiveRecord::Schema.define(version: 20180329085361) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "jobduct_callbacks", force: :cascade do |t|
    t.integer  "channel_id"
    t.string   "title"
    t.string   "call_url"
    t.string   "remote_uri"
    t.string   "status"
    t.string   "success_code"
    t.datetime "sent_at"
    t.datetime "received_at"
    t.datetime "processed_at"
    t.text     "serial_sent_payload"
    t.text     "serial_return_payload"
  end

  add_index "jobduct_callbacks", ["channel_id"], name: "jobduct_callbacks_by_channel", using: :btree

  create_table "jobduct_channels", force: :cascade do |t|
    t.string   "title"
    t.string   "channel_group"
    t.string   "status_line"
    t.string   "status"
    t.string   "exec_status"
    t.string   "handler_class"
    t.string   "user"
    t.string   "invoker"
    t.string   "root_invoker"
    t.string   "signal"
    t.string   "callback_url"
    t.string   "callback_uri"
    t.text     "serial_properties"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "jobduct_channels", ["callback_uri"], name: "jobduct_channels_by_callback_uri", using: :btree
  add_index "jobduct_channels", ["channel_group"], name: "jobduct_channels_by_channel_group", using: :btree
  add_index "jobduct_channels", ["invoker"], name: "jobduct_channels_by_invoker", using: :btree
  add_index "jobduct_channels", ["root_invoker"], name: "jobduct_channels_by_root_invoker", using: :btree

  create_table "jobduct_logs", force: :cascade do |t|
    t.integer "channel_id"
    t.string  "highest_level"
    t.text    "serial_messages"
  end

  add_index "jobduct_logs", ["channel_id"], name: "jobduct_logs_by_channel", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "username"
    t.string   "display_name"
    t.string   "department"
    t.string   "roles"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

end
