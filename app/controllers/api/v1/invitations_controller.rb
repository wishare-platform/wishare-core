# frozen_string_literal: true

module Api
  module V1
    class InvitationsController < BaseController
      before_action :set_invitation, only: [:show, :update, :destroy]

      def index
        sent_invitations = current_user.sent_invitations.includes(:recipient_user)
        received_invitations = current_user.received_invitations.includes(:sender)

        render json: {
          sent: sent_invitations.map { |i| invitation_json(i, :sent) },
          received: received_invitations.map { |i| invitation_json(i, :received) },
          pending_sent_count: sent_invitations.pending.count,
          pending_received_count: received_invitations.pending.count
        }
      end

      def show
        # Show invitation by token (for accepting invitations)
        invitation = Invitation.find_by(token: params[:token])

        if invitation.nil?
          render json: { error: 'Invitation not found' }, status: :not_found
          return
        end

        if invitation.expired?
          render json: { error: 'Invitation has expired' }, status: :gone
          return
        end

        render json: {
          invitation: invitation_json(invitation, :received),
          can_accept: invitation.pending?
        }
      end

      def create
        invitation = current_user.sent_invitations.build(invitation_params)

        if invitation.save
          # Send email notification
          InvitationMailer.invitation_email(invitation).deliver_later

          # Create notification for sender
          Notification.create!(
            user: current_user,
            notification_type: :invitation_sent,
            title: I18n.t('notifications.invitation_sent.title'),
            message: I18n.t('notifications.invitation_sent.message', email: invitation.recipient_email),
            data: { invitation_id: invitation.id, recipient_email: invitation.recipient_email }
          )

          render json: invitation_json(invitation, :sent), status: :created
        else
          render json: { errors: invitation.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        # Accept or decline invitation
        case params[:action_type]
        when 'accept'
          if @invitation.update(status: :accepted)
            # Create connection between users
            connection = Connection.create!(
              user: @invitation.sender,
              partner: current_user,
              status: :accepted
            )

            # Create reverse connection
            Connection.create!(
              user: current_user,
              partner: @invitation.sender,
              status: :accepted
            )

            # Create notifications
            create_acceptance_notifications(@invitation)

            render json: {
              message: 'Invitation accepted',
              invitation: invitation_json(@invitation, :received),
              connection_id: connection.id
            }
          else
            render json: { errors: @invitation.errors.full_messages }, status: :unprocessable_entity
          end

        when 'decline'
          if @invitation.update(status: :declined)
            # Notify sender of decline
            Notification.create!(
              user: @invitation.sender,
              notification_type: :invitation_declined,
              title: I18n.t('notifications.invitation_declined.title'),
              message: I18n.t('notifications.invitation_declined.message', name: current_user.name),
              data: { invitation_id: @invitation.id, declined_by_id: current_user.id }
            )

            render json: {
              message: 'Invitation declined',
              invitation: invitation_json(@invitation, :received)
            }
          else
            render json: { errors: @invitation.errors.full_messages }, status: :unprocessable_entity
          end

        else
          render json: { error: 'Invalid action type' }, status: :bad_request
        end
      end

      def destroy
        if @invitation.sender == current_user
          @invitation.destroy
          render json: { message: 'Invitation cancelled' }
        else
          render json: { error: 'Not authorized to cancel this invitation' }, status: :forbidden
        end
      end

      private

      def set_invitation
        @invitation = if params[:token]
                       Invitation.find_by!(token: params[:token])
                     else
                       current_user.sent_invitations.find(params[:id])
                     end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Invitation not found' }, status: :not_found
      end

      def invitation_params
        params.require(:invitation).permit(:recipient_email, :message)
      end

      def invitation_json(invitation, type)
        json = {
          id: invitation.id,
          recipient_email: invitation.recipient_email,
          message: invitation.message,
          status: invitation.status,
          token: invitation.token,
          expires_at: invitation.expires_at,
          expired: invitation.expired?,
          created_at: invitation.created_at,
          updated_at: invitation.updated_at
        }

        case type
        when :sent
          json[:sender] = {
            id: invitation.sender.id,
            name: invitation.sender.name,
            email: invitation.sender.email
          }
        when :received
          json[:recipient] = if invitation.recipient_user
                              {
                                id: invitation.recipient_user.id,
                                name: invitation.recipient_user.name,
                                email: invitation.recipient_user.email
                              }
                            else
                              { email: invitation.recipient_email }
                            end
        end

        json
      end

      def create_acceptance_notifications(invitation)
        # Notify sender
        Notification.create!(
          user: invitation.sender,
          notification_type: :invitation_accepted,
          title: I18n.t('notifications.invitation_accepted.title'),
          message: I18n.t('notifications.invitation_accepted.message', name: current_user.name),
          data: {
            invitation_id: invitation.id,
            accepted_by_id: current_user.id,
            new_friend_id: current_user.id
          }
        )

        # Notify recipient
        Notification.create!(
          user: current_user,
          notification_type: :connection_formed,
          title: I18n.t('notifications.connection_formed.title'),
          message: I18n.t('notifications.connection_formed.message', name: invitation.sender.name),
          data: {
            invitation_id: invitation.id,
            connected_with_id: invitation.sender.id
          }
        )
      end
    end
  end
end