require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  test "valid invitation" do
    invitation = build(:invitation)
    assert invitation.valid?
  end

  test "requires recipient_email" do
    invitation = build(:invitation, recipient_email: nil)
    assert_not invitation.valid?
  end

  test "validates recipient_email format" do
    invitation = build(:invitation, recipient_email: "not-an-email")
    assert_not invitation.valid?
  end

  test "generates token on create" do
    invitation = create(:invitation)
    assert_not_nil invitation.token
    assert invitation.token.length > 20
  end

  test "cannot invite self" do
    user = create(:user)
    invitation = build(:invitation, sender: user, recipient_email: user.email)
    assert_not invitation.valid?
    assert_includes invitation.errors[:recipient_email], "can't invite yourself"
  end

  test "cannot send duplicate pending invitation" do
    sender = create(:user)
    create(:invitation, sender: sender, recipient_email: "friend@example.com")

    duplicate = build(:invitation, sender: sender, recipient_email: "friend@example.com")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:recipient_email], "already has a pending invitation"
  end

  test "cannot invite existing partner" do
    sender = create(:user)
    recipient = create(:user)
    create(:connection, user: sender, partner: recipient, status: :accepted)

    invitation = build(:invitation, sender: sender, recipient_email: recipient.email)
    assert_not invitation.valid?
    assert_includes invitation.errors[:recipient_email], "is already your partner"
  end

  test "expired? returns true for old invitations" do
    invitation = create(:invitation)
    invitation.update_column(:created_at, 8.days.ago)

    assert invitation.expired?
  end

  test "expired? returns false for recent invitations" do
    invitation = create(:invitation)
    assert_not invitation.expired?
  end

  test "accept! creates connection and updates status" do
    sender = create(:user)
    recipient = create(:user)
    invitation = create(:invitation, sender: sender, recipient_email: recipient.email)

    invitation.accept!(recipient)

    assert invitation.reload.accepted?
    assert_not_nil invitation.accepted_at
    assert Connection.between_users(sender, recipient)&.accepted?
  end
end
