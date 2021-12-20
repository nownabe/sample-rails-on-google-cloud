class PostNotificationJob < ApplicationJob
  queue_as :default

  def perform(post)
    Rails.logger.info("Performing PostNotificationJob with Post(ID: #{post.id})")

    sleep 10

    post_notification = PostNotification.new(post: post)
    post_notification.message = "New post (#{post.id}) was created by #{post.name}."

    unless post_notification.save
      Rails.logger.error(post_notification.errors)
    end
  end
end
