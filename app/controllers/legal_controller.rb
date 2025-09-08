class LegalController < ApplicationController
  # Legal pages don't require authentication
  skip_before_action :authenticate_user!, if: :devise_controller?
  
  def terms_of_service
    # Terms of Service page
  end
  
  def privacy_policy
    # Privacy Policy page
  end
end