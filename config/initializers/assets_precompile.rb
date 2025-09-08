# Skip secret key base validation during asset precompilation
# This allows assets to compile during Docker builds without secrets
if ENV['SECRET_KEY_BASE_DUMMY'].present? || ENV['SECRET_KEY_BASE'].blank?
  # Use a dummy secret key base for asset precompilation
  Rails.application.config.secret_key_base ||= SecureRandom.hex(64)
  Rails.application.credentials.secret_key_base ||= Rails.application.config.secret_key_base
end