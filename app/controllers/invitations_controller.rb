class InvitationsController < ApplicationController
  before_action :authenticate_user!, except: [:show, :update]
  before_action :set_invitation, only: [:show, :update]
  before_action :set_user_invitation, only: [:destroy]

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
    # Check if invitation is expired by time
    if @invitation.expired?
      @invitation.mark_as_expired! unless @invitation.status == 'expired'
      redirect_to root_path, alert: 'This invitation has expired.'
      return
    end
    
    # Check if invitation has already been accepted
    if @invitation.accepted?
      redirect_to root_path, notice: 'This invitation has already been accepted.'
      return
    end

    # Check if invitation has already been declined or marked as expired
    if @invitation.status == 'expired'
      redirect_to root_path, alert: 'This invitation is no longer valid.'
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
    # Check if invitation is still valid before processing
    if @invitation.expired? || @invitation.status == 'expired' || @invitation.accepted?
      redirect_to root_path, alert: 'This invitation is no longer valid.'
      return
    end

    if params[:accept] == 'true'
      if user_signed_in? && current_user.email == @invitation.recipient_email
        begin
          @invitation.accept!(current_user)
          redirect_to root_path, notice: 'You are now connected! 💕'
        rescue ActiveRecord::RecordInvalid => e
          redirect_to accept_invitation_path(token: @invitation.token), alert: 'Unable to accept invitation: ' + e.message
        end
      else
        redirect_to new_user_registration_path(email: @invitation.recipient_email)
      end
    else
      # Mark invitation as expired when declined
      @invitation.mark_as_expired!
      redirect_to root_path, notice: 'Invitation declined.'
    end
  end

  def destroy
    @invitation.destroy
    redirect_to connections_path, notice: 'Invitation cancelled successfully.'
  end

  private

  def set_invitation
    @invitation = Invitation.find_by!(token: params[:token])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: 'Invalid invitation link.'
  end

  def set_user_invitation
    @invitation = current_user.sent_invitations.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to connections_path, alert: 'Invitation not found.'
  end

  def invitation_params
    params.require(:invitation).permit(:recipient_email)
  end
end
