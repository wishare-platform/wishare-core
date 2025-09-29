class ConnectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_connection, only: [:show, :update, :destroy]

  def index
    @connections = current_user.accepted_connections.includes(user: :avatar_attachment, partner: :avatar_attachment)
    @pending_invitations = current_user.sent_invitations.pending_invitations.includes(sender: :avatar_attachment)
  end

  def show
  end

  def update
    if @connection.update(connection_params)
      redirect_to connections_path, notice: 'Connection updated successfully.'
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    @connection.destroy
    redirect_to connections_path, notice: 'Connection removed successfully.'
  end

  private

  def set_connection
    @connection = current_user.all_connections.find_by(id: params[:id])
    render_404 and return unless @connection
  end

  def connection_params
    params.require(:connection).permit(:status)
  end
end
