class InvitationsController < ApplicationController
  before_action :authenticate_user!, except: [:show, :update]
  before_action :set_invitation, only: [:show, :update]

  def new
    @invitation = current_user.sent_invitations.build
  end

  def create
    @invitation = current_user.sent_invitations.build(invitation_params)
    
    if @invitation.save
      # Send email invitation
      InvitationMailer.invitation(@invitation).deliver_now
      redirect_to connections_path, notice: 'Invitation sent successfully! An email has been sent to your partner.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    if @invitation.expired?
      @invitation.mark_as_expired!
      render :expired and return
    end
    
    if @invitation.accepted?
      redirect_to root_path, notice: 'This invitation has already been accepted.'
      return
    end

    # If user is not signed in, redirect to sign up with pre-filled email
    unless user_signed_in?
      redirect_to new_user_registration_path(email: @invitation.recipient_email)
      return
    end

    # Check if current user's email matches invitation
    if current_user.email != @invitation.recipient_email
      redirect_to root_path, alert: 'This invitation is not for your email address.'
      return
    end
  end

  def update
    if params[:accept] == 'true'
      if user_signed_in? && current_user.email == @invitation.recipient_email
        begin
          @invitation.accept!(current_user)
          redirect_to root_path, notice: 'You are now connected! 💕'
        rescue ActiveRecord::RecordInvalid => e
          redirect_to invitation_path(@invitation.token), alert: 'Unable to accept invitation: ' + e.message
        end
      else
        redirect_to new_user_registration_path(email: @invitation.recipient_email)
      end
    else
      redirect_to root_path, notice: 'Invitation declined.'
    end
  end

  private

  def set_invitation
    @invitation = Invitation.find_by!(token: params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: 'Invalid invitation link.'
  end

  def invitation_params
    params.require(:invitation).permit(:recipient_email)
  end
end
