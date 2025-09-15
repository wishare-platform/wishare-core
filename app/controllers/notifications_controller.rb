class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications = current_user.notifications.recent.includes(:notifiable)
    @unread_count = current_user.unread_notifications_count
    
    respond_to do |format|
      format.html
      format.json { render json: @notifications }
    end
  end

  def mark_as_read
    notification = current_user.notifications.find_by(id: params[:id])

    if notification
      notification.update(read: true)
      redirect_back(fallback_location: notifications_path)
    else
      render_404
    end
  end

  def mark_all_as_read
    current_user.notifications.unread.update_all(read: true)
    redirect_back(fallback_location: notifications_path)
  end
end
