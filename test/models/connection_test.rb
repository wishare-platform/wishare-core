require "test_helper"

class ConnectionTest < ActiveSupport::TestCase
  test "valid connection" do
    user1 = create(:user)
    user2 = create(:user)
    connection = build(:connection, user: user1, partner: user2)
    assert connection.valid?
  end

  test "cannot connect to self" do
    user = create(:user)
    connection = build(:connection, user: user, partner: user)
    assert_not connection.valid?
    assert_includes connection.errors[:partner_id], "can't connect to yourself"
  end

  test "enforces unique user-partner pair" do
    user1 = create(:user)
    user2 = create(:user)
    create(:connection, user: user1, partner: user2)

    duplicate = build(:connection, user: user1, partner: user2)
    assert_not duplicate.valid?
  end

  test "between_users finds connection in either direction" do
    user1 = create(:user)
    user2 = create(:user)
    connection = create(:connection, user: user1, partner: user2)

    assert_equal connection, Connection.between_users(user1, user2)
    assert_equal connection, Connection.between_users(user2, user1)
  end

  test "between_users returns nil when no connection exists" do
    user1 = create(:user)
    user2 = create(:user)

    assert_nil Connection.between_users(user1, user2)
  end

  test "accepted_connections scope" do
    create(:connection, :accepted)
    create(:connection, status: :pending)
    create(:connection, status: :declined)

    assert_equal 1, Connection.accepted_connections.count
  end

  test "other_user returns the other user" do
    user1 = create(:user)
    user2 = create(:user)
    connection = create(:connection, user: user1, partner: user2)

    assert_equal user2, connection.other_user(user1)
    assert_equal user1, connection.other_user(user2)
  end
end
