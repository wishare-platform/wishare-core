# frozen_string_literal: true

module Api
  module V1
    class ConnectionsController < BaseController
      before_action :set_connection, only: [:show, :update, :destroy]

      def index
        connections = current_user.all_connections.includes(:user, :partner)

        render json: {
          connections: connections.map { |c| connection_json(c) },
          pending_count: connections.pending.count,
          accepted_count: connections.accepted.count
        }
      end

      def show
        render json: connection_json(@connection)
      end

      def create
        # This creates an invitation, not a direct connection
        render json: { error: 'Use invitations endpoint to create connections' }, status: :bad_request
      end

      def update
        # Accept/decline connection (when user is the partner)
        if @connection.user == current_user
          render json: { error: 'Cannot update your own connection' }, status: :forbidden
          return
        end

        case params[:action_type]
        when 'accept'
          if @connection.update(status: :accepted)
            # Create reverse connection
            Connection.create!(
              user: @connection.partner,
              partner: @connection.user,
              status: :accepted
            )
            render json: connection_json(@connection)
          else
            render json: { errors: @connection.errors.full_messages }, status: :unprocessable_entity
          end
        when 'decline'
          @connection.update(status: :declined)
          render json: { message: 'Connection declined' }
        else
          render json: { error: 'Invalid action type' }, status: :bad_request
        end
      end

      def destroy
        # Disconnect - remove both connections
        if @connection.accepted?
          # Find and destroy reverse connection
          reverse_connection = Connection.find_by(
            user: @connection.partner,
            partner: @connection.user,
            status: :accepted
          )
          reverse_connection&.destroy
        end

        @connection.destroy
        render json: { message: 'Connection removed' }
      end

      def friends
        # Get all accepted connections for friends & family wishlists
        connections = current_user.all_connections.accepted.includes(:user, :partner)
        friends = connections.map do |c|
          friend = c.user == current_user ? c.partner : c.user
          {
            id: friend.id,
            name: friend.name,
            email: friend.email,
            avatar_url: friend.avatar_url,
            connection_id: c.id,
            connected_at: c.updated_at,
            wishlists_count: friend.wishlists.friends_and_family.count
          }
        end

        render json: { friends: friends, count: friends.count }
      end

      private

      def set_connection
        @connection = current_user.all_connections.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Connection not found' }, status: :not_found
      end

      def connection_json(connection)
        other_user = connection.user == current_user ? connection.partner : connection.user
        is_initiator = connection.user == current_user

        {
          id: connection.id,
          status: connection.status,
          user: {
            id: other_user.id,
            name: other_user.name,
            email: other_user.email,
            avatar_url: other_user.avatar_url
          },
          is_initiator: is_initiator,
          can_accept: !is_initiator && connection.pending?,
          can_decline: !is_initiator && connection.pending?,
          created_at: connection.created_at,
          updated_at: connection.updated_at
        }
      end
    end
  end
end