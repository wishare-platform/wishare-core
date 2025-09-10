class Admin::BaseController < ApplicationController
  before_action :authenticate_admin!
  layout 'admin'
  
  private
  
  def authenticate_admin!
    redirect_to root_path unless current_user&.admin? || current_user&.super_admin?
  end
  
  def current_admin
    current_user if current_user&.admin? || current_user&.super_admin?
  end
  helper_method :current_admin
  
  def require_super_admin!
    redirect_to admin_root_path unless current_user&.super_admin?
  end
end