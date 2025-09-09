class LandingController < ApplicationController
  # No authentication required for landing page
  
  def index
    # Redirect authenticated users to dashboard
    if user_signed_in?
      redirect_to authenticated_root_path
    end
  end
end