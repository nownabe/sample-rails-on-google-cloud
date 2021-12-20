json.extract! post_notification, :id, :post_id, :message, :created_at, :updated_at
json.url post_notification_url(post_notification, format: :json)
