class DashboardController < ApplicationController
  before_action :authenticate_user!
  
  def index
    redirect_to wishlists_path
  end
end
