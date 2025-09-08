class LegalController < ApplicationController
  # Legal pages don't require authentication
  # Note: ApplicationController doesn't have authenticate_user! callback
  
  def terms_of_service
    # Terms of Service page
  end
  
  def privacy_policy
    # Privacy Policy page
  end
end