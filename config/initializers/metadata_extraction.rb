# URL Metadata Extraction Configuration
# This initializer configures the enhanced metadata extraction system

Rails.application.config.to_prepare do
  # Configure extraction settings
  Rails.application.config.metadata_extraction = {
    # Enable/disable extraction methods
    methods: {
      cache: true,
      api: ENV['ENABLE_METADATA_API'] != 'false',
      enhanced_html: true,
      standard_html: true
    },

    # API service configuration
    api_services: {
      microlink: {
        enabled: true,
        timeout: 10
      },
      linkpreview: {
        enabled: ENV['LINKPREVIEW_API_KEY'].present?,
        api_key: ENV['LINKPREVIEW_API_KEY']
      },
      unfurl: {
        enabled: ENV['UNFURL_API_KEY'].present?,
        api_key: ENV['UNFURL_API_KEY']
      }
    },

    # Caching configuration
    cache: {
      enabled: true,
      ttl: 24.hours,
      namespace: 'url_metadata'
    },

    # Extraction timeout settings
    timeouts: {
      http_read: 10,
      http_open: 5,
      total: 30
    },

    # Platform-specific optimizations
    platform_optimizations: {
      shopify: true,
      woocommerce: true,
      magento: true,
      bigcommerce: true,
      amazon: true
    },

    # Additional domains for currency detection
    custom_currency_domains: {
      # Add custom domains here
      # 'example.com.br' => 'BRL'
    }
  }

  # Log configuration on startup (development only)
  if Rails.env.development?
    Rails.logger.info "=" * 80
    Rails.logger.info "URL Metadata Extraction Configuration"
    Rails.logger.info "=" * 80
    Rails.logger.info "Methods enabled:"
    Rails.application.config.metadata_extraction[:methods].each do |method, enabled|
      Rails.logger.info "  #{method}: #{enabled}"
    end
    Rails.logger.info "API services:"
    Rails.application.config.metadata_extraction[:api_services].each do |service, config|
      Rails.logger.info "  #{service}: #{config[:enabled] ? 'enabled' : 'disabled'}"
    end
    Rails.logger.info "=" * 80
  end
end