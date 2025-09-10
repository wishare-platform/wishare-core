class InvitationMailer < ApplicationMailer
  def invitation(invitation_record)
    @invitation = invitation_record
    @sender = @invitation.sender
    @recipient_email = @invitation.recipient_email
    @invitation_url = accept_invitation_url(token: @invitation.token)

    # Check if recipient already has an account
    @existing_user = User.find_by(email: @recipient_email)

    I18n.with_locale(@sender.preferred_locale || I18n.default_locale) do
      mail(
        to: @recipient_email,
        subject: t("emails.invitation.subject", sender_name: @sender.display_name)
      )
    end
  end
end
