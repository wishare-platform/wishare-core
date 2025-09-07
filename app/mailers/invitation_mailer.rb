class InvitationMailer < ApplicationMailer
  def invitation(invitation_record)
    @invitation = invitation_record
    @sender = @invitation.sender
    @recipient_email = @invitation.recipient_email
    @invitation_url = invitation_url(token: @invitation.token)
    
    # Check if recipient already has an account
    @existing_user = User.find_by(email: @recipient_email)
    
    mail(
      to: @recipient_email,
      subject: "#{@sender.display_name} wants to share wishlists with you on Wishare!"
    )
  end
end
