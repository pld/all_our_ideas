# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090630144105) do

  create_table "questions", :force => true do |t|
    t.integer  "user_id",                        :null => false
    t.integer  "pairwise_id",                    :null => false
    t.boolean  "active",      :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
  end

  create_table "questions_visits", :force => true do |t|
    t.integer  "question_id",   :null => false
    t.integer  "visit_id",      :null => false
    t.integer  "voter_id_ext",  :null => false
    t.integer  "prompt_id_ext"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "questions_visits", ["question_id"], :name => "index_questions_visits_on_question_id"
  add_index "questions_visits", ["visit_id"], :name => "index_questions_visits_on_visit_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "users", :force => true do |t|
    t.string   "encoded_password", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email",            :null => false
    t.integer  "voter_id"
  end

  create_table "visits", :force => true do |t|
    t.string   "locale"
    t.string   "ip_address",                        :null => false
    t.string   "ip_city"
    t.string   "ip_latitude"
    t.string   "ip_longitude"
    t.string   "ip_country_code"
    t.string   "ip_country_name"
    t.string   "ip_dma_code"
    t.string   "ip_area_code"
    t.string   "ip_region"
    t.string   "host"
    t.string   "user_agent"
    t.string   "request_uri"
    t.string   "referrer"
    t.boolean  "active",          :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
