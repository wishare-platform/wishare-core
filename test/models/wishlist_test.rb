require "test_helper"

class WishlistTest < ActiveSupport::TestCase
  test "valid wishlist" do
    wishlist = build(:wishlist)
    assert wishlist.valid?
  end

  test "requires name" do
    wishlist = build(:wishlist, name: nil)
    assert_not wishlist.valid?
    assert_includes wishlist.errors[:name], "can't be blank"
  end

  test "requires visibility" do
    wishlist = build(:wishlist, visibility: nil)
    assert_not wishlist.valid?
  end

  test "validates event_type inclusion" do
    wishlist = build(:wishlist, event_type: "invalid_event")
    assert_not wishlist.valid?
    assert_includes wishlist.errors[:event_type], "is not included in the list"
  end

  # Scopes
  test "public_lists returns only publicly visible wishlists" do
    user = create(:user)
    public_wl = create(:wishlist, user: user, visibility: :publicly_visible)
    create(:wishlist, :private, user: user)

    assert_includes Wishlist.public_lists, public_wl
    assert_equal 1, Wishlist.public_lists.count
  end

  test "upcoming_events returns future event wishlists" do
    user = create(:user)
    upcoming = create(:wishlist, :birthday, user: user)
    create(:wishlist, :past_event, user: user)
    create(:wishlist, user: user) # general, no event date

    assert_includes Wishlist.upcoming_events, upcoming
    assert_equal 1, Wishlist.upcoming_events.count
  end

  # Business logic
  test "days_until_event returns correct count" do
    wishlist = build(:wishlist, event_type: "birthday", event_date: 10.days.from_now.to_date)
    assert_equal 10, wishlist.days_until_event
  end

  test "days_until_event returns nil for general wishlists" do
    wishlist = build(:wishlist, event_type: "none")
    assert_nil wishlist.days_until_event
  end

  test "event_passed? returns true for past events" do
    wishlist = build(:wishlist, event_type: "birthday", event_date: 5.days.ago.to_date)
    assert wishlist.event_passed?
  end

  test "event_passed? returns false for future events" do
    wishlist = build(:wishlist, event_type: "birthday", event_date: 5.days.from_now.to_date)
    assert_not wishlist.event_passed?
  end

  test "general_wishlist? returns true for none event type" do
    assert build(:wishlist, event_type: "none").general_wishlist?
    assert build(:wishlist, event_type: nil).general_wishlist?
    assert build(:wishlist, event_type: "birthday", event_date: nil).general_wishlist?
  end
end
