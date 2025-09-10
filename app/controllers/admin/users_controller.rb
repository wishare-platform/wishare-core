class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :update, :destroy]
  
  def index
    @users = User.includes(:user_analytic, :wishlists, :connections)
                 
    @users = @users.where("name ILIKE ? OR email ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    @users = @users.where(role: params[:role]) if params[:role].present?
    @users = @users.order(created_at: :desc)
    @users = @users.limit(25).offset((params[:page]&.to_i || 1 - 1) * 25)
    
    @total_users = User.count
    @active_users = User.joins(:user_analytic)
                       .where('user_analytics.last_activity_at > ?', 30.days.ago)
                       .count
  end

  def show
    @user_analytics = @user.user_analytic || @user.build_user_analytic
    @recent_events = AnalyticsEvent.by_user(@user)
                                  .recent
                                  .limit(20)
    @wishlists = @user.wishlists.includes(:wishlist_items)
    @connections = @user.accepted_connections.includes(:user, :partner)
  end

  def update
    # Only allow role changes by super admins
    if user_params[:role].present? && !current_user.super_admin?
      redirect_to admin_user_path(@user), alert: 'Unauthorized: Only super admins can change user roles.'
      return
    end
    
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: 'User updated successfully.'
    else
      redirect_to admin_user_path(@user), alert: 'Failed to update user.'
    end
  end

  def destroy
    if @user.destroy
      redirect_to admin_users_path, notice: 'User deleted successfully.'
    else
      redirect_to admin_users_path, alert: 'Failed to delete user.'
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:role)
  end
end