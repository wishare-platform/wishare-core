# Wishare Production Deployment Safety Guide

## 🚨 Critical Data Protection Practices

### Pre-Deployment Checklist

#### 1. Database Backup
```bash
# Railway automatic backup (recommended)
railway db backup

# Manual backup for extra safety
pg_dump $DATABASE_URL > backup_$(date +%Y%m%d_%H%M%S).sql
```

#### 2. Migration Safety Review
- [ ] No enum value changes without data migration
- [ ] No column renames without proper data preservation
- [ ] No new required fields without default values
- [ ] All migrations have proper `down` methods
- [ ] Test migrations on local database copy

#### 3. Staging Environment Testing
- [ ] Deploy to staging first
- [ ] Test all critical user flows
- [ ] Verify admin panel functionality
- [ ] Check analytics data integrity

### High-Risk Changes to Avoid

#### ❌ Dangerous Enum Changes
```ruby
# This would break existing data
enum :visibility, { 
  private: 0,     # Changed from private_list
  shared: 1,      # Changed from partner_only
  public: 2       # Changed from publicly_visible
}
```

#### ❌ Destructive Migrations
```ruby
# These can lose data
remove_column :wishlists, :old_field
rename_column :users, :name, :full_name  # Without data migration
drop_table :old_analytics
```

### ✅ Safe Migration Patterns

#### Enum Changes
```ruby
class UpdateEnumValues < ActiveRecord::Migration[8.0]
  def up
    # Update data first
    Wishlist.where(visibility: 'old_value').update_all(visibility: 'new_value')
    
    # Deploy model changes separately
  end

  def down
    # Always provide rollback
    Wishlist.where(visibility: 'new_value').update_all(visibility: 'old_value')
  end
end
```

#### New Required Fields
```ruby
class AddRequiredField < ActiveRecord::Migration[8.0]
  def change
    # Step 1: Add as nullable
    add_column :wishlists, :new_field, :string, null: true
    
    # Step 2: Populate existing records (separate migration)
    # Step 3: Make non-nullable (separate migration)
  end
end
```

### Railway Deployment Process

#### 1. Environment Variables
```bash
# Verify all required env vars are set
railway vars

# Add new variables before deployment
railway vars set NEW_FEATURE_FLAG=true
```

#### 2. Safe Deployment Steps
```bash
# 1. Deploy to staging
railway up --environment staging

# 2. Test thoroughly
# 3. Deploy to production with backup
railway db backup
railway up --environment production

# 4. Monitor logs immediately
railway logs --tail
```

#### 3. Rollback Plan
```bash
# If issues arise, rollback immediately
git revert HEAD
railway up --environment production

# Or rollback specific migration
railway run rails db:rollback
```

### Database Monitoring

#### Key Metrics to Watch
- Database connection count
- Query performance
- Error rates in logs
- User-reported issues

#### Post-Deployment Checklist
- [ ] Admin panel accessible
- [ ] User registration/login working
- [ ] Wishlist creation/editing working
- [ ] Notifications sending
- [ ] Analytics data collecting

### Emergency Procedures

#### If Data Loss Detected
1. **Immediately stop writes**
   ```bash
   # Put app in maintenance mode if possible
   railway vars set MAINTENANCE_MODE=true
   ```

2. **Restore from backup**
   ```bash
   # Restore latest backup
   railway db restore backup_id
   ```

3. **Investigate and fix**
   - Identify root cause
   - Create migration to fix data
   - Test on staging first

#### Contact Information
- **Database Issues**: Check Railway dashboard
- **Application Errors**: Monitor railway logs
- **Emergency**: Have backup plan ready

## Current Safe State ✅

The recent admin panel changes are **LOW RISK**:
- No existing data structure changes
- Only additive features (new controllers, views)
- Role enum is backward compatible
- No destructive migrations

## Future Considerations

When you have real users:
- Schedule deployments during low-traffic hours
- Consider blue-green deployments for zero downtime
- Implement feature flags for gradual rollouts
- Set up automated monitoring and alerts