class CookieConsentsController < ApplicationController
  before_action :set_consent, only: [:show, :update]
  
  def show
    # Show current consent preferences
    @consent = @consent || CookieConsent.find_or_create_for_request(request, current_user)
  end

  def create
    @consent = CookieConsent.find_or_create_for_request(request, current_user)
    
    if @consent.update_consent!(
      analytics: params[:analytics_enabled] == 'true',
      marketing: params[:marketing_enabled] == 'true', 
      functional: params[:functional_enabled] != 'false',
      request: request
    )
      
      # Track consent given
      if @consent.analytics_enabled?
        AnalyticsJob.perform_later(
          'consent_given',
          current_user&.id,
          CookieConsent.extract_session_id(request),
          {
            remote_ip: request.remote_ip,
            user_agent: request.user_agent,
            path: request.path,
            referer: request.referer
          },
          consent_type: 'analytics',
          consent_version: CookieConsent::CURRENT_VERSION
        )
      end
      
      respond_to do |format|
        format.json { 
          render json: { 
            success: true, 
            consent: @consent.consent_summary,
            message: 'Cookie preferences saved successfully'
          }
        }
        format.html { 
          redirect_back(fallback_location: root_path, 
                       notice: 'Cookie preferences saved successfully') 
        }
      end
    else
      respond_to do |format|
        format.json { 
          render json: { 
            success: false, 
            errors: @consent.errors.full_messages 
          }, status: :unprocessable_entity 
        }
        format.html { 
          redirect_back(fallback_location: root_path, 
                       alert: 'Unable to save cookie preferences') 
        }
      end
    end
  end

  def update
    if @consent.update_consent!(
      analytics: params[:analytics_enabled] == 'true',
      marketing: params[:marketing_enabled] == 'true',
      functional: params[:functional_enabled] != 'false',
      request: request
    )
      
      respond_to do |format|
        format.json { 
          render json: { 
            success: true, 
            consent: @consent.consent_summary,
            message: 'Cookie preferences updated successfully'
          }
        }
        format.html { 
          redirect_to cookie_consent_path, 
                     notice: 'Cookie preferences updated successfully' 
        }
      end
    else
      respond_to do |format|
        format.json { 
          render json: { 
            success: false, 
            errors: @consent.errors.full_messages 
          }, status: :unprocessable_entity 
        }
        format.html { 
          render :show, 
                 alert: 'Unable to update cookie preferences' 
        }
      end
    end
  end
  
  def privacy_policy
    # Show privacy policy page
  end
  
  private
  
  def set_consent
    @consent = CookieConsent.find_consent_for_request(request, current_user)
  end
end
