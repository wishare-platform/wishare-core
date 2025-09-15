class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :load_dashboard_data

  def index
    @user = current_user
  end

  private

  def load_dashboard_data
    dashboard_data = DashboardDataService.new(current_user).call

    @user_stats = dashboard_data[:user_stats]
    @pending_connections = dashboard_data[:pending_connections]
    @recent_notifications = dashboard_data[:recent_notifications]
    @friends = dashboard_data[:friends]
    @upcoming_events = dashboard_data[:upcoming_events]
    @recent_items = dashboard_data[:recent_items]
    @budget_items = dashboard_data[:budget_items]
    @trending_items = dashboard_data[:trending_items]
    @featured_wishlists = dashboard_data[:featured_wishlists]
    @settings = dashboard_data[:settings]
  end
end
