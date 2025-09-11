class AddressLookupService
  include HTTParty
  
  class << self
    def lookup_address(postal_code, country = nil)
      postal_code = normalize_postal_code(postal_code)
      return { error: 'Invalid postal code format' } unless postal_code
      
      # Auto-detect country if not provided
      detected_country = country || detect_country_from_postal_code(postal_code)
      
      case detected_country.upcase
      when 'BR', 'BRAZIL'
        lookup_brazilian_cep(postal_code)
      when 'US', 'USA', 'UNITED STATES'
        lookup_us_zip(postal_code)
      else
        { error: 'Country not supported or could not be detected' }
      end
    rescue Net::TimeoutError, Errno::ECONNREFUSED, Net::HTTPError => e
      Rails.logger.error "Address lookup network error: #{e.message}"
      { error: 'Address lookup service temporarily unavailable' }
    rescue JSON::ParserError => e
      Rails.logger.error "Address lookup JSON parse error: #{e.message}"
      { error: 'Invalid response from address service' }
    rescue StandardError => e
      Rails.logger.error "Address lookup unexpected error: #{e.message}"
      { error: 'Address lookup failed' }
    end
    
    private
    
    def normalize_postal_code(postal_code)
      return nil unless postal_code.present?
      
      # Remove all non-alphanumeric characters
      cleaned = postal_code.to_s.gsub(/[^0-9A-Za-z]/, '')
      
      # Validate format
      if cleaned.match?(/^\d{8}$/) # Brazilian CEP
        cleaned
      elsif cleaned.match?(/^\d{5}$/) # US ZIP (5 digits)
        cleaned
      elsif cleaned.match?(/^[0-9]{5}[0-9]{4}$/) # US ZIP+4
        cleaned[0..4] # Use only first 5 digits for basic lookup
      else
        nil
      end
    end
    
    def detect_country_from_postal_code(postal_code)
      return nil unless postal_code.present?
      
      # Remove all non-numeric characters for pattern matching
      cleaned = postal_code.to_s.gsub(/[^0-9]/, '')
      
      # Brazilian CEP patterns (8 digits)
      if cleaned.match?(/^\d{8}$/)
        'BR'
      # US ZIP patterns (5 or 9 digits)
      elsif cleaned.match?(/^\d{5}(\d{4})?$/)
        'US'
      else
        # Default fallback - could be extended for more countries
        nil
      end
    end
    
    def lookup_brazilian_cep(cep)
      # Use ViaCEP API - free and reliable
      response = HTTParty.get("https://viacep.com.br/ws/#{cep}/json/", 
                             timeout: 10,
                             headers: { 'Accept' => 'application/json' })
      
      if response.success?
        data = response.parsed_response
        
        if data['erro']
          { error: 'CEP not found' }
        else
          {
            success: true,
            street_address: data['logradouro'],
            city: data['localidade'],
            state: data['uf'],
            postal_code: cep,
            country: 'BR',
            neighborhood: data['bairro'], # Additional Brazilian field
            state_name: data['estado']
          }
        end
      else
        { error: "CEP lookup failed with status: #{response.code}" }
      end
    end
    
    def lookup_us_zip(zip_code)
      # Use Zippopotam.us API - free and no registration required
      response = HTTParty.get("http://api.zippopotam.us/us/#{zip_code}",
                             timeout: 10,
                             headers: { 'Accept' => 'application/json' })
      
      if response.success?
        data = response.parsed_response
        
        # Get the first place (most ZIP codes have only one)
        place = data['places']&.first
        return { error: 'ZIP code not found' } unless place
        
        {
          success: true,
          street_address: nil, # ZIP lookup doesn't provide street
          city: place['place name'],
          state: place['state abbreviation'],
          postal_code: zip_code,
          country: 'US',
          state_name: place['state'],
          latitude: place['latitude']&.to_f,
          longitude: place['longitude']&.to_f
        }
      else
        { error: "ZIP code lookup failed with status: #{response.code}" }
      end
    end
  end
end