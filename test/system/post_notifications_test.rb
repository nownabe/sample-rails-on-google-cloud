require "application_system_test_case"

class PostNotificationsTest < ApplicationSystemTestCase
  setup do
    @post_notification = post_notifications(:one)
  end

  test "visiting the index" do
    visit post_notifications_url
    assert_selector "h1", text: "Post Notifications"
  end

  test "creating a Post notification" do
    visit post_notifications_url
    click_on "New Post Notification"

    fill_in "Message", with: @post_notification.message
    fill_in "Post", with: @post_notification.post_id
    click_on "Create Post notification"

    assert_text "Post notification was successfully created"
    click_on "Back"
  end

  test "updating a Post notification" do
    visit post_notifications_url
    click_on "Edit", match: :first

    fill_in "Message", with: @post_notification.message
    fill_in "Post", with: @post_notification.post_id
    click_on "Update Post notification"

    assert_text "Post notification was successfully updated"
    click_on "Back"
  end

  test "destroying a Post notification" do
    visit post_notifications_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Post notification was successfully destroyed"
  end
end
