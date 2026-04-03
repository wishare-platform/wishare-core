require "test_helper"

class UserTest < ActiveSupport::TestCase
  # Validations
  test "valid user with all required fields" do
    user = build(:user)
    assert user.valid?
  end

  test "requires name" do
    user = build(:user, name: nil)
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "requires email" do
    user = build(:user, email: nil)
    assert_not user.valid?
  end

  test "requires unique email" do
    create(:user, email: "test@example.com")
    user = build(:user, email: "test@example.com")
    assert_not user.valid?
  end

  test "validates preferred_locale inclusion" do
    user = build(:user, preferred_locale: "fr")
    assert_not user.valid?
    assert_includes user.errors[:preferred_locale], "is not included in the list"
  end

  test "validates theme_preference inclusion" do
    user = build(:user, theme_preference: "neon")
    assert_not user.valid?
    assert_includes user.errors[:theme_preference], "is not included in the list"
  end

  # Password complexity
  test "password must be at least 12 characters" do
    user = build(:user, password: "Short1!")
    assert_not user.valid?
  end

  test "password must include uppercase, lowercase, number, and special char" do
    user = build(:user, password: "alllowercase1!")
    assert_not user.valid?

    user = build(:user, password: "ALLUPPERCASE1!")
    assert_not user.valid?

    user = build(:user, password: "NoNumbers!Abc")
    assert_not user.valid?

    user = build(:user, password: "NoSpecial1Abcd")
    assert_not user.valid?
  end

  test "valid strong password passes complexity" do
    user = build(:user, password: "MyStr0ng!Pass")
    assert user.valid?
  end

  # Associations
  test "connected_to? returns true for accepted connections" do
    user1 = create(:user)
    user2 = create(:user)
    create(:connection, user: user1, partner: user2, status: :accepted)

    assert user1.connected_to?(user2)
  end

  test "connected_to? returns false for pending connections" do
    user1 = create(:user)
    user2 = create(:user)
    create(:connection, user: user1, partner: user2, status: :pending)

    assert_not user1.connected_to?(user2)
  end

  test "connected_to? returns false for nil user" do
    user = create(:user)
    assert_not user.connected_to?(nil)
  end

  test "unread_notifications_count returns correct count" do
    user = create(:user)
    invitation = create(:invitation, sender: create(:user))
    create(:notification, user: user, notifiable: invitation, read: false)
    create(:notification, user: user, notifiable: invitation, read: true)

    assert_equal 1, user.unread_notifications_count
  end

  # OAuth
  test "from_omniauth creates new user from Google auth" do
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "123456",
      info: {
        email: "oauth@example.com",
        name: "OAuth User",
        image: "https://example.com/avatar.jpg"
      }
    )

    assert_difference "User.count", 1 do
      user = User.from_omniauth(auth)
      assert_equal "oauth@example.com", user.email
      assert_equal "OAuth User", user.name
      assert_equal "google_oauth2", user.provider
    end
  end

  test "from_omniauth links existing email user to OAuth" do
    existing = create(:user, email: "existing@example.com")

    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "789",
      info: {
        email: "existing@example.com",
        name: "Existing User"
      }
    )

    assert_no_difference "User.count" do
      user = User.from_omniauth(auth)
      assert_equal existing.id, user.id
      assert_equal "google_oauth2", user.provider
      assert_equal "789", user.uid
    end
  end

  # Social validations
  test "bio cannot exceed 500 characters" do
    user = build(:user, bio: "a" * 501)
    assert_not user.valid?
    assert_includes user.errors[:bio], "is too long (maximum is 500 characters)"
  end

  test "instagram_username validates format" do
    user = build(:user, instagram_username: "valid.user_name")
    assert user.valid?

    user = build(:user, instagram_username: "invalid user!")
    assert_not user.valid?
  end
end
