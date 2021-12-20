class CreatePostNotifications < ActiveRecord::Migration[6.1]
  def change
    create_table :post_notifications do |t|
      t.references :post, null: false, foreign_key: true
      t.text :message

      t.timestamps
    end
  end
end
