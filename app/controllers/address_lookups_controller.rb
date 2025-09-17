class AddressLookupsController < ApplicationController
  before_action :authenticate_user!
  
  def lookup
    postal_code = params[:postal_code]
    # Let the service auto-detect country from postal code pattern
    # Only use explicit country if provided via params
    country = params[:country]

    if postal_code.blank?
      render json: { error: I18n.t('address_lookup.errors.postal_code_required') }, status: :bad_request
      return
    end

    result = AddressLookupService.lookup_address(postal_code, country)
    
    if result[:success]
      render json: {
        success: true,
        data: result.except(:success)
      }
    else
      render json: { 
        error: result[:error] || I18n.t('address_lookup.errors.lookup_failed')
      }, status: :unprocessable_entity
    end
  end
  
  private
  
  def detect_country_from_locale
    case I18n.locale.to_s
    when 'pt-BR'
      'BR'
    else
      'US'
    end
  end
end