namespace :url_cache do
  desc "Display cache statistics"
  task stats: :environment do
    stats = UrlMetadataCache.statistics

    puts "\n📊 URL Metadata Cache Statistics"
    puts "=" * 60
    puts "Total Cached URLs: #{stats[:total_cached]}"
    puts "Valid Cache Entries: #{stats[:valid_cached]}"
    puts "Expired Entries: #{stats[:expired]}"
    puts "Popular Items (≥10 hits): #{stats[:popular_items]}"
    puts "\n📈 Usage Metrics"
    puts "Total Cache Hits: #{stats[:total_hits]}"
    puts "Average Hits per URL: #{stats[:avg_hits_per_url]}"
    puts "Cache Size: #{stats[:cache_size_mb]} MB"
    puts "\n🔝 Top Platforms"
    stats[:platforms].each do |platform, count|
      puts "  #{platform || 'unknown'}: #{count} URLs"
    end
    puts "\n🏆 Most Popular URLs"
    stats[:most_popular_urls].each do |url, hits|
      puts "  #{hits} hits: #{url[0..60]}#{url.length > 60 ? '...' : ''}"
    end
    puts "\n📅 Date Range"
    puts "Oldest Entry: #{stats[:oldest_entry]&.strftime('%Y-%m-%d %H:%M')}"
    puts "Newest Entry: #{stats[:newest_entry]&.strftime('%Y-%m-%d %H:%M')}"
    puts "=" * 60
  end

  desc "Clean up expired and excess cache entries"
  task cleanup: :environment do
    puts "🧹 Starting cache cleanup..."
    UrlMetadataCache.cleanup!
    puts "✅ Cache cleanup completed"
  end

  desc "Warm cache for popular expired items"
  task warm: :environment do
    puts "🔥 Warming cache for popular items..."
    count = UrlMetadataCache.popular.expired.count
    if count > 0
      puts "Found #{count} popular expired items to refresh"
      UrlMetadataCache.warm_cache_for_popular_items
      puts "✅ Cache warming jobs queued"
    else
      puts "No popular expired items found"
    end
  end

  desc "Force refresh a specific URL"
  task :refresh, [:url] => :environment do |_t, args|
    if args[:url].blank?
      puts "❌ Please provide a URL: rake url_cache:refresh[https://example.com/product]"
      exit
    end

    puts "🔄 Refreshing metadata for: #{args[:url]}"

    # Find existing cache entry
    normalized = UrlMetadataCache.normalize_url(args[:url])
    hash = UrlMetadataCache.generate_hash(normalized)
    cache = UrlMetadataCache.find_by(url_hash: hash)

    if cache
      cache.refresh!
      puts "✅ Refresh job queued for existing cache entry"
    else
      # Extract new metadata
      metadata = MasterUrlMetadataExtractor.new(args[:url], skip_methods: [:database_cached, :memory_cached]).extract
      if metadata.present?
        UrlMetadataCache.store(args[:url], metadata)
        puts "✅ New metadata extracted and cached"
        puts "Title: #{metadata[:title]}"
        puts "Price: #{metadata[:currency]} #{metadata[:price]}" if metadata[:price]
      else
        puts "❌ Failed to extract metadata"
      end
    end
  end

  desc "Clear all cache entries (use with caution)"
  task clear: :environment do
    puts "⚠️  This will delete ALL cached URL metadata!"
    print "Are you sure? (yes/no): "

    if STDIN.gets.chomp.downcase == 'yes'
      count = UrlMetadataCache.count
      UrlMetadataCache.destroy_all
      Rails.cache.delete_matched("url_metadata:*")
      puts "✅ Deleted #{count} cache entries"
    else
      puts "❌ Cancelled"
    end
  end

  desc "Export popular URLs to CSV"
  task export: :environment do
    require 'csv'

    filename = "url_cache_export_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv"

    CSV.open(filename, 'w') do |csv|
      csv << ['URL', 'Title', 'Platform', 'Hit Count', 'Last Accessed', 'Expires At']

      UrlMetadataCache.most_popular.limit(1000).find_each do |cache|
        csv << [
          cache.url,
          cache.title,
          cache.platform,
          cache.hit_count,
          cache.last_accessed_at,
          cache.expires_at
        ]
      end
    end

    puts "✅ Exported to #{filename}"
  end

  desc "Schedule periodic cache maintenance"
  task schedule: :environment do
    puts "📅 Scheduling cache maintenance tasks..."

    # This would typically integrate with whenever gem or similar
    # For now, just show what should be scheduled

    puts "Recommended cron schedule:"
    puts "0 */6 * * * rake url_cache:cleanup  # Every 6 hours"
    puts "0 2 * * * rake url_cache:warm       # Daily at 2 AM"
    puts "0 0 * * 0 rake url_cache:stats      # Weekly stats"
  end
end