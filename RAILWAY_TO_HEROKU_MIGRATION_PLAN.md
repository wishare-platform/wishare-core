# Wishare Migration Plan: Railway → Heroku

**Migration Date**: TBD
**Estimated Downtime**: < 5 minutes (with proper preparation)
**Estimated Duration**: 3-4 hours total
**Risk Level**: Medium (mitigated with comprehensive rollback strategy)

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Cost Comparison](#cost-comparison)
3. [Pre-Migration Checklist](#pre-migration-checklist)
4. [Phase 1: Heroku Setup](#phase-1-heroku-setup)
5. [Phase 2: Database Migration](#phase-2-database-migration)
6. [Phase 3: SendGrid → Resend Migration](#phase-3-sendgrid--resend-migration)
7. [Phase 4: Application Deployment](#phase-4-application-deployment)
8. [Phase 5: DNS & Domain Configuration](#phase-5-dns--domain-configuration)
9. [Phase 6: Validation & Testing](#phase-6-validation--testing)
10. [Phase 7: Go-Live](#phase-7-go-live)
11. [Rollback Procedures](#rollback-procedures)
12. [Post-Migration Monitoring](#post-migration-monitoring)
13. [Environment Variables Reference](#environment-variables-reference)

---

## Executive Summary

### Migration Objectives
- **Primary Goal**: Reduce monthly infrastructure costs while maintaining performance
- **Secondary Goal**: Improve email deliverability with Resend
- **Timeline**: Complete migration within one maintenance window (3-4 hours)
- **Success Criteria**: Zero data loss, < 5 minutes downtime, all features working

### Key Changes
| Component | Current (Railway) | Target (Heroku) |
|-----------|------------------|-----------------|
| Platform | Railway | Heroku |
| Database | Railway PostgreSQL | Heroku PostgreSQL (Standard-0 or higher) |
| Email Service | SendGrid | Resend |
| Deployment | Dockerfile | Heroku Ruby buildpack |
| Domain | wishare.xyz | wishare.xyz (DNS update) |

---

## Cost Comparison

### Current Railway Costs (Estimated)
```
Web Service (Pro):      $20/month (1 GB RAM, 1 vCPU)
PostgreSQL (Pro):       $10/month (1 GB RAM, 10 GB storage)
Outbound Data Transfer: ~$5/month (varies)
SendGrid (Free Tier):   $0 (100 emails/day)
--------------------------------
TOTAL:                  ~$35-40/month
```

### Projected Heroku Costs
```
Eco Dyno (1 dyno):           $5/month (512 MB RAM)
Standard-0 PostgreSQL:       $25/month (10 GB storage, 20 connections)
  OR Basic PostgreSQL:       $9/month (10 GB storage, 20 connections)
Resend (Free Tier):          $0 (3,000 emails/month, 100/day)
--------------------------------
TOTAL (with Standard-0):     ~$30/month (SAVE $5-10/month)
TOTAL (with Basic):          ~$14/month (SAVE $21-26/month)
```

### Cost Optimization Recommendations
1. **Start with Basic PostgreSQL** ($9/month) - suitable for < 1,000 users
2. **Use Eco Dyno** ($5/month) - sufficient for low-traffic apps
3. **Upgrade to Standard-0** ($25/month) when you hit 500+ concurrent users
4. **Resend Free Tier** - 3,000 emails/month is excellent for current scale

**Estimated Annual Savings**: $60-310/year depending on PostgreSQL plan

---

## Pre-Migration Checklist

### 1. Information Gathering
- [ ] Document all Railway environment variables
- [ ] Verify current database size and connection count
- [ ] List all active users and critical data
- [ ] Review recent activity logs for baseline metrics
- [ ] Document current performance benchmarks (response times, error rates)

### 2. Account Setup
- [ ] Create Heroku account (or verify existing)
- [ ] Install Heroku CLI: `brew install heroku/brew/heroku`
- [ ] Login to Heroku: `heroku login`
- [ ] Create Resend account at https://resend.com
- [ ] Verify Resend domain ownership for wishare.xyz

### 3. Backup Everything
```bash
# Create comprehensive backup directory
mkdir -p ~/wishare-migration-backup-$(date +%Y%m%d)
cd ~/wishare-migration-backup-$(date +%Y%m%d)

# Backup Railway database
railway run pg_dump $DATABASE_URL > railway-backup-full.sql
railway run pg_dump $DATABASE_URL --format=custom > railway-backup-full.dump

# Backup environment variables
railway variables > railway-env-vars.txt

# Backup code
cd /Users/helrabelo/Code/personal/wishare/wishare-core
git status  # Ensure clean working tree
git tag railway-last-deploy-$(date +%Y%m%d)
git push origin railway-last-deploy-$(date +%Y%m%d)

# Verify backups
ls -lh ~/wishare-migration-backup-$(date +%Y%m%d)/
```

### 4. Create Rollback Plan Document
- [ ] Document Railway database connection string
- [ ] Save Railway environment variables in secure location
- [ ] Create rollback timeline (< 10 minutes to restore)
- [ ] Test database restore locally from backup

### 5. Communication Plan
- [ ] Schedule maintenance window (recommend off-peak hours)
- [ ] Prepare user notification (if applicable)
- [ ] Alert any team members or stakeholders

---

## Phase 1: Heroku Setup

**Estimated Time**: 30 minutes
**Risk Level**: Low

### Step 1.1: Create Heroku Application
```bash
cd /Users/helrabelo/Code/personal/wishare/wishare-core

# Create new Heroku app (choose your preferred name)
heroku create wishare-production

# Verify app creation
heroku apps:info -a wishare-production

# Set app to use US region (or EU if preferred)
# Note: Already set during creation, but verify:
heroku regions -a wishare-production
```

### Step 1.2: Add PostgreSQL Database
```bash
# Option A: Basic PostgreSQL ($9/month) - Recommended for start
heroku addons:create heroku-postgresql:basic -a wishare-production

# Option B: Standard-0 PostgreSQL ($25/month) - For production scale
# heroku addons:create heroku-postgresql:standard-0 -a wishare-production

# Verify database creation
heroku addons:info -a wishare-production
heroku pg:info -a wishare-production

# Get database credentials
heroku config:get DATABASE_URL -a wishare-production
```

### Step 1.3: Configure Buildpacks for Rails 8.1
```bash
# Add Ruby buildpack (Rails 8.1 compatible)
heroku buildpacks:add heroku/ruby -a wishare-production

# Add Node.js buildpack for Tailwind CSS compilation
heroku buildpacks:add heroku/nodejs -a wishare-production

# Verify buildpacks order (Node.js should be first, Ruby second)
heroku buildpacks -a wishare-production
```

### Step 1.4: Configure Heroku Stack
```bash
# Verify Heroku stack (should be heroku-24 for Rails 8.1)
heroku stack -a wishare-production

# If needed, set to heroku-24
heroku stack:set heroku-24 -a wishare-production
```

### Step 1.5: Create Procfile for Heroku
```bash
# Create production Procfile (different from Procfile.dev)
cat > Procfile << 'EOF'
web: bundle exec puma -C config/puma.rb
release: bundle exec rake db:migrate
worker: bundle exec solid_queue start
EOF

# Commit Procfile
git add Procfile
git commit -m "Add Heroku Procfile for production deployment"
```

### Step 1.6: Configure Puma for Heroku
Ensure `/Users/helrabelo/Code/personal/wishare/wishare-core/config/puma.rb` is Heroku-compatible:

```ruby
# config/puma.rb
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Heroku sets PORT environment variable
port ENV.fetch("PORT") { 3000 }

environment ENV.fetch("RAILS_ENV") { "development" }

# Heroku recommends workers = 2 for Eco/Basic dynos, 3-4 for Standard
workers ENV.fetch("WEB_CONCURRENCY") { 2 }

preload_app!

on_worker_boot do
  ActiveRecord::Base.establish_connection
end

plugin :tmp_restart
```

**Validation Checklist:**
- [ ] Heroku app created successfully
- [ ] PostgreSQL addon provisioned
- [ ] Buildpacks configured (Node.js + Ruby)
- [ ] Procfile created and committed
- [ ] Puma configuration verified

---

## Phase 2: Database Migration

**Estimated Time**: 45-60 minutes
**Risk Level**: HIGH (requires careful execution)
**Downtime**: 5-10 minutes during final switch

### Step 2.1: Analyze Current Database
```bash
# Connect to Railway database and gather metrics
railway run psql $DATABASE_URL

-- Run these SQL queries to understand your data:
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Count critical records
SELECT 'users' AS table_name, COUNT(*) FROM users
UNION ALL
SELECT 'wishlists', COUNT(*) FROM wishlists
UNION ALL
SELECT 'wishlist_items', COUNT(*) FROM wishlist_items
UNION ALL
SELECT 'connections', COUNT(*) FROM connections
UNION ALL
SELECT 'activity_feeds', COUNT(*) FROM activity_feeds;

-- Check for any long-running transactions or locks
SELECT * FROM pg_stat_activity WHERE state != 'idle';

\q
```

### Step 2.2: Create Final Production Backup
```bash
# Create timestamped backup
BACKUP_FILE="railway-final-backup-$(date +%Y%m%d-%H%M%S).dump"

railway run pg_dump $DATABASE_URL --format=custom --no-owner --no-acl > ~/wishare-migration-backup-$(date +%Y%m%d)/$BACKUP_FILE

# Verify backup file exists and has reasonable size
ls -lh ~/wishare-migration-backup-$(date +%Y%m%d)/$BACKUP_FILE

# Calculate backup checksum for integrity verification
shasum -a 256 ~/wishare-migration-backup-$(date +%Y%m%d)/$BACKUP_FILE > ~/wishare-migration-backup-$(date +%Y%m%d)/$BACKUP_FILE.sha256
```

### Step 2.3: Test Database Restore Locally (Critical Step)
```bash
# Create test database locally
createdb wishare_migration_test

# Restore backup to test database
pg_restore --verbose --clean --no-acl --no-owner \
  -d wishare_migration_test \
  ~/wishare-migration-backup-$(date +%Y%m%d)/$BACKUP_FILE

# Verify restoration
psql wishare_migration_test -c "SELECT COUNT(*) FROM users;"
psql wishare_migration_test -c "SELECT COUNT(*) FROM wishlists;"

# If successful, clean up test database
dropdb wishare_migration_test
```

### Step 2.4: Restore to Heroku PostgreSQL
```bash
# Get Heroku database connection details
heroku pg:info -a wishare-production

# Upload backup to temporary hosting (Heroku requires accessible URL)
# Option A: Use Heroku's pg:backups restore feature
heroku pg:backups:restore \
  "$(cat ~/wishare-migration-backup-$(date +%Y%m%d)/$BACKUP_FILE | base64)" \
  DATABASE_URL \
  -a wishare-production \
  --confirm wishare-production

# Option B: Use pg_restore directly (requires Heroku Postgres connection string)
HEROKU_DB_URL=$(heroku config:get DATABASE_URL -a wishare-production)

pg_restore --verbose --clean --no-acl --no-owner \
  -d "$HEROKU_DB_URL" \
  ~/wishare-migration-backup-$(date +%Y%m%d)/$BACKUP_FILE

# Note: You may see some harmless errors about roles/ownership - this is normal
```

### Step 2.5: Verify Database Migration
```bash
# Connect to Heroku database
heroku pg:psql -a wishare-production

-- Verify table counts match Railway
SELECT 'users' AS table_name, COUNT(*) FROM users
UNION ALL
SELECT 'wishlists', COUNT(*) FROM wishlists
UNION ALL
SELECT 'wishlist_items', COUNT(*) FROM wishlist_items
UNION ALL
SELECT 'connections', COUNT(*) FROM connections
UNION ALL
SELECT 'activity_feeds', COUNT(*) FROM activity_feeds;

-- Verify indexes exist
SELECT tablename, indexname FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- Verify sequences are correct
SELECT sequence_name, last_value FROM information_schema.sequences
WHERE sequence_schema = 'public';

\q
```

### Step 2.6: Database Migration Checklist
- [ ] Railway database analyzed and documented
- [ ] Final backup created with timestamp
- [ ] Backup checksum calculated
- [ ] Local restore test completed successfully
- [ ] Heroku database restore completed
- [ ] Record counts verified (Railway vs Heroku)
- [ ] Indexes verified
- [ ] Sequences verified
- [ ] No data loss detected

**Rollback Trigger**: If any verification fails, DO NOT proceed. Roll back immediately.

---

## Phase 3: SendGrid → Resend Migration

**Estimated Time**: 30 minutes
**Risk Level**: Low

### Step 3.1: Setup Resend Account
1. **Create Account**: https://resend.com/signup
2. **Verify Email**: Complete email verification
3. **Add Domain**: Go to Domains → Add Domain → `wishare.xyz`
4. **Add DNS Records**: Add Resend's DNS records to your domain registrar:
   ```
   Type: TXT
   Name: @
   Value: [Resend verification code]

   Type: CNAME
   Name: resend._domainkey
   Value: [Resend DKIM record]

   Type: TXT
   Name: _dmarc
   Value: v=DMARC1; p=none; rua=mailto:dmarc@wishare.xyz
   ```
5. **Verify Domain**: Wait for DNS propagation (5-30 minutes), then verify in Resend dashboard
6. **Generate API Key**: API Keys → Create API Key → Copy securely

### Step 3.2: Update Rails Email Configuration

**Create Resend Mailer Adapter** (`lib/resend_delivery.rb`):
```ruby
# lib/resend_delivery.rb
require 'net/http'
require 'json'

class ResendDelivery
  attr_accessor :settings

  def initialize(settings)
    @settings = settings
  end

  def deliver!(mail)
    api_key = settings[:api_key] || ENV['RESEND_API_KEY']
    raise "Resend API key not configured" unless api_key

    uri = URI('https://api.resend.com/emails')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request['Authorization'] = "Bearer #{api_key}"
    request['Content-Type'] = 'application/json'

    # Build email payload
    payload = {
      from: "#{mail[:from].display_names.first || 'Wishare'} <#{mail.from.first}>",
      to: mail.to,
      subject: mail.subject
    }

    # Add CC/BCC if present
    payload[:cc] = mail.cc if mail.cc.present?
    payload[:bcc] = mail.bcc if mail.bcc.present?

    # Add content (HTML or text)
    if mail.html_part
      payload[:html] = mail.html_part.body.to_s
    elsif mail.text_part
      payload[:text] = mail.text_part.body.to_s
    elsif mail.content_type =~ /text\/html/
      payload[:html] = mail.body.to_s
    else
      payload[:text] = mail.body.to_s
    end

    request.body = payload.to_json

    response = http.request(request)

    if response.code.to_i >= 400
      Rails.logger.error "Resend API Error: #{response.code} - #{response.body}"
      raise "Resend API Error: #{response.code} - #{response.body}"
    else
      Rails.logger.info "Email sent successfully via Resend API: #{response.code}"
    end

    response
  end
end
```

**Create Resend Initializer** (`config/initializers/resend.rb`):
```ruby
# config/initializers/resend.rb
unless ENV['SECRET_KEY_BASE_DUMMY'] == '1'
  require_relative '../../lib/resend_delivery'
  ActionMailer::Base.add_delivery_method :resend, ResendDelivery
end
```

**Update Production Environment** (`config/environments/production.rb`):
```ruby
# config/environments/production.rb
# Find the SendGrid configuration section and replace with:

# Configure Resend for email delivery
unless ENV['SECRET_KEY_BASE_DUMMY'] == '1'
  config.action_mailer.delivery_method = :resend
  config.action_mailer.resend_settings = {
    api_key: ENV['RESEND_API_KEY']
  }
else
  config.action_mailer.delivery_method = :test
end
```

**Update Gemfile** (remove sendgrid-ruby, it's no longer needed):
```ruby
# Gemfile
# Remove this line:
# gem "sendgrid-ruby"

# No additional gem needed for Resend (uses Net::HTTP)
```

### Step 3.3: Test Email Locally
```bash
# Add Resend API key to local environment
echo 'export RESEND_API_KEY="re_your_api_key_here"' >> ~/.zshrc
source ~/.zshrc

# Start Rails console
cd /Users/helrabelo/Code/personal/wishare/wishare-core
rails console

# Test email sending
ActionMailer::Base.delivery_method = :resend
ActionMailer::Base.resend_settings = { api_key: ENV['RESEND_API_KEY'] }

# Send test email
DeviseMailer.confirmation_instructions(User.first, 'fake-token').deliver_now

# Check Resend dashboard for delivery confirmation
```

### Step 3.4: Remove SendGrid Dependencies
```bash
# Remove SendGrid files
rm config/initializers/sendgrid_api.rb
rm lib/sendgrid_api_delivery.rb

# Update Gemfile
bundle install

# Commit changes
git add .
git commit -m "Replace SendGrid with Resend for email delivery"
```

**Validation Checklist:**
- [ ] Resend account created and verified
- [ ] Domain verified in Resend dashboard
- [ ] DNS records added and propagated
- [ ] API key generated and saved securely
- [ ] ResendDelivery class created
- [ ] Resend initializer created
- [ ] Production.rb updated
- [ ] Test email sent successfully
- [ ] SendGrid files removed
- [ ] Changes committed to git

---

## Phase 4: Application Deployment

**Estimated Time**: 45 minutes
**Risk Level**: Medium

### Step 4.1: Configure Environment Variables
```bash
# Set all required environment variables on Heroku
heroku config:set RAILS_ENV=production -a wishare-production
heroku config:set RACK_ENV=production -a wishare-production
heroku config:set RAILS_LOG_TO_STDOUT=enabled -a wishare-production
heroku config:set RAILS_SERVE_STATIC_FILES=true -a wishare-production

# Rails secret keys (generate new ones)
heroku config:set SECRET_KEY_BASE=$(rails secret) -a wishare-production
heroku config:set RAILS_MASTER_KEY=$(cat config/master.key) -a wishare-production

# Host configuration
heroku config:set HOST_URL=wishare.xyz -a wishare-production

# Resend API
heroku config:set RESEND_API_KEY=re_your_api_key_here -a wishare-production

# Google OAuth (copy from Railway)
heroku config:set GOOGLE_CLIENT_ID=your_client_id -a wishare-production
heroku config:set GOOGLE_CLIENT_SECRET=your_client_secret -a wishare-production

# Google Cloud Storage (if using GCS for Active Storage)
heroku config:set GOOGLE_CLOUD_PROJECT=cupidgifts-53f25c269968 -a wishare-production
heroku config:set GOOGLE_CLOUD_KEYFILE=$(cat cupidgifts-53f25c269968.json | base64) -a wishare-production

# Rails 8 Solid Queue/Cache/Cable configuration
heroku config:set SOLID_QUEUE_IN_PUMA=true -a wishare-production

# Database URL (should already be set by Heroku PostgreSQL addon)
# heroku config:get DATABASE_URL -a wishare-production

# Verify all variables are set
heroku config -a wishare-production
```

### Step 4.2: Update Google OAuth Redirect URIs
1. Go to https://console.cloud.google.com/
2. Navigate to: APIs & Services → Credentials
3. Click on your OAuth 2.0 Client ID
4. Add authorized redirect URIs:
   ```
   https://wishare-production.herokuapp.com/users/auth/google_oauth2/callback
   https://wishare.xyz/users/auth/google_oauth2/callback
   ```
5. Save changes

### Step 4.3: Deploy to Heroku
```bash
cd /Users/helrabelo/Code/personal/wishare/wishare-core

# Ensure you're on main/master branch with latest changes
git checkout main
git status

# Add Heroku remote (if not already added)
heroku git:remote -a wishare-production

# Deploy application
git push heroku main

# Monitor deployment logs
heroku logs --tail -a wishare-production
```

### Step 4.4: Run Database Migrations
```bash
# Migrations should run automatically via release phase in Procfile
# But verify they completed successfully:
heroku run rails db:migrate:status -a wishare-production

# If migrations didn't run, run manually:
heroku run rails db:migrate -a wishare-production
```

### Step 4.5: Verify Application Health
```bash
# Check dyno status
heroku ps -a wishare-production

# Check application logs for errors
heroku logs --tail -a wishare-production

# Open application in browser
heroku open -a wishare-production

# Test health endpoint
curl https://wishare-production.herokuapp.com/up

# Run Rails console to verify app configuration
heroku run rails console -a wishare-production
```

### Step 4.6: Scale Dynos (if needed)
```bash
# By default, one web dyno is started
# To add worker dyno for Solid Queue background jobs:
heroku ps:scale worker=1 -a wishare-production

# To scale web dynos for higher traffic:
# heroku ps:scale web=2 -a wishare-production

# Check current dyno formation
heroku ps -a wishare-production
```

**Validation Checklist:**
- [ ] All environment variables configured
- [ ] Google OAuth redirect URIs updated
- [ ] Application deployed successfully
- [ ] Database migrations completed
- [ ] Dynos are running (web + worker)
- [ ] Health endpoint responding
- [ ] No critical errors in logs
- [ ] Rails console accessible

---

## Phase 5: DNS & Domain Configuration

**Estimated Time**: 15 minutes (+ DNS propagation time)
**Risk Level**: Low
**Downtime**: None (DNS propagation happens gradually)

### Step 5.1: Add Custom Domain to Heroku
```bash
# Add custom domain
heroku domains:add wishare.xyz -a wishare-production
heroku domains:add www.wishare.xyz -a wishare-production

# Get DNS target from Heroku
heroku domains -a wishare-production

# You'll see output like:
# Domain Name        DNS Target
# wishare.xyz        wishare-production-abc123.herokudns.com
# www.wishare.xyz    wishare-production-abc123.herokudns.com
```

### Step 5.2: Configure DNS Records
Log into your domain registrar (where wishare.xyz is registered) and update DNS records:

**For Apex Domain (wishare.xyz):**
```
Type: CNAME (or ALIAS/ANAME if your registrar supports it)
Name: @
Value: wishare-production-abc123.herokudns.com
TTL: 300 (5 minutes for faster propagation)
```

**For WWW Subdomain (www.wishare.xyz):**
```
Type: CNAME
Name: www
Value: wishare-production-abc123.herokudns.com
TTL: 300
```

**Important DNS Notes:**
- Some registrars don't support CNAME for apex domains. In that case, use ALIAS or ANAME record
- If your registrar doesn't support ALIAS/ANAME, consider using a DNS service like Cloudflare
- Keep TTL low (300s) during migration for faster rollback if needed

### Step 5.3: Enable Automated Certificate Management (ACM)
```bash
# Heroku automatically provisions SSL certificates via Let's Encrypt
# Wait for certificate provisioning (takes 30-60 minutes after DNS propagation)
heroku certs:auto:enable -a wishare-production

# Check certificate status
heroku certs:info -a wishare-production

# You should see status: Provisioning or Issued
```

### Step 5.4: Verify DNS Propagation
```bash
# Check DNS resolution (repeat until it shows Heroku IP)
dig wishare.xyz
dig www.wishare.xyz

# Check from multiple locations
# https://www.whatsmydns.net/#CNAME/wishare.xyz

# Test HTTPS access (after certificate is issued)
curl -I https://wishare.xyz
```

**Validation Checklist:**
- [ ] Custom domains added to Heroku
- [ ] DNS records updated at registrar
- [ ] DNS propagation verified
- [ ] SSL certificate provisioned
- [ ] HTTPS access working
- [ ] HTTP → HTTPS redirect working

---

## Phase 6: Validation & Testing

**Estimated Time**: 30 minutes
**Risk Level**: Low

### Step 6.1: Functional Testing Checklist

**Authentication Tests:**
- [ ] User registration works (email delivery)
- [ ] User login works (email/password)
- [ ] Google OAuth login works
- [ ] Password reset works (email delivery)
- [ ] Email confirmation works

**Core Features:**
- [ ] Dashboard loads correctly
- [ ] Create new wishlist
- [ ] Add items to wishlist
- [ ] URL metadata extraction works
- [ ] Edit wishlist/items
- [ ] Delete wishlist/items
- [ ] Share wishlist (copy link)
- [ ] View public wishlist (logged out)

**Social Features:**
- [ ] Send connection invitation
- [ ] Accept connection invitation
- [ ] View friends' wishlists
- [ ] Activity feed updates
- [ ] Notifications work (in-app)

**Profile & Settings:**
- [ ] Edit profile information
- [ ] Upload profile picture
- [ ] Change password
- [ ] Update email preferences
- [ ] Change language (English/Portuguese)

**Admin Panel:**
- [ ] Admin login at /admin
- [ ] User management works
- [ ] Analytics dashboard loads

### Step 6.2: Performance Testing
```bash
# Run performance benchmarks
heroku run rails runner "
  require 'benchmark'
  puts 'Testing database queries...'
  puts Benchmark.measure {
    User.includes(:wishlists, :connections).limit(10).to_a
  }

  puts 'Testing activity feed...'
  puts Benchmark.measure {
    ActivityFeed.dashboard_optimized.limit(20).to_a
  }
" -a wishare-production

# Check response times
curl -w "@-" -o /dev/null -s https://wishare.xyz <<'EOF'
    time_namelookup:  %{time_namelookup}\n
       time_connect:  %{time_connect}\n
    time_appconnect:  %{time_appconnect}\n
   time_pretransfer:  %{time_pretransfer}\n
      time_redirect:  %{time_redirect}\n
 time_starttransfer:  %{time_starttransfer}\n
                    ----------\n
         time_total:  %{time_total}\n
EOF
```

**Performance Targets:**
- Dashboard load: < 500ms
- Wishlist index: < 300ms
- Item creation: < 200ms
- API responses: < 150ms

### Step 6.3: Email Testing
```bash
# Test all email types from Rails console
heroku run rails console -a wishare-production

# Test confirmation email
user = User.first
DeviseMailer.confirmation_instructions(user, user.confirmation_token).deliver_now

# Test password reset email
DeviseMailer.reset_password_instructions(user, user.reset_password_token).deliver_now

# Test invitation email
invitation = Invitation.first
InvitationMailer.invitation_email(invitation).deliver_now

# Exit console
exit

# Verify emails in Resend dashboard
# https://resend.com/emails
```

### Step 6.4: Database Connection Testing
```bash
# Verify connection pool usage
heroku pg:info -a wishare-production

# Check for connection leaks
heroku run rails runner "
  puts 'Active connections: '
  puts ActiveRecord::Base.connection_pool.stat
" -a wishare-production

# Run database maintenance
heroku pg:maintenance -a wishare-production
```

### Step 6.5: Monitoring & Logging
```bash
# Enable Heroku runtime metrics
heroku labs:enable runtime-dyno-metadata -a wishare-production

# Check application metrics
heroku ps:autoscale:enable web --min 1 --max 2 --p95 500 -a wishare-production

# Monitor logs for errors
heroku logs --tail --source app -a wishare-production

# Check for any 500 errors
heroku logs --tail | grep "500 Internal Server Error"
```

**Validation Checklist:**
- [ ] All authentication flows working
- [ ] Core features tested and working
- [ ] Social features operational
- [ ] Profile management working
- [ ] Admin panel accessible
- [ ] Performance meets targets
- [ ] All email types delivering
- [ ] Database connections stable
- [ ] No critical errors in logs

---

## Phase 7: Go-Live

**Estimated Time**: 15 minutes
**Risk Level**: Low (if all validations passed)

### Step 7.1: Final Pre-Flight Checks
```bash
# Verify Heroku app is fully operational
heroku ps -a wishare-production
heroku config -a wishare-production
heroku pg:info -a wishare-production

# Check DNS propagation globally
dig wishare.xyz +short
nslookup wishare.xyz

# Verify SSL certificate
curl -I https://wishare.xyz | grep -i "HTTP\|SSL"

# Test critical user journey
# 1. Visit https://wishare.xyz
# 2. Sign up new account
# 3. Verify email received
# 4. Create wishlist
# 5. Add items
# 6. Share wishlist link
```

### Step 7.2: Update Application URLs
Update any hardcoded URLs in your application:

```bash
# Search for Railway URLs
grep -r "railway.app" /Users/helrabelo/Code/personal/wishare/wishare-core/

# Update any configuration files
# Update mobile app URLs (iOS/Android)
# Update any external service webhooks
```

### Step 7.3: Decommission Railway (After Verification)
**DO NOT do this until you've verified Heroku is working for 24-48 hours**

```bash
# After 24-48 hours of stable operation on Heroku:

# 1. Download final Railway logs for records
railway logs > railway-final-logs-$(date +%Y%m%d).txt

# 2. Remove Railway service (but keep database temporarily)
railway service delete wishare-web

# 3. Keep Railway database running for 1 week as backup
# 4. After 1 week of stable Heroku operation, remove Railway database
railway service delete wishare-database

# 5. Cancel Railway subscription (if no other projects)
```

### Step 7.4: Update Documentation
```bash
# Update CLAUDE.md with new infrastructure details
cat >> /Users/helrabelo/Code/personal/wishare/CLAUDE.md << 'EOF'

## Production Infrastructure (Updated Sept 2025)
- **Platform**: Heroku (migrated from Railway)
- **Application**: wishare-production.herokuapp.com → wishare.xyz
- **Database**: Heroku PostgreSQL (Standard-0 or Basic)
- **Email Service**: Resend (migrated from SendGrid)
- **SSL**: Automated Certificate Management (Let's Encrypt)
- **Monthly Cost**: ~$14-30 (depending on database plan)

### Deployment Commands
```bash
# Deploy to production
git push heroku main

# Run migrations
heroku run rails db:migrate -a wishare-production

# Rails console
heroku run rails console -a wishare-production

# View logs
heroku logs --tail -a wishare-production

# Scale dynos
heroku ps:scale web=1 worker=1 -a wishare-production
```
EOF
```

**Go-Live Checklist:**
- [ ] All pre-flight checks passed
- [ ] DNS fully propagated globally
- [ ] SSL certificate active
- [ ] Critical user journeys tested
- [ ] No errors in production logs
- [ ] Mobile apps tested (if deployed)
- [ ] Documentation updated
- [ ] Railway still running as backup

---

## Rollback Procedures

### Rollback Decision Matrix

| Scenario | Severity | Action | Timeframe |
|----------|----------|--------|-----------|
| Minor UI issues | Low | Monitor, fix in next deploy | 24 hours |
| Email delivery failing | Medium | Revert Resend changes, restore SendGrid | 30 minutes |
| Database connection issues | High | Rollback DNS, restore Railway | 10 minutes |
| Complete application failure | Critical | Full rollback to Railway | 5 minutes |

### Emergency Rollback: Full Return to Railway

**If you need to rollback completely, follow these steps:**

```bash
# STEP 1: Revert DNS immediately (fastest way to restore service)
# Log into domain registrar and change DNS records back to Railway:
# Type: CNAME
# Name: @
# Value: [your-railway-domain].railway.app

# STEP 2: Verify Railway app is still running
railway status

# If Railway was stopped, restart it:
railway up

# STEP 3: Restore database to Railway (if data loss occurred)
# This should only be needed if data was created on Heroku that needs to be preserved

# Create backup of Heroku database
heroku pg:backups:capture -a wishare-production
heroku pg:backups:download -a wishare-production

# Restore to Railway
railway run pg_restore --verbose --clean --no-acl --no-owner -d $DATABASE_URL latest.dump

# STEP 4: Revert email configuration
# If Resend migration was deployed, revert these commits:
git revert HEAD~3..HEAD  # Adjust based on number of commits to revert
git push origin main
railway up

# STEP 5: Verify Railway is working
curl https://[your-railway-domain].railway.app/up

# STEP 6: Wait for DNS propagation (5-30 minutes)
# Monitor: https://www.whatsmydns.net/#CNAME/wishare.xyz
```

### Partial Rollback: Email Only

**If only email delivery is failing:**

```bash
# STEP 1: Revert Resend changes
cd /Users/helrabelo/Code/personal/wishare/wishare-core
git revert [commit-hash-of-resend-migration]

# STEP 2: Restore SendGrid configuration
git checkout [last-sendgrid-commit] -- config/initializers/sendgrid_api.rb
git checkout [last-sendgrid-commit] -- lib/sendgrid_api_delivery.rb
git checkout [last-sendgrid-commit] -- config/environments/production.rb

# STEP 3: Restore SendGrid gem
# Add back to Gemfile:
echo 'gem "sendgrid-ruby"' >> Gemfile
bundle install

# STEP 4: Set SendGrid API key on Heroku
heroku config:set SENDGRID_API_KEY=[your-sendgrid-key] -a wishare-production

# STEP 5: Deploy fix
git add .
git commit -m "Rollback to SendGrid for email delivery"
git push heroku main

# STEP 6: Test email
heroku run rails console -a wishare-production
# > DeviseMailer.confirmation_instructions(User.first, 'test-token').deliver_now
```

### Partial Rollback: Database Only

**If database issues occur but app is working:**

```bash
# STEP 1: Stop Heroku app to prevent writes
heroku maintenance:on -a wishare-production

# STEP 2: Restore from Railway backup
HEROKU_DB_URL=$(heroku config:get DATABASE_URL -a wishare-production)

pg_restore --verbose --clean --no-acl --no-owner \
  -d "$HEROKU_DB_URL" \
  ~/wishare-migration-backup-[date]/railway-final-backup-[timestamp].dump

# STEP 3: Verify restoration
heroku pg:psql -a wishare-production
# Run verification queries from Step 2.5

# STEP 4: Resume app
heroku maintenance:off -a wishare-production
```

**Rollback Validation Checklist:**
- [ ] Railway app is running
- [ ] DNS points to Railway
- [ ] Database restored successfully
- [ ] Email delivery working
- [ ] User authentication working
- [ ] All critical features operational

---

## Post-Migration Monitoring

### Week 1: Intensive Monitoring

**Daily Checks (7 days):**
```bash
# Morning check (9am)
heroku ps -a wishare-production
heroku logs --tail --source app | grep ERROR
heroku pg:info -a wishare-production

# Midday check (2pm)
# Visit https://wishare.xyz and test critical features
# Check Resend dashboard for email delivery stats

# Evening check (8pm)
heroku logs --tail | grep "500 Internal Server Error"
heroku pg:diagnose -a wishare-production
```

**Key Metrics to Monitor:**
- Response times (target: < 500ms for dashboard)
- Error rate (target: < 0.1%)
- Database connection pool usage (target: < 80%)
- Email delivery rate (target: > 98%)
- Dyno memory usage (target: < 400MB for Eco dyno)
- SSL certificate status (should be "Issued")

### Week 2-4: Regular Monitoring

**Every 2-3 Days:**
```bash
# Quick health check
curl https://wishare.xyz/up
heroku logs --tail -a wishare-production | grep -E "ERROR|WARN"

# Database maintenance
heroku pg:maintenance -a wishare-production

# Check for long-running queries
heroku pg:ps -a wishare-production
```

### Month 1+: Automated Monitoring

**Setup Heroku Alerts:**
```bash
# Enable Heroku Dyno metadata
heroku labs:enable runtime-dyno-metadata -a wishare-production

# Create alerts for critical metrics (requires Heroku paid plan)
# - Dyno memory > 80%
# - Response time > 1000ms
# - Error rate > 1%
# - Database connections > 18 (out of 20)
```

**Consider Adding Monitoring Tools:**
- **New Relic**: Free tier available (heroku addons:create newrelic:wayne)
- **Papertrail**: Log aggregation (heroku addons:create papertrail:choklad)
- **Scout APM**: Performance monitoring (heroku addons:create scout:chair)
- **Honeybadger**: Error tracking (external service)

### Cost Optimization Review (After 30 Days)

**Analyze actual usage and optimize:**
```bash
# Review dyno usage
heroku ps:autoscale -a wishare-production

# Review database usage
heroku pg:info -a wishare-production

# Check if you can downgrade database plan
# If connections consistently < 10 and storage < 8GB, Basic plan is sufficient

# Review add-on costs
heroku addons -a wishare-production
```

**Cost Optimization Opportunities:**
- If traffic is low: Keep Eco dyno ($5/month)
- If database usage < 8GB: Use Basic PostgreSQL ($9/month)
- If email volume < 3000/month: Stay on Resend free tier
- If no background jobs: Remove worker dyno

### Performance Optimization (Ongoing)

**Monthly Performance Review:**
```bash
# Run performance profiler
heroku run rails runner "
  require 'benchmark'

  puts 'Dashboard Query Performance:'
  puts Benchmark.measure {
    User.includes(:wishlists, :activity_feeds).first(10)
  }

  puts 'Wishlist Index Performance:'
  puts Benchmark.measure {
    Wishlist.with_attached_cover_image.limit(20)
  }
" -a wishare-production

# Identify slow queries
heroku pg:outliers -a wishare-production

# Review cache hit rate (if using Redis)
# heroku redis:info -a wishare-production
```

---

## Environment Variables Reference

### Complete Environment Variables List

**Copy these from Railway and set on Heroku:**

```bash
# Core Rails Configuration
RAILS_ENV=production
RACK_ENV=production
RAILS_LOG_TO_STDOUT=enabled
RAILS_SERVE_STATIC_FILES=true
SECRET_KEY_BASE=[generate with: rails secret]
RAILS_MASTER_KEY=[from config/master.key]

# Application Configuration
HOST_URL=wishare.xyz

# Database (auto-set by Heroku PostgreSQL addon)
DATABASE_URL=[auto-set-by-heroku]

# Email Service (Resend)
RESEND_API_KEY=re_[your-resend-api-key]

# Google OAuth
GOOGLE_CLIENT_ID=[your-google-client-id]
GOOGLE_CLIENT_SECRET=[your-google-client-secret]

# Google Cloud Storage (if using GCS)
GOOGLE_CLOUD_PROJECT=cupidgifts-53f25c269968
GOOGLE_CLOUD_KEYFILE=[base64-encoded-json-keyfile]

# Rails 8 Solid Queue/Cache/Cable
SOLID_QUEUE_IN_PUMA=true

# Optional: Performance & Scaling
WEB_CONCURRENCY=2  # Puma workers
RAILS_MAX_THREADS=5  # Puma threads
RAILS_MIN_THREADS=5

# Optional: Monitoring
NEW_RELIC_LICENSE_KEY=[if-using-new-relic]
SCOUT_KEY=[if-using-scout]

# Optional: Feature Flags
ENABLE_BACKGROUND_JOBS=true
MAINTENANCE_MODE=false
```

### Quick Command to Set All Variables:

```bash
# Create a script to set all variables at once
cat > set_heroku_env.sh << 'EOF'
#!/bin/bash

heroku config:set \
  RAILS_ENV=production \
  RACK_ENV=production \
  RAILS_LOG_TO_STDOUT=enabled \
  RAILS_SERVE_STATIC_FILES=true \
  SECRET_KEY_BASE=$(rails secret) \
  HOST_URL=wishare.xyz \
  RESEND_API_KEY=re_your_key_here \
  GOOGLE_CLIENT_ID=your_client_id \
  GOOGLE_CLIENT_SECRET=your_client_secret \
  SOLID_QUEUE_IN_PUMA=true \
  WEB_CONCURRENCY=2 \
  RAILS_MAX_THREADS=5 \
  -a wishare-production

echo "Environment variables set successfully!"
EOF

chmod +x set_heroku_env.sh
./set_heroku_env.sh
```

---

## Migration Timeline Summary

### Pre-Migration (Week before)
- [ ] Review this plan completely
- [ ] Create Heroku account
- [ ] Create Resend account
- [ ] Backup all Railway data
- [ ] Schedule maintenance window
- [ ] Notify users (if applicable)

### Migration Day (3-4 hours)
- **Hour 1**: Heroku setup, database migration prep
- **Hour 2**: Database migration and verification
- **Hour 3**: Email migration, application deployment
- **Hour 4**: DNS update, SSL provisioning, testing

### Post-Migration
- **Week 1**: Daily monitoring, intensive checks
- **Week 2-4**: Regular monitoring every 2-3 days
- **After 1 week**: Decommission Railway database
- **After 1 month**: Cost optimization review

---

## Success Criteria

### Migration Success Definition:
✅ Zero data loss (all records migrated)
✅ < 5 minutes downtime experienced by users
✅ All features working (auth, wishlists, email, etc.)
✅ Performance meets or exceeds Railway baseline
✅ Cost reduced by 15-60% (depending on database plan)
✅ Email deliverability maintained or improved
✅ SSL/HTTPS working correctly
✅ Mobile apps still functional (if deployed)
✅ No critical errors in logs after 24 hours
✅ User satisfaction maintained (no complaints)

---

## Support Resources

### Heroku Documentation
- **Heroku Dev Center**: https://devcenter.heroku.com/
- **Rails on Heroku**: https://devcenter.heroku.com/articles/getting-started-with-rails8
- **PostgreSQL on Heroku**: https://devcenter.heroku.com/articles/heroku-postgresql
- **SSL Certificates**: https://devcenter.heroku.com/articles/automated-certificate-management

### Resend Documentation
- **Resend Docs**: https://resend.com/docs
- **Domain Setup**: https://resend.com/docs/dashboard/domains/introduction
- **API Reference**: https://resend.com/docs/api-reference/introduction

### Community Support
- **Heroku Community**: https://help.heroku.com/
- **Rails Discord**: https://discord.gg/rails
- **Stack Overflow**: Search "heroku rails deployment"

### Emergency Contacts
- **Heroku Support**: https://help.heroku.com/tickets
- **Resend Support**: support@resend.com

---

## Final Notes

### Best Practices for Success
1. **Don't Rush**: Follow each step carefully, validate before moving forward
2. **Keep Railway Running**: Don't delete Railway until 7 days of stable Heroku operation
3. **Monitor Closely**: Watch logs, metrics, and user feedback for first week
4. **Test Thoroughly**: Complete all validation steps before declaring success
5. **Document Everything**: Keep notes on any issues and how you solved them

### Common Pitfalls to Avoid
- ❌ Not testing database restore before migration day
- ❌ Forgetting to update Google OAuth redirect URIs
- ❌ Deleting Railway immediately after migration
- ❌ Not checking email deliverability after Resend migration
- ❌ Skipping DNS propagation verification
- ❌ Not having a rollback plan ready

### When to Seek Help
- Database restore fails multiple times
- SSL certificate doesn't provision after 2 hours
- Email delivery fails consistently
- Application won't start on Heroku
- Performance significantly degrades vs Railway

**Don't hesitate to roll back if something feels wrong. It's better to retry the migration than to have a broken production app.**

---

## Change Log

**Version 1.0** - September 30, 2025
- Initial comprehensive migration plan created
- Includes all phases from setup to monitoring
- Cost comparison and optimization strategies
- Complete rollback procedures
- Environment variables reference

---

**Good luck with your migration! Remember: measure twice, cut once. Take your time and follow each step carefully.**
