# Development seed data for Wishare
# Creates test users, connections, wishlists, and items for testing

puts "🌱 Seeding database..."

# Clear existing data (be careful in production!)
if Rails.env.development?
  puts "Clearing existing data..."
  WishlistItem.destroy_all
  Wishlist.destroy_all
  Invitation.destroy_all
  Connection.destroy_all
  User.destroy_all
  
  # Reset primary key sequences to avoid ID conflicts
  ActiveRecord::Base.connection.reset_pk_sequence!('users')
  ActiveRecord::Base.connection.reset_pk_sequence!('connections')
  ActiveRecord::Base.connection.reset_pk_sequence!('invitations')
  ActiveRecord::Base.connection.reset_pk_sequence!('wishlists')
  ActiveRecord::Base.connection.reset_pk_sequence!('wishlist_items')
end

# Create main test user
puts "Creating test users..."
main_user = User.create!(
  email: "test@wishare.xyz",
  password: "password123",
  password_confirmation: "password123",
  name: "Test User",
  date_of_birth: Date.new(1990, 3, 15),
  avatar_url: "https://api.dicebear.com/7.x/avataaars/svg?seed=test",
  preferred_locale: "en"
)

# Create connected friends/family
friend1 = User.create!(
  email: "friend1@wishare.xyz", 
  password: "password123",
  password_confirmation: "password123",
  name: "Sarah Johnson",
  date_of_birth: Date.new(1994, 6, 22),
  avatar_url: "https://api.dicebear.com/7.x/avataaars/svg?seed=sarah",
  preferred_locale: "pt-BR"
)

friend2 = User.create!(
  email: "friend2@wishare.xyz",
  password: "password123", 
  password_confirmation: "password123",
  name: "Michael Chen",
  date_of_birth: Date.new(1988, 11, 8),
  avatar_url: "https://api.dicebear.com/7.x/avataaars/svg?seed=michael",
  preferred_locale: "en"
)

family1 = User.create!(
  email: "family1@wishare.xyz",
  password: "password123",
  password_confirmation: "password123", 
  name: "Emma Davis",
  date_of_birth: Date.new(1985, 9, 12),
  avatar_url: "https://api.dicebear.com/7.x/avataaars/svg?seed=emma",
  preferred_locale: "pt-BR"
)

# Create user with pending invitation
pending_user = User.create!(
  email: "pending@wishare.xyz",
  password: "password123",
  password_confirmation: "password123",
  name: "David Wilson",
  date_of_birth: Date.new(1992, 4, 30),
  avatar_url: "https://api.dicebear.com/7.x/avataaars/svg?seed=david",
  preferred_locale: "en"
)

# Create unconnected user (for public wishlist testing)
public_user = User.create!(
  email: "public@wishare.xyz",
  password: "password123",
  password_confirmation: "password123",
  name: "Alex Thompson",
  date_of_birth: Date.new(1987, 12, 3),
  avatar_url: "https://api.dicebear.com/7.x/avataaars/svg?seed=alex",
  preferred_locale: "pt-BR"
)

puts "Creating connections..."

# Create accepted connections
Connection.create!(
  user: main_user,
  partner: friend1,
  status: :accepted
)

Connection.create!(
  user: friend1,
  partner: main_user,
  status: :accepted
)

Connection.create!(
  user: main_user,
  partner: friend2,
  status: :accepted
)

Connection.create!(
  user: friend2,
  partner: main_user,
  status: :accepted
)

Connection.create!(
  user: main_user,
  partner: family1,
  status: :accepted
)

Connection.create!(
  user: family1,
  partner: main_user,
  status: :accepted
)

# Create pending invitation
invitation = Invitation.create!(
  sender: main_user,
  recipient_email: "newuser@example.com",
  token: SecureRandom.hex(16),
  status: :pending
)

# Create another pending invitation from different user
Invitation.create!(
  sender: pending_user,
  recipient_email: main_user.email,
  token: SecureRandom.hex(16),
  status: :pending
)

puts "Creating notification preferences..."

