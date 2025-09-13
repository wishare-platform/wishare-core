class JwtDenylist < ApplicationRecord
  # Remove JWT functionality for now

  self.table_name = 'jwt_denylists'

  belongs_to :user, optional: true
end
