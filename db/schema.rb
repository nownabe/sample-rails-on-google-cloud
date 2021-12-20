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

ActiveRecord::Schema.define(version: 2021_12_20_071219) do

  create_table "post_notifications", id: { limit: 8 }, force: :cascade do |t|
    t.integer "post_id", limit: 8, null: false
    t.string "message"
    t.time "created_at", null: false
    t.time "updated_at", null: false
  end

  create_table "posts", id: { limit: 8 }, force: :cascade do |t|
    t.string "name"
    t.string "title"
    t.string "content"
    t.time "created_at", null: false
    t.time "updated_at", null: false
  end

  add_foreign_key "post_notifications", "posts"
end