# Create notification preferences for all users
[main_user, friend1, friend2, family1, pending_user, public_user].each do |user|
  NotificationPreference.find_or_create_by!(user: user) do |pref|
    pref.email_invitations = true
    pref.email_purchases = true
    pref.email_new_items = true
    pref.email_connections = true
    pref.push_enabled = true
    pref.digest_frequency = :daily
  end
end

# Set some users with different preferences for testing
friend1.notification_preference.update!(
  digest_frequency: :weekly,
  email_new_items: false
)

public_user.notification_preference.update!(
  digest_frequency: :instant,
  push_enabled: false
)

puts "Creating sample notifications..."

# Create some sample notifications for testing
Notification.create!(
  user: main_user,
  notification_type: :invitation_received,
  notifiable: Invitation.last,
  data: { sender_name: "David Wilson" },
  read: false
)

Notification.create!(
  user: friend1,
  notification_type: :invitation_accepted,
  notifiable: Connection.where(user: friend1, partner: main_user).first,
  data: { acceptor_name: "Test User" },
  read: true,
  created_at: 1.day.ago
)

# Skip item_purchased notification for now - will be created after items are added

puts "Creating wishlists..."

# Main user's wishlists
birthday_list = Wishlist.create!(
  user: main_user,
  name: "Birthday Wishlist 🎂",
  description: "Things I'd love for my birthday coming up in March!",
  event_type: "birthday",
  event_date: Date.new(2025, 3, 15),
  is_default: true,
  visibility: :partner_only
)

christmas_list = Wishlist.create!(
  user: main_user,
  name: "Christmas 2025 🎄",
  description: "Holiday gift ideas for family and friends",
  event_type: "christmas",
  event_date: Date.new(2025, 12, 25),
  is_default: false,
  visibility: :partner_only
)

public_list = Wishlist.create!(
  user: main_user,
  name: "Home Office Upgrade",
  description: "Items to improve my work from home setup",
  event_type: "none",
  is_default: false,
  visibility: :publicly_visible
)

private_list = Wishlist.create!(
  user: main_user,
  name: "Secret Project Ideas",
  description: "Personal project supplies - just for me",
  event_type: "none",
  is_default: false,
  visibility: :private_list
)

# Friend's wishlists
friend1_birthday = Wishlist.create!(
  user: friend1,
  name: "Sarah's Birthday List",
  description: "Turning 31 this year! 🎉",
  event_type: "birthday",
  event_date: Date.new(2025, 6, 22),
  is_default: true,
  visibility: :partner_only
)

friend1_baby = Wishlist.create!(
  user: friend1,
  name: "Baby Shower Registry",
  description: "Items for our upcoming arrival 👶",
  event_type: "baby_shower",
  event_date: Date.new(2025, 4, 15),
  is_default: false,
  visibility: :publicly_visible
)

# Friend 2's wishlist
friend2_list = Wishlist.create!(
  user: friend2,
  name: "Michael's Tech Wishlist",
  description: "Gadgets and gizmos I'm eyeing",
  event_type: "none",
  is_default: true,
  visibility: :partner_only
)

# Family member's wishlist
family1_list = Wishlist.create!(
  user: family1,
  name: "Emma's Reading List",
  description: "Books I want to read this year 📚",
  event_type: "none",
  is_default: true,
  visibility: :partner_only
)

# Public user's public wishlist (not connected)
public_user_list = Wishlist.create!(
  user: public_user,
  name: "Alex's Wedding Registry",
  description: "Items for our upcoming wedding!",
  event_type: "wedding",
  event_date: Date.new(2025, 8, 12),
  is_default: true,
  visibility: :publicly_visible
)

puts "Creating wishlist items..."

# Birthday list items
WishlistItem.create!(
  wishlist: birthday_list,
  name: "Apple AirPods Pro (2nd Gen)",
  description: "For my daily commute and workouts",
  url: "https://www.apple.com/airpods-pro/",
  price: 249.00,
  priority: :high,
  status: :available,
  image_url: "https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/MQD83?wid=1144&hei=1144"
)

