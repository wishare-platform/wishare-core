namespace :dev do
  desc "Reset development database and seed with test data"
  task reset: :environment do
    if Rails.env.development?
      puts "🔄 Resetting development database..."
      
      # Reset database (drop, create, migrate, seed)
      Rake::Task['db:reset'].invoke
      
      puts "✅ Development database reset complete!"
      puts "📧 Login with: test@wishare.xyz / password123"
    else
      puts "❌ This task can only be run in development environment"
      exit 1
    end
  end

  desc "Just seed the development database (without reset)"
  task seed: :environment do
    if Rails.env.development?
      puts "🌱 Seeding development database..."
      
      Rake::Task['db:seed'].invoke
      
      puts "✅ Development database seeded!"
      puts "📧 Login with: test@wishare.xyz / password123"
    else
      puts "❌ This task can only be run in development environment"
      exit 1
    end
  end

  desc "Quick reset for development (clears data, keeps schema)"
  task quick_reset: :environment do
    if Rails.env.development?
      puts "⚡ Quick reset - clearing data and reseeding..."
      
      # Clear existing data
      puts "Clearing existing data..."
      WishlistItem.destroy_all
      Wishlist.destroy_all
      Invitation.destroy_all
      Connection.destroy_all
      Notification.destroy_all
      User.destroy_all
      
      # Seed new data
      Rake::Task['db:seed'].invoke
      
      puts "✅ Quick reset complete!"
      puts "📧 Login with: test@wishare.xyz / password123"
    else
      puts "❌ This task can only be run in development environment"
      exit 1
    end
  end
end