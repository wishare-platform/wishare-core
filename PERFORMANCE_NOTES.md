# Performance Optimization Notes

## Counter Cache Lessons Learned (Sept 18, 2025)

### Issue Summary
- **Problem**: Added Rails `counter_cache: true` to User associations (wishlists, activity_feeds)
- **Error**: `NoMethodError: undefined method '-@' for nil` in application layout
- **Impact**: Broke dashboard and wishlists pages for all users

### Root Cause Analysis
1. **Rails 8.0+ Behavior**: Counter cache implementation has stricter requirements in newer Rails versions
2. **Complex Queries**: Layout rendering involves complex association queries that conflict with counter cache
3. **Association Loading**: Counter cache interferes with Rails association lazy loading in views
4. **String Operations**: The `-@` error suggests Rails was performing string operations on nil during association resolution

### Solution Applied
- Removed `counter_cache: true` from User model associations
- Kept database columns (`wishlists_count`, `activity_feeds_count`, `connections_count`) for future use
- Reverted to standard Rails association queries

### Performance Guidelines

#### Current Approach (< 1000 users)
- **Use standard Rails associations** - Performance is adequate for current user base
- **Database indexes are sufficient** - Existing indexes handle current query load effectively
- **Avoid premature optimization** - Counter caches add complexity without significant benefit

#### Future Performance Strategies (when needed)

##### Option 1: Manual Caching (Recommended)
```ruby
class User < ApplicationRecord
  def cached_wishlists_count
    Rails.cache.fetch("user_#{id}_wishlists_count", expires_in: 1.hour) do
      wishlists.count
    end
  end

  def invalidate_wishlists_count_cache
    Rails.cache.delete("user_#{id}_wishlists_count")
  end
end
```

##### Option 2: Database Views
```sql
CREATE VIEW user_stats AS
SELECT
  users.id,
  COUNT(DISTINCT wishlists.id) as wishlists_count,
  COUNT(DISTINCT connections.id) as connections_count
FROM users
LEFT JOIN wishlists ON wishlists.user_id = users.id
LEFT JOIN connections ON connections.user_id = users.id AND connections.status = 1
GROUP BY users.id;
```

##### Option 3: Conditional Counter Cache (Complex)
- Only implement if other options prove insufficient
- Requires extensive error handling and data consistency checks
- Higher maintenance burden

### Performance Monitoring Triggers

Implement performance optimization when:
- **User count > 1,000** - Database queries may start showing latency
- **Dashboard load time > 2 seconds** - User experience degrades
- **Database CPU usage > 70%** - Server resources under pressure
- **Association queries appear in slow query log** - Database optimization needed

### Key Takeaways

1. **Start Simple**: Use Rails defaults until performance becomes a measurable problem
2. **Measure Before Optimizing**: Use APM tools (New Relic, DataDog) to identify actual bottlenecks
3. **Counter Cache Risks**: Can break complex queries and add debugging complexity
4. **Manual Caching**: More control and flexibility than automatic counter cache
5. **Database Design**: Good indexes and query patterns often sufficient for small-medium apps

### Files Affected
- `app/models/user.rb` - Removed counter_cache declarations
- `db/migrate/20250917223335_add_counter_caches_to_users.rb` - Migration kept for future use
- Database columns preserved for potential future implementation

### Related Documentation
- [Rails Counter Cache Guide](https://guides.rubyonrails.org/association_basics.html#counter-cache)
- [Rails Caching Guide](https://guides.rubyonrails.org/caching_with_rails.html)
- [Active Record Performance](https://guides.rubyonrails.org/active_record_querying.html#retrieving-multiple-objects-in-batches)