WishlistItem.create!(
  wishlist: birthday_list,
  name: "Kindle Paperwhite Signature Edition",
  description: "Want to read more this year!",
  url: "https://www.amazon.com/dp/B08KTZ8249",
  price: 189.99,
  priority: :high,
  status: :available,
  image_url: "https://m.media-amazon.com/images/I/61HyrxVbsGL._AC_SX679_.jpg"
)

WishlistItem.create!(
  wishlist: birthday_list,
  name: "LEGO Architecture Statue of Liberty",
  description: "Love architecture sets!",
  url: "https://www.lego.com/en-us/product/statue-of-liberty-21042",
  price: 119.99,
  priority: :medium,
  status: :available,
  image_url: "https://www.lego.com/cdn/cs/set/assets/blt5c5b2e3f8f7c5d2a/21042.jpg"
)

WishlistItem.create!(
  wishlist: birthday_list,
  name: "Moleskine Classic Notebook Set",
  description: "For journaling and sketching",
  url: "https://www.moleskine.com/",
  price: 45.00,
  priority: :low,
  status: :available
)

# Christmas list items
WishlistItem.create!(
  wishlist: christmas_list,
  name: "Nintendo Switch OLED",
  description: "Time to upgrade from my old Switch",
  url: "https://www.nintendo.com/us/switch/oled/",
  price: 349.99,
  priority: :high,
  status: :available,
  image_url: "https://assets.nintendo.com/image/upload/f_auto/q_auto/dpr_1.5/c_scale,w_500/ncom/en_US/switch/oled-model/hero"
)

WishlistItem.create!(
  wishlist: christmas_list,
  name: "Instant Pot Duo Plus",
  description: "For meal prep Sundays",
  url: "https://www.instantpot.com/",
  price: 129.99,
  priority: :medium,
  status: :available
)

WishlistItem.create!(
  wishlist: christmas_list,
  name: "Fuzzy Socks Collection",
  description: "Can never have too many cozy socks!",
  price: 25.00,
  priority: :low,
  status: :available
)

# Home office list items
WishlistItem.create!(
  wishlist: public_list,
  name: "Herman Miller Aeron Chair",
  description: "The ultimate ergonomic office chair",
  url: "https://www.hermanmiller.com/products/seating/office-chairs/aeron-chairs/",
  price: 1795.00,
  priority: :high,
  status: :available,
  image_url: "https://www.hermanmiller.com/content/dam/hmicom/page_assets/products/aeron_chairs/mh_prd_ovw_aeron_chairs.jpg"
)

WishlistItem.create!(
  wishlist: public_list,
  name: "LG 34\" Ultrawide Monitor",
  description: "For better productivity with multiple windows",
  url: "https://www.lg.com/us/monitors",
  price: 599.99,
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: public_list,
  name: "Blue Yeti Microphone",
  description: "For video calls and recordings",
  url: "https://www.bluemic.com/en-us/products/yeti/",
  price: 99.99,
  priority: :medium,
  status: :purchased
)

# Private list items
WishlistItem.create!(
  wishlist: private_list,
  name: "Arduino Starter Kit",
  description: "Want to learn electronics",
  price: 89.99,
  priority: :medium,
  status: :available
)

# Friend 1's birthday items
WishlistItem.create!(
  wishlist: friend1_birthday,
  name: "Yoga Mat - Manduka PRO",
  description: "Need a good quality mat for daily practice",
  url: "https://www.manduka.com/",
  price: 120.00,
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: friend1_birthday,
  name: "Cookbook: Salt, Fat, Acid, Heat",
  description: "Want to improve my cooking skills",
  price: 35.00,
  priority: :medium,
  status: :available
)

# Friend 1's baby shower items
WishlistItem.create!(
  wishlist: friend1_baby,
  name: "Baby Monitor with Camera",
  description: "Peace of mind for the nursery",
  price: 199.99,
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: friend1_baby,
  name: "Diaper Bag Backpack",
  description: "Hands-free and stylish",
  price: 79.99,
  priority: :high,
  status: :purchased
)

# Friend 2's tech items
WishlistItem.create!(
  wishlist: friend2_list,
  name: "Raspberry Pi 5",
  description: "For my home automation projects",
  url: "https://www.raspberrypi.com/products/raspberry-pi-5/",
  price: 80.00,
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: friend2_list,
  name: "Mechanical Keyboard - Keychron K2",
  description: "Wireless mechanical keyboard for coding",
  price: 99.00,
  priority: :medium,
  status: :available
)

