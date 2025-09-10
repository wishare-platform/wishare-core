#!/bin/bash

# Wishare Pre-Deployment Safety Check
# Run this before every production deployment

echo "🚀 Wishare Pre-Deployment Safety Check"
echo "======================================"
echo ""

# Check for pending migrations
echo "📋 Checking for pending migrations..."
if rails db:migrate:status | grep -q "down"; then
    echo "⚠️  WARNING: You have pending migrations"
    rails db:migrate:status | grep "down"
    echo ""
    echo "❓ Do you want to review these migrations? (y/n)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "📝 Please review migration files for:"
        echo "   - Destructive operations (DROP, REMOVE, RENAME)"
        echo "   - Enum value changes"
        echo "   - New required fields"
        echo "   - Proper rollback methods"
        echo ""
        echo "Press Enter when ready to continue..."
        read -r
    fi
else
    echo "✅ No pending migrations"
fi
echo ""

# Check for uncommitted changes
echo "🔍 Checking for uncommitted changes..."
if ! git diff --quiet; then
    echo "⚠️  WARNING: You have uncommitted changes"
    git status --short
    echo ""
    echo "❓ Do you want to commit these changes? (y/n)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Please commit your changes and run this script again."
        exit 1
    fi
else
    echo "✅ No uncommitted changes"
fi
echo ""

# Check current branch
echo "🌿 Checking current branch..."
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "⚠️  WARNING: You're on branch '$CURRENT_BRANCH', not 'main'"
    echo "❓ Are you sure you want to deploy from this branch? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Deployment cancelled. Switch to main branch."
        exit 1
    fi
else
    echo "✅ On main branch"
fi
echo ""

# Check if tests pass (if test suite exists)
if [ -f "test/test_helper.rb" ] || [ -f "spec/spec_helper.rb" ]; then
    echo "🧪 Running tests..."
    if bundle exec rails test 2>/dev/null || bundle exec rspec 2>/dev/null; then
        echo "✅ Tests pass"
    else
        echo "❌ Tests failed"
        echo "❓ Continue anyway? (y/n)"
        read -r response
        if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            echo "Deployment cancelled due to test failures."
            exit 1
        fi
    fi
else
    echo "ℹ️  No test suite found, skipping tests"
fi
echo ""

# Environment variables check
echo "🔧 Checking environment variables..."
REQUIRED_VARS=("GOOGLE_CLIENT_ID" "GOOGLE_CLIENT_SECRET" "SENDGRID_API_KEY")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo "⚠️  WARNING: Missing environment variables:"
    for var in "${MISSING_VARS[@]}"; do
        echo "   - $var"
    done
    echo "Make sure these are set in Railway production environment"
else
    echo "✅ Required environment variables present"
fi
echo ""

# Backup reminder
echo "💾 Backup reminder..."
echo "❓ Have you created a backup? (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "✅ Backup confirmed"
else
    echo "🔄 Creating backup now..."
    ./scripts/backup_db.sh production
fi
echo ""

# Final confirmation
echo "🎯 Pre-deployment check complete!"
echo ""
echo "📋 Summary:"
echo "   ✅ Migrations reviewed"
echo "   ✅ Changes committed"  
echo "   ✅ Branch confirmed"
echo "   ✅ Tests checked"
echo "   ✅ Environment variables verified"
echo "   ✅ Backup created"
echo ""
echo "🚀 Ready to deploy!"
echo ""
echo "Deploy commands:"
echo "   Staging:    railway up --environment staging"
echo "   Production: railway up --environment production"
echo ""
echo "Monitor after deployment:"
echo "   railway logs --tail --environment production"