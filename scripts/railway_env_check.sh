#!/bin/bash

# Railway Environment Variable Check Script
# Usage: railway run ./scripts/railway_env_check.sh

echo "========================================"
echo "WISHARE RAILWAY ENV VARIABLES CHECK"
echo "========================================"

echo ""
echo "1. Critical Environment Variables:"
echo "-----------------------------------"

check_env_var() {
    local var_name=$1
    if [ -n "${!var_name}" ]; then
        echo "✅ $var_name: SET"
    else
        echo "❌ $var_name: MISSING"
    fi
}

# Critical variables for basic functionality
check_env_var "DATABASE_URL"
check_env_var "SECRET_KEY_BASE"
check_env_var "HOST_URL"

echo ""
echo "2. Authentication Variables:"
echo "----------------------------"
check_env_var "GOOGLE_CLIENT_ID"
check_env_var "GOOGLE_CLIENT_SECRET"
check_env_var "JWT_SECRET_KEY"

echo ""
echo "3. Email Variables:"
echo "-------------------"
check_env_var "SENDGRID_API_KEY"

echo ""
echo "4. Redis/Cache Variables:"
echo "-------------------------"
check_env_var "REDIS_URL"
check_env_var "REDISCLOUD_URL"

echo ""
echo "5. Storage Variables:"
echo "---------------------"
check_env_var "GCS_PROJECT_ID"
check_env_var "GCS_BUCKET"
check_env_var "GOOGLE_APPLICATION_CREDENTIALS"

echo ""
echo "6. Rails Environment:"
echo "---------------------"
echo "RAILS_ENV: ${RAILS_ENV:-not_set}"
echo "RACK_ENV: ${RACK_ENV:-not_set}"

echo ""
echo "7. Testing Database Connection:"
echo "-------------------------------"
bundle exec rails runner "
begin
  ActiveRecord::Base.connection.execute('SELECT 1')
  puts '✅ Database connection: SUCCESS'
rescue => e
  puts \"❌ Database connection: FAILED - #{e.message}\"
end
"

echo ""
echo "Environment check complete!"
echo "========================================"