# Family member's book items
WishlistItem.create!(
  wishlist: family1_list,
  name: "The Midnight Library by Matt Haig",
  description: "Heard great things about this book",
  price: 16.99,
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: family1_list,
  name: "Project Hail Mary by Andy Weir",
  description: "Love sci-fi novels!",
  price: 18.99,
  priority: :high,
  status: :purchased
)

WishlistItem.create!(
  wishlist: family1_list,
  name: "Book Light for Reading in Bed",
  description: "Don't want to disturb anyone",
  price: 12.99,
  priority: :low,
  status: :available
)

# Public user's items
WishlistItem.create!(
  wishlist: public_user_list,
  name: "Photography Course - Online",
  description: "Want to improve my photography skills",
  price: 199.00,
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: public_user_list,
  name: "Camera Lens - 50mm f/1.8",
  description: "For portrait photography",
  price: 125.00,
  priority: :medium,
  status: :available
)

# Create item_purchased notification now that items exist
blue_yeti_item = WishlistItem.find_by(name: "Blue Yeti Microphone")
if blue_yeti_item
  Notification.create!(
    user: main_user,
    notification_type: :item_purchased,
    notifiable: blue_yeti_item,
    data: { purchaser_name: "Someone", item_name: "Blue Yeti Microphone" },
    read: false,
    created_at: 1.hour.ago
  )
end

puts "Creating additional notifications..."

# Add more sample notifications for better testing
Notification.create!(
  user: friend2,
  notification_type: :new_item_added,
  notifiable: WishlistItem.find_by(name: "Apple AirPods Pro (2nd Gen)"),
  data: { user_name: "Test User", item_name: "Apple AirPods Pro (2nd Gen)" },
  read: false,
  created_at: 2.hours.ago
)

Notification.create!(
  user: family1,
  notification_type: :wishlist_shared,
  notifiable: Wishlist.find_by(name: "Christmas 2025 🎄"),
  data: { sharer_name: "Test User" },
  read: false,
  created_at: 3.days.ago
)

# Create some read notifications for testing - use an existing user as notifiable
Notification.create!(
  user: main_user,
  notification_type: :connection_removed,
  notifiable: pending_user,
  data: { user_name: "David Wilson" },
  read: true,
  created_at: 1.week.ago
)

puts "✅ Seeding complete!"
puts ""
puts "📧 Test Accounts Created:"
puts "  Main User: test@wishare.xyz / password123 (English)"
puts "  Friend 1: friend1@wishare.xyz / password123 (Sarah - connected, Portuguese)"
puts "  Friend 2: friend2@wishare.xyz / password123 (Michael - connected, English)"
puts "  Family: family1@wishare.xyz / password123 (Emma - connected, Portuguese)"
puts "  Pending: pending@wishare.xyz / password123 (David - has sent invitation, English)"
puts "  Public: public@wishare.xyz / password123 (Alex - not connected, has public list, Portuguese)"
puts ""
puts "🎁 Created:"
puts "  - #{User.count} users with language preferences"
puts "  - #{Connection.count} connections"
puts "  - #{Invitation.count} invitations"
puts "  - #{Wishlist.count} wishlists with event types"
puts "  - #{WishlistItem.count} wishlist items"
puts "  - #{NotificationPreference.count} notification preferences"
puts "  - #{Notification.count} sample notifications"
puts ""
puts "🔔 Notification System Features:"
puts "  - Real-time in-app notifications"
puts "  - Email notification preferences (instant/daily/weekly)"
puts "  - Push notification support ready"
puts "  - Sample notifications for testing"
puts ""
puts "🌍 Internationalization Features:"
puts "  - Users have mixed English/Portuguese preferences"
puts "  - Test language switching and locale formatting"
puts "  - Date formats: EN (MM/DD/YYYY) vs PT-BR (DD/MM/YYYY)"
puts ""
puts "🚀 You can now log in with any test account to explore the app!"
