require "test_helper"

class PostNotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post_notification = post_notifications(:one)
  end

  test "should get index" do
    get post_notifications_url
    assert_response :success
  end

  test "should get new" do
    get new_post_notification_url
    assert_response :success
  end

  test "should create post_notification" do
    assert_difference('PostNotification.count') do
      post post_notifications_url, params: { post_notification: { message: @post_notification.message, post_id: @post_notification.post_id } }
    end

    assert_redirected_to post_notification_url(PostNotification.last)
  end

  test "should show post_notification" do
    get post_notification_url(@post_notification)
    assert_response :success
  end

  test "should get edit" do
    get edit_post_notification_url(@post_notification)
    assert_response :success
  end

  test "should update post_notification" do
    patch post_notification_url(@post_notification), params: { post_notification: { message: @post_notification.message, post_id: @post_notification.post_id } }
    assert_redirected_to post_notification_url(@post_notification)
  end

  test "should destroy post_notification" do
    assert_difference('PostNotification.count', -1) do
      delete post_notification_url(@post_notification)
    end

    assert_redirected_to post_notifications_url
  end
end
