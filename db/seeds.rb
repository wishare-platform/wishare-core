# Development seed data for Wishare
# Creates test users, connections, wishlists, and items for testing

puts "🌱 Seeding database..."

# Check if seed data already exists
if User.exists?(email: "test@wishare.xyz") && !Rails.env.development?
  puts "✅ Seed data already exists! Skipping seeding to avoid duplicates."
  puts "🎉 Your Wishare database is ready to go!"
  exit 0
end

# Clear existing data (be careful in production!)
if Rails.env.development?
  puts "Clearing existing data..."
  # Clear in reverse dependency order to avoid foreign key violations
  AnalyticsEvent.destroy_all
  UserAnalytic.destroy_all
  Notification.destroy_all
  NotificationPreference.destroy_all
  DeviceToken.destroy_all
  WishlistItem.destroy_all
  Wishlist.destroy_all
  Invitation.destroy_all
  Connection.destroy_all
  CookieConsent.destroy_all if defined?(CookieConsent)
  JwtDenylist.destroy_all if defined?(JwtDenylist)
  User.destroy_all
  
  # Reset primary key sequences to avoid ID conflicts
  ActiveRecord::Base.connection.reset_pk_sequence!('users')
  ActiveRecord::Base.connection.reset_pk_sequence!('connections')
  ActiveRecord::Base.connection.reset_pk_sequence!('invitations')
  ActiveRecord::Base.connection.reset_pk_sequence!('wishlists')
  ActiveRecord::Base.connection.reset_pk_sequence!('wishlist_items')
  ActiveRecord::Base.connection.reset_pk_sequence!('analytics_events')
  ActiveRecord::Base.connection.reset_pk_sequence!('user_analytics')
  ActiveRecord::Base.connection.reset_pk_sequence!('notifications')
  ActiveRecord::Base.connection.reset_pk_sequence!('notification_preferences')
end

# Create main test user (representing the Instagram story author)
puts "Creating test users..."

main_user = User.find_or_create_by(email: "test@wishare.xyz") do |user|
  user.password = "SecurePassword123!"
  user.password_confirmation = "SecurePassword123!"
  user.name = "Hel Rabelo"
  user.date_of_birth = Date.new(1991, 3, 15)
  user.avatar_url = "https://api.dicebear.com/7.x/avataaars/svg?seed=helena"
  user.preferred_locale = "pt-BR"
  # Enhanced profile data for testing new features
  user.bio = "🏃‍♀️ Running enthusiast & terrible at choosing gifts (that's why I built Wishare!). Living the dream with Ylana and our 4 German Spitz overlords: Cacao (the tiny dictator), Olivia (chaos incarnate), Linda (the innocent one), and Oliver (mama's boy with attachment issues). 🐕✨"
  user.gender = "female"
  user.website = "https://helrabelo.dev"
  # Social media presence for testing
  user.instagram_username = "helrabelo"
  user.twitter_username = "helrabelo"
  user.tiktok_username = "helrabelo.dev"
  user.youtube_url = "https://https://youtube.com/@helrabelo"
  # Address - Famous address in Rio - Copacabana Palace area
  user.street_number = "1702"
  user.street_address = "Avenida Atlântica"
  user.city = "Rio de Janeiro"
  user.state = "RJ"
  user.postal_code = "22021001"
  user.country = "BR"
  user.address_visibility = :public
  user.bio_visibility = :public
  user.social_links_visibility = :connected_users
  user.website_visibility = :public
end
# Create Ylana (the partner mentioned in the stories)
ylana = User.find_or_create_by(email: "ylana@wishare.xyz") do |user|
  user.password = "PuzzleMaster2024!"
  user.password_confirmation = "PuzzleMaster2024!"
  user.name = "Ylana Moreira"
  user.date_of_birth = Date.new(1992, 8, 14)
  user.avatar_url = "https://api.dicebear.com/7.x/avataaars/svg?seed=ylana"
  user.preferred_locale = "pt-BR"
  # Enhanced profile data
  user.bio = "🧩 Puzzle collector extraordinaire with 'only' 9 puzzles (Hel exaggerates as usual 😅). Tea enthusiast, mindfulness practitioner, and professional dog whisperer to 4 adorable German Spitz. Currently accepting puzzle recommendations and denying I have a hoarding problem. 🍵✨"
  user.gender = "female"
  user.website = "https://ylana.puzzles"
  # Social media for testing variety
  user.instagram_username = "ylana.puzzles"
  user.twitter_username = "puzzleylana"
  user.youtube_url = "https://youtube.com/@puzzlesandtea"
  # Address - Famous address in São Paulo - Rua Oscar Freire (luxury shopping district)
  user.street_number = "909"
  user.street_address = "Rua Oscar Freire"
  user.city = "São Paulo"
  user.state = "SP"
  user.postal_code = "01426001"
  user.country = "BR"
  user.address_visibility = :connected_users
  user.bio_visibility = :connected_users
  user.social_links_visibility = :public
  user.website_visibility = :connected_users
end

friend2 = User.find_or_create_by(email: "friend2@wishare.xyz") do |user|
  user.password = "TechGuru2024$"
  user.password_confirmation = "TechGuru2024$"
  user.name = "Michael Chen"
  user.date_of_birth = Date.new(1988, 11, 8)
  user.avatar_url = "https://api.dicebear.com/7.x/avataaars/svg?seed=michael"
  user.preferred_locale = "en"
  # Tech professional profile
  user.bio = "🚀 Tech enthusiast, home automation nerd, and Raspberry Pi collector. Currently living the presidential life in Brasília while working remotely. Always up for discussing the latest gadgets and gizmos. Warning: May talk your ear off about smart home setups! 💻🏠"
  user.gender = "male"
  user.website = "https://michael.tech"
  # Social media focused on tech
  user.instagram_username = "michaeltech"
  user.twitter_username = "techguru_michael"
  user.youtube_url = "https://youtube.com/@michaelchentech"
  # Famous address in Brasília - Palácio da Alvorada area (presidential district)
  user.street_number = "1"
  user.street_address = "Palácio da Alvorada"
  user.city = "Brasília"
  user.state = "DF"
  user.postal_code = "70150900"
  user.country = "BR"
  user.address_visibility = :connected_users
  user.bio_visibility = :public
  user.social_links_visibility = :public
  user.website_visibility = :public
end

family1 = User.find_or_create_by(email: "family1@wishare.xyz") do |user|
  user.password = "BookLover2024#"
  user.password_confirmation = "BookLover2024#"
  user.name = "Emma Davis"
  user.date_of_birth = Date.new(1985, 9, 12)
  user.avatar_url = "https://api.dicebear.com/7.x/avataaars/svg?seed=emma"
  user.preferred_locale = "pt-BR"
  # Book lover and culture enthusiast
  user.bio = "📚 Avid reader, history buff, and proud Bahiana living in the heart of Salvador's historic center. Currently working my way through 50 books this year (33 down, 17 to go!). Love discussing literature, history, and the rich culture of Salvador. Always open to book recommendations! 🏛️📖"
  user.gender = "female"
  user.website = "https://emmareads.blog"
  # Social media focused on books and culture
  user.instagram_username = "emmareads.salvador"
  user.twitter_username = "emmalovesbooks"
  user.tiktok_username = "bookish.emma"
  # Famous address in Salvador - Pelourinho (historic center)
  user.street_number = "6"
  user.street_address = "Largo do Pelourinho"
  user.city = "Salvador"
  user.state = "BA"
  user.postal_code = "40026280"
  user.country = "BR"
  user.address_visibility = :connected_users
  user.bio_visibility = :public
  user.social_links_visibility = :connected_users
  user.website_visibility = :public
end

# Create user with pending invitation
pending_user = User.find_or_create_by(email: "pending@wishare.xyz") do |user|
  user.password = "PendingConnection123!"
  user.password_confirmation = "PendingConnection123!"
  user.name = "David Wilson"
  user.date_of_birth = Date.new(1992, 4, 30)
  user.avatar_url = "https://api.dicebear.com/7.x/avataaars/svg?seed=david"
  user.preferred_locale = "en"
  # Minimal profile for testing incomplete profiles
  user.bio = "Still figuring out this whole social media thing 🤷‍♂️"
  user.gender = "male"
  # Only partial social media presence
  user.instagram_username = "david.wilson.92"
  user.bio_visibility = :connected_users
  user.social_links_visibility = :private
end

# Create unconnected user (for public wishlist testing)
public_user = User.find_or_create_by(email: "public@wishare.xyz") do |user|
  user.password = "BeachLife2024@"
  user.password_confirmation = "BeachLife2024@"
  user.name = "Alex Thompson"
  user.date_of_birth = Date.new(1987, 12, 3)
  user.avatar_url = "https://api.dicebear.com/7.x/avataaars/svg?seed=alex"
  user.preferred_locale = "pt-BR"
  # Beach lifestyle influencer
  user.bio = "🏖️ Beach life enthusiast & wedding planner living the dream in Florianópolis. Photography hobbyist capturing the magic of Santa Catarina. Getting married soon and sharing the journey! Always planning the next beach adventure or cozy sunset moment. 📸💍"
  user.gender = "non_binary"
  user.website = "https://alexbeachlife.com"
  # Full social media presence for public profile testing
  user.instagram_username = "alexbeachlife"
  user.twitter_username = "beachalex"
  user.tiktok_username = "alex.beach.sc"
  user.youtube_url = "https://youtube.com/@alexbeachlife"
  # Famous address in Florianópolis - Jurerê Internacional (luxury beach area)
  user.street_number = "1470"
  user.street_address = "Avenida dos Búzios"
  user.city = "Florianópolis"
  user.state = "SC"
  user.postal_code = "88053700"
  user.country = "BR"
  user.address_visibility = :public
  user.bio_visibility = :public
  user.social_links_visibility = :public
  user.website_visibility = :public
end

puts "Creating connections..."

# Only create connections if they don't already exist
unless Connection.exists?(user: main_user, partner: ylana)
  Connection.create!(
    user: main_user,
    partner: ylana,
    status: :accepted
  )
end

unless Connection.exists?(user: ylana, partner: main_user)
  Connection.create!(
    user: ylana,
    partner: main_user,
    status: :accepted
  )
end

unless Connection.exists?(user: main_user, partner: friend2)
  Connection.create!(
    user: main_user,
    partner: friend2,
    status: :accepted
  )
end

unless Connection.exists?(user: friend2, partner: main_user)
  Connection.create!(
    user: friend2,
    partner: main_user,
    status: :accepted
  )
end

unless Connection.exists?(user: main_user, partner: family1)
  Connection.create!(
    user: main_user,
    partner: family1,
    status: :accepted
  )
end

unless Connection.exists?(user: family1, partner: main_user)
  Connection.create!(
    user: family1,
    partner: main_user,
    status: :accepted
  )
end

# Create pending invitation
unless Invitation.exists?(sender: main_user, recipient_email: "newuser@example.com")
  invitation = Invitation.create!(
    sender: main_user,
    recipient_email: "newuser@example.com",
    token: SecureRandom.hex(16),
    status: :pending
  )
end

# Create another pending invitation from different user
unless Invitation.exists?(sender: pending_user, recipient_email: main_user.email)
  Invitation.create!(
    sender: pending_user,
    recipient_email: main_user.email,
    token: SecureRandom.hex(16),
    status: :pending
  )
end

puts "Creating notification preferences..."

# Create notification preferences for all users
[main_user, ylana, friend2, family1, pending_user, public_user].each do |user|
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
ylana.notification_preference.update!(
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
  user: ylana,
  notification_type: :invitation_accepted,
  notifiable: Connection.where(user: ylana, partner: main_user).first,
  data: { acceptor_name: "Hel Rabelo" },
  read: true,
  created_at: 1.day.ago
)

# Skip item_purchased notification for now - will be created after items are added

puts "Creating wishlists..."

# Skip wishlist creation if main user already has wishlists
if main_user.wishlists.any?
  puts "Main user already has wishlists, skipping wishlist creation..."
  running_shoes_list = main_user.wishlists.find_by(name: "Tênis de Corrida 👟")
  birthday_list = main_user.wishlists.find_by(name: "Aniversário 2025 🎂")
  christmas_list = main_user.wishlists.find_by(name: "Natal 2025 🎄")
  public_list = main_user.wishlists.find_by(name: "Home Office Upgrade")
  private_list = main_user.wishlists.find_by(name: "Secret Project Ideas")
  fun_event_list = main_user.wishlists.find_by(name: "Sobrevivência com 4 German Spitz 🐕")
  ylana_puzzles = ylana.wishlists.find_by(name: "Quebra-cabeças 🧩")
  ylana_birthday = ylana.wishlists.find_by(name: "Aniversário Ylana 🎉")
  friend2_list = friend2.wishlists.find_by(name: "Michael's Tech Wishlist")
  family1_list = family1.wishlists.find_by(name: "Emma's Reading List")
  public_user_list = public_user.wishlists.find_by(name: "Alex's Wedding Registry")
else
  # Main user's wishlists - reflecting the Instagram story examples
  running_shoes_list = Wishlist.create!(
  user: main_user,
  name: "Tênis de Corrida 👟",
  description: "Todos os 17 pares que quero ganhar porque sou PÉSSIMA pra saber o que quero! Ylana, se você está lendo isso, pode escolher qualquer um que eu fico feliz... desde que não seja chinelo 😂",
  event_type: "none",
  is_default: true,
  visibility: :partner_only
)

birthday_list = Wishlist.create!(
  user: main_user,
  name: "Aniversário 2025 🎂",
  description: "Coisas que adoraria ganhar no meu aniversário em março! Aproveitei e já deixei uma lista pronta porque vocês sabem como sou ruim pra decidir na hora 🤷‍♀️",
  event_type: "birthday",
  event_date: Date.new(2025, 3, 15),
  is_default: false,
  visibility: :partner_only
)

christmas_list = Wishlist.create!(
  user: main_user,
  name: "Natal 2025 🎄",
  description: "Ideias de presentes para família e amigos",
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

# Fun event wishlist - German Spitz chaos management
fun_event_list = Wishlist.create!(
  user: main_user,
  name: "Sobrevivência com 4 German Spitz 🐕",
  description: "Itens para sobreviver à tirania da Cacao e ao caos da Olivia. Linda e Oliver são anjos, mas as outras duas... que Deus me ajude 😅 (Sim Ylana, você pode mostrar essa lista pra elas, elas já sabem que mandam na casa mesmo)",
  event_type: "other",
  is_default: false,
  visibility: :publicly_visible
)

# Ylana's wishlists - reflecting the Instagram story examples
ylana_puzzles = Wishlist.create!(
  user: ylana,
  name: "Quebra-cabeças 🧩",
  description: "Meus 8432 quebra-cabeças favoritos! Hel sempre exagera nos números, mas confesso que tenho uns 9... ou 10... ok, talvez mais 😅 Vocês sabem como é, não consigo resistir a um quebra-cabeça bonito!",
  event_type: "none",
  is_default: true,
  visibility: :partner_only
)

ylana_birthday = Wishlist.create!(
  user: ylana,
  name: "Aniversário Ylana 🎉",
  description: "Lista para o meu aniversário em agosto!",
  event_type: "birthday",
  event_date: Date.new(2025, 8, 14),
  is_default: false,
  visibility: :partner_only
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
end

puts "Creating wishlist items..."

# Skip item creation if wishlist items already exist
if running_shoes_list&.wishlist_items&.any?
  puts "Wishlist items already exist, skipping item creation..."
else
  # Running shoes list (Instagram story example - "todos os 17 pares que quero ganhar")
  WishlistItem.create!(
  wishlist: running_shoes_list,
  name: "Nike Alphafly Next% 3",
  description: "Para quebrar recordes pessoais (que atualmente é conseguir correr 1km sem parar pra tirar selfie 🤳)",
  url: "https://www.nike.com.br/tenis-alphafly-next-3-081573.html",
  price: 2999.99,
  currency: 'BRL',
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: running_shoes_list,
  name: "Adidas Adizero Adios Pro 4",
  description: "Tecnologia de ponta para maratonas (ou para correr atrás do Uber que passou direto 🚗💨)",
  url: "https://www.adidas.com.br/tenis-adizero-adios-pro-4/JR1094.html",
  price: 1899.99,
  currency: 'BRL',
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: running_shoes_list,
  name: "Hoka Cielo X1 2.0",
  description: "Máximo retorno de energia",
  url: "https://www.tf.com.br/tenis-unissex--hoka-cielo-x1-2-0-colorido/p",
  price: 1699.99,
  currency: 'BRL',
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: running_shoes_list,
  name: "ON Cloudboom Strike",
  description: "Inovação suíça em corrida",
  url: "https://www.on.com/pt-br/products/cloudboom-strike-3me3048/mens/white-black-shoes-3ME30480462",
  price: 1299.99,
  currency: 'BRL',
  priority: :medium,
  status: :available
)

WishlistItem.create!(
  wishlist: running_shoes_list,
  name: "Saucony Endorphin Elite",
  description: "Para competições sérias",
  url: "https://www.tf.com.br/tenis-saucony-endorphin-elite-masculino-branco-laranja/p",
  price: 1599.99,
  currency: 'BRL',
  priority: :high,
  status: :purchased
)

# More running shoes to reach the "17 pairs" mentioned in Instagram
WishlistItem.create!(
  wishlist: running_shoes_list,
  name: "Nike Vaporfly Next% 3",
  description: "O clássico dos recordes",
  url: "https://www.nike.com.br/",
  price: 2199.99,
  currency: 'BRL',
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: running_shoes_list,
  name: "Adidas Ultraboost 23",
  description: "Conforto supremo para treinos longos",
  url: "https://www.adidas.com.br/",
  price: 899.99,
  currency: 'BRL',
  priority: :medium,
  status: :available
)

WishlistItem.create!(
  wishlist: running_shoes_list,
  name: "Hoka Mach 5",
  description: "Versatilidade para todos os treinos",
  url: "https://www.tf.com.br/",
  price: 799.99,
  currency: 'BRL',
  priority: :medium,
  status: :available
)

WishlistItem.create!(
  wishlist: running_shoes_list,
  name: "New Balance SC Elite v4",
  description: "Placa de carbono para velocidade",
  url: "https://www.newbalance.com.br/",
  price: 1899.99,
  currency: 'BRL',
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: running_shoes_list,
  name: "Asics Magic Speed 3",
  description: "Perfeito para tempo runs",
  url: "https://www.asics.com.br/",
  price: 1099.99,
  currency: 'BRL',
  priority: :medium,
  status: :available
)

WishlistItem.create!(
  wishlist: running_shoes_list,
  name: "Mizuno Wave Rebellion Pro",
  description: "Inovação japonesa em running",
  url: "https://www.mizuno.com.br/",
  price: 1399.99,
  currency: 'BRL',
  priority: :medium,
  status: :available
)

WishlistItem.create!(
  wishlist: running_shoes_list,
  name: "Brooks Hyperion Elite 4",
  description: "Para corredores sérios",
  url: "https://www.brooksrunning.com.br/",
  price: 1699.99,
  currency: 'BRL',
  priority: :high,
  status: :available
)

# Birthday list items
WishlistItem.create!(
  wishlist: birthday_list,
  name: "Apple AirPods Pro (2nd Gen)",
  description: "Para o dia a dia e treinos",
  url: "https://www.apple.com/br/airpods-pro/",
  price: 2899.00,
  currency: 'BRL',
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: birthday_list,
  name: "Kindle Paperwhite Signature Edition",
  description: "Quero ler mais este ano!",
  url: "https://www.amazon.com.br/dp/B08KTZ8249",
  price: 899.99,
  currency: 'BRL',
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: birthday_list,
  name: "LEGO Architecture Estátua da Liberdade",
  description: "Adoro sets de arquitetura!",
  url: "https://www.lego.com/pt-br/product/statue-of-liberty-21042",
  price: 699.99,
  currency: 'BRL',
  priority: :medium,
  status: :available
)

WishlistItem.create!(
  wishlist: birthday_list,
  name: "Kit Moleskine Classic",
  description: "Para journaling e desenhos",
  url: "https://www.moleskine.com/pt-br/",
  price: 199.90,
  currency: 'BRL',
  priority: :low,
  status: :available
)

# Christmas list items (Brazilian pricing)
WishlistItem.create!(
  wishlist: christmas_list,
  name: "Nintendo Switch OLED",
  description: "Hora de fazer upgrade do meu Switch antigo",
  url: "https://www.nintendo.com.br/",
  price: 2499.99,
  currency: 'BRL',
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: christmas_list,
  name: "Panela Elétrica de Pressão Mondial",
  description: "Para meal prep dos domingos",
  url: "https://www.mondial.com.br/",
  price: 299.99,
  currency: 'BRL',
  priority: :medium,
  status: :available
)

WishlistItem.create!(
  wishlist: christmas_list,
  name: "Coleção de Meias Fofas",
  description: "Nunca é demais ter meias quentinhas!",
  price: 79.90,
  currency: 'BRL',
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
  currency: 'USD',
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
  currency: 'USD',
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: public_list,
  name: "Blue Yeti Microphone",
  description: "For video calls and recordings",
  url: "https://www.bluemic.com/en-us/products/yeti/",
  price: 99.99,
  currency: 'USD',
  priority: :medium,
  status: :purchased
)

# Private list items
WishlistItem.create!(
  wishlist: private_list,
  name: "Arduino Starter Kit",
  description: "Quero aprender eletrônica",
  price: 299.99,
  currency: 'BRL',
  priority: :medium,
  status: :available
)

# German Spitz survival items (chaos management)
WishlistItem.create!(
  wishlist: fun_event_list,
  name: "Livro: Como Treinar Seu Dragão (versão canina)",
  description: "Porque a Cacao literalmente é um dragão de 3kg que acha que manda na casa toda. Spoiler: ela manda mesmo 🐉",
  price: 39.90,
  currency: 'BRL',
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: fun_event_list,
  name: "Protetor Auricular Profissional",
  description: "Para quando a Cacao decide que 6h da manhã é hora perfeita para seus discursos motivacionais (aka latidos sem parar) 🔊😴",
  price: 89.99,
  currency: 'BRL',
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: fun_event_list,
  name: "Aspirador de Pó Industrial",
  description: "Porque com a Olivia espalhando pelos por toda casa, meu Roomba teve uma crise existencial e pediu demissão 🤖💔",
  price: 399.90,
  currency: 'BRL',
  priority: :medium,
  status: :available
)

WishlistItem.create!(
  wishlist: fun_event_list,
  name: "Curso de Meditação e Paciência",
  description: "Para quando a Linda faz aquela carinha de 'não entendi nada' depois que expliquei 47 vezes que não pode subir no sofá 🧘‍♂️",
  price: 197.50,
  currency: 'BRL',
  priority: :medium,
  status: :available
)

WishlistItem.create!(
  wishlist: fun_event_list,
  name: "Terapia para Oliver (Complexo de Édipo Canino)",
  description: "O menino precisa entender que a Ylana não é SÓ dele. Ele me olha com ciúme quando eu dou beijo nela 🐕💔",
  price: 250.00,
  currency: 'BRL',
  priority: :low,
  status: :available
)

# Ylana's puzzle collection (Instagram story example - "8432 quebra-cabeças") - Real Grow puzzles!
WishlistItem.create!(
  wishlist: ylana_puzzles,
  name: "Quebra-cabeça 2000 peças - Porto Colorido",
  description: "Paisagem encantadora de um porto europeu - vai ocupar a mesa da sala por uns 3 meses, mas vale a pena!",
  url: "https://www.lojagrow.com.br/quebra-cabeca-2000-pecas-porto-colorido/p",
  price: 89.90,
  currency: 'BRL',
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: ylana_puzzles,
  name: "Quebra-cabeça 2000 peças - Villaggio D'Italia",
  description: "Charme italiano em cada peça",
  url: "https://www.lojagrow.com.br/quebra-cabeca-2000-pecas-villaggio-d-italia/p",
  price: 89.90,
  currency: 'BRL',
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: ylana_puzzles,
  name: "Quebra-cabeça 2000 peças - Ateliê",
  description: "Um ateliê artístico cheio de detalhes",
  url: "https://www.lojagrow.com.br/quebra-cabeca-2000-pecas-atelie/p",
  price: 89.90,
  currency: 'BRL',
  priority: :medium,
  status: :available
)

WishlistItem.create!(
  wishlist: ylana_puzzles,
  name: "Quebra-cabeça 2000 peças - Estante de Cachorros",
  description: "Para os amantes de pets e livros! Hel já comprou esse aqui (obrigada amor! ❤️) e agora fico olhando pros pedacinhos achando que tenho cachorro de verdade 🐶",
  url: "https://www.lojagrow.com.br/quebra-cabeca-2000-pecas-estante-de-cachorros/p",
  price: 89.90,
  currency: 'BRL',
  priority: :high,
  status: :purchased
)

WishlistItem.create!(
  wishlist: ylana_puzzles,
  name: "Quebra-cabeça 2000 peças - Entardecer em Paris",
  description: "O romantismo parisiense em quebra-cabeça",
  url: "https://www.lojagrow.com.br/quebra-cabeca-2000-pecas-entardecer-em-paris/p",
  price: 89.90,
  currency: 'BRL',
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: ylana_puzzles,
  name: "Quebra-cabeça 2000 peças - Rua Americana",
  description: "Nostalgia americana dos anos 50",
  url: "https://www.lojagrow.com.br/quebra-cabeca-2000-pecas-rua-americana/p",
  price: 89.90,
  currency: 'BRL',
  priority: :medium,
  status: :available
)

WishlistItem.create!(
  wishlist: ylana_puzzles,
  name: "Quebra-cabeça 2000 peças - Vilarejo Italiano",
  description: "A beleza da Itália rural",
  url: "https://www.lojagrow.com.br/quebra---cabeca-2000-pecas-vilarejo-italiano/p",
  price: 89.90,
  currency: 'BRL',
  priority: :medium,
  status: :available
)

WishlistItem.create!(
  wishlist: ylana_puzzles,
  name: "Quebra-cabeça 2000 peças - Vilarejo das Fadas",
  description: "Um mundo mágico e encantado",
  url: "https://www.lojagrow.com.br/quebra-cabeca-2000-pecas-vilarejo-das-fadas/p",
  price: 89.90,
  currency: 'BRL',
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: ylana_puzzles,
  name: "Quebra-cabeça 2000 peças - Casa na Praia",
  description: "Tranquilidade litorânea em 2000 peças",
  url: "https://www.lojagrow.com.br/quebra-cabeca-2000-pecas-casa-na-praia/p",
  price: 89.90,
  currency: 'BRL',
  priority: :medium,
  status: :purchased
)

# Adding more puzzles to get closer to the "8432" joke
WishlistItem.create!(
  wishlist: ylana_puzzles,
  name: "Quebra-cabeça 1000 peças - Biblioteca Antiga",
  description: "Para quem ama livros e mistérios",
  url: "https://www.lojagrow.com.br/quebra-cabeca-1000-pecas-biblioteca-antiga/p",
  price: 59.90,
  currency: 'BRL',
  priority: :medium,
  status: :available
)

WishlistItem.create!(
  wishlist: ylana_puzzles,
  name: "Quebra-cabeça 3000 peças - Mapa Múndi Vintage",
  description: "Desafio máximo para exploradores!",
  url: "https://www.lojagrow.com.br/quebra-cabeca-3000-pecas-mapa-mundi-vintage/p",
  price: 139.90,
  currency: 'BRL',
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: ylana_puzzles,
  name: "Quebra-cabeça 500 peças - Jardim Secreto",
  description: "Perfeito para relaxar no fim de semana",
  url: "https://www.lojagrow.com.br/quebra-cabeca-500-pecas-jardim-secreto/p",
  price: 39.90,
  currency: 'BRL',
  priority: :low,
  status: :available
)

# Ylana's birthday items
WishlistItem.create!(
  wishlist: ylana_birthday,
  name: "Kit de Chás Premium",
  description: "Coleção de chás especiais do mundo",
  url: "https://www.tea.com.br/",
  price: 189.99,
  currency: 'BRL',
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: ylana_birthday,
  name: "Livro: O Poder do Agora",
  description: "Leitura para mindfulness",
  price: 45.90,
  currency: 'BRL',
  priority: :medium,
  status: :available
)

# Friend 2's tech items
WishlistItem.create!(
  wishlist: friend2_list,
  name: "Raspberry Pi 5",
  description: "For my home automation projects",
  url: "https://www.raspberrypi.com/products/raspberry-pi-5/",
  price: 80.00,
  currency: 'USD',
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: friend2_list,
  name: "Mechanical Keyboard - Keychron K2",
  description: "Wireless mechanical keyboard for coding",
  price: 99.00,
  currency: 'USD',
  priority: :medium,
  status: :available
)

# Family member's book items
WishlistItem.create!(
  wishlist: family1_list,
  name: "The Midnight Library by Matt Haig",
  description: "Heard great things about this book",
  price: 16.99,
  currency: 'USD',
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: family1_list,
  name: "Project Hail Mary by Andy Weir",
  description: "Love sci-fi novels!",
  price: 18.99,
  currency: 'USD',
  priority: :high,
  status: :purchased
)

WishlistItem.create!(
  wishlist: family1_list,
  name: "Book Light for Reading in Bed",
  description: "Don't want to disturb anyone",
  price: 12.99,
  currency: 'USD',
  priority: :low,
  status: :available
)

# Public user's items
WishlistItem.create!(
  wishlist: public_user_list,
  name: "Photography Course - Online",
  description: "Want to improve my photography skills",
  price: 199.00,
  currency: 'USD',
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: public_user_list,
  name: "Camera Lens - 50mm f/1.8",
  description: "For portrait photography",
  price: 125.00,
  currency: 'USD',
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

puts "Setting up admin users for testing admin panel..."

# Set main user as admin for admin panel testing
main_user.update!(role: :admin)

# Create a super admin user for testing elevated permissions
super_admin = User.find_or_create_by(email: "admin@wishare.xyz") do |user|
  user.password = "AdminSecure2024$!"
  user.password_confirmation = "AdminSecure2024$!"
  user.name = "Super Admin"
  user.avatar_url = "https://api.dicebear.com/7.x/avataaars/svg?seed=admin"
  user.preferred_locale = "en"
  user.role = :super_admin
  # Professional admin profile
  user.bio = "🛡️ Platform administrator ensuring Wishare runs smoothly for everyone. Monitoring system health, managing user reports, and continuously improving the gifting experience. Always here to help! 💻⚡"
  user.gender = "prefer_not_to_say"
  user.website = "https://wishare.xyz/admin"
  # Professional social presence
  user.twitter_username = "wishare_admin"
  user.bio_visibility = :public
  user.social_links_visibility = :connected_users
  user.website_visibility = :public
end

# Ensure the super admin has the correct role (in case user already existed)
super_admin.update!(role: :super_admin) unless super_admin.super_admin?

puts "Updating existing users with enhanced profile data..."

# Update existing users with new profile data if they already existed
if main_user.bio.blank?
  main_user.update!(
    bio: "🏃‍♀️ Running enthusiast & terrible at choosing gifts (that's why I built Wishare!). Living the dream with Ylana and our 4 German Spitz overlords: Cacao (the tiny dictator), Olivia (chaos incarnate), Linda (the innocent one), and Oliver (mama's boy with attachment issues). 🐕✨",
    gender: "female",
    website: "https://helrabelo.dev",
    instagram_username: "helrabelo",
    twitter_username: "helrabelo",
    tiktok_username: "helrabelo.dev",
    youtube_url: "https://youtube.com/@helrabelo",
    bio_visibility: :public,
    social_links_visibility: :connected_users,
    website_visibility: :public
  )
end

if ylana.bio.blank?
  ylana.update!(
    bio: "🧩 Puzzle collector extraordinaire with 'only' 9 puzzles (Hel exaggerates as usual 😅). Tea enthusiast, mindfulness practitioner, and professional dog whisperer to 4 adorable German Spitz. Currently accepting puzzle recommendations and denying I have a hoarding problem. 🍵✨",
    gender: "female",
    website: "https://ylana.puzzles",
    instagram_username: "ylana.puzzles",
    twitter_username: "puzzleylana",
    youtube_url: "https://youtube.com/@puzzlesandtea",
    bio_visibility: :connected_users,
    social_links_visibility: :public,
    website_visibility: :connected_users
  )
end

if friend2.bio.blank?
  friend2.update!(
    bio: "🚀 Tech enthusiast, home automation nerd, and Raspberry Pi collector. Currently living the presidential life in Brasília while working remotely. Always up for discussing the latest gadgets and gizmos. Warning: May talk your ear off about smart home setups! 💻🏠",
    gender: "male",
    website: "https://michael.tech",
    instagram_username: "michaeltech",
    twitter_username: "techguru_michael",
    youtube_url: "https://youtube.com/@michaelchentech",
    bio_visibility: :public,
    social_links_visibility: :public,
    website_visibility: :public
  )
end

if family1.bio.blank?
  family1.update!(
    bio: "📚 Avid reader, history buff, and proud Bahiana living in the heart of Salvador's historic center. Currently working my way through 50 books this year (33 down, 17 to go!). Love discussing literature, history, and the rich culture of Salvador. Always open to book recommendations! 🏛️📖",
    gender: "female",
    website: "https://emmareads.blog",
    instagram_username: "emmareads.salvador",
    twitter_username: "emmalovesbooks",
    tiktok_username: "bookish.emma",
    bio_visibility: :public,
    social_links_visibility: :connected_users,
    website_visibility: :public
  )
end

if pending_user.bio.blank?
  pending_user.update!(
    bio: "Still figuring out this whole social media thing 🤷‍♂️",
    gender: "male",
    instagram_username: "david.wilson.92",
    bio_visibility: :connected_users,
    social_links_visibility: :private_info
  )
end

if public_user.bio.blank?
  public_user.update!(
    bio: "🏖️ Beach life enthusiast & wedding planner living the dream in Florianópolis. Photography hobbyist capturing the magic of Santa Catarina. Getting married soon and sharing the journey! Always planning the next beach adventure or cozy sunset moment. 📸💍",
    gender: "non_binary",
    website: "https://alexbeachlife.com",
    instagram_username: "alexbeachlife",
    twitter_username: "beachalex",
    tiktok_username: "alex.beach.sc",
    youtube_url: "https://youtube.com/@alexbeachlife",
    bio_visibility: :public,
    social_links_visibility: :public,
    website_visibility: :public
  )
end

if super_admin.bio.blank?
  super_admin.update!(
    bio: "🛡️ Platform administrator ensuring Wishare runs smoothly for everyone. Monitoring system health, managing user reports, and continuously improving the gifting experience. Always here to help! 💻⚡",
    gender: "prefer_not_to_say",
    website: "https://wishare.xyz/admin",
    twitter_username: "wishare_admin",
    bio_visibility: :public,
    social_links_visibility: :connected_users,
    website_visibility: :public
  )
end

end

puts "Creating analytics events for dashboard testing..."

# Create realistic analytics events for the past 30 days
users = [main_user, ylana, friend2, family1, pending_user, public_user, super_admin]
event_types = [:page_view, :wishlist_created, :item_added, :invitation_sent, :connection_formed, 
               :item_purchased, :wishlist_shared, :login_attempt, :sign_up_attempt, 
               :invitation_accepted, :notification_clicked, :search_performed]

# Generate events over the last 30 days
30.times do |days_ago|
  date = days_ago.days.ago
  
  # More activity on recent days
  events_count = (30 - days_ago) / 3 + rand(5)
  
  events_count.times do
    user = users.sample
    event_type = event_types.sample
    
    AnalyticsEvent.create!(
      user: rand(10) > 1 ? user : nil, # 10% anonymous events
      event_type: event_type,
      session_id: SecureRandom.hex(8),
      ip_address: "192.168.1.#{rand(255)}",
      user_agent: "Mozilla/5.0 (compatible; TestSeed)",
      created_at: date + rand(24).hours,
      metadata: {
        test_data: true,
        page: "/#{['wishlists', 'dashboard', 'connections', 'profile'].sample}",
        source: "seed_data"
      }
    )
  end
end

puts "Creating user analytics data for engagement scoring..."

# Create user analytics for all users with realistic engagement data
users.each do |user|
  user_wishlists_count = user.wishlists.count
  user_items_count = user.wishlists.joins(:wishlist_items).count
  user_connections_count = user.accepted_connections.count
  
  UserAnalytic.create!(
    user: user,
    wishlists_created_count: user_wishlists_count,
    items_added_count: user_items_count,
    connections_count: user_connections_count,
    invitations_sent_count: user.sent_invitations.count,
    invitations_accepted_count: rand(3) + 1,
    items_purchased_count: rand(5),
    page_views_count: rand(100) + 50,
    first_activity_at: user.created_at,
    last_activity_at: rand(7).days.ago + rand(24).hours
  )
end

# Give main users higher engagement for realistic testing
main_user.user_analytic.update!(
  wishlists_created_count: 6,
  items_added_count: 25,
  connections_count: 3,
  invitations_sent_count: 4,
  invitations_accepted_count: 3,
  items_purchased_count: 8,
  page_views_count: 250,
  last_activity_at: 1.hour.ago
)

ylana.user_analytic.update!(
  wishlists_created_count: 2,
  items_added_count: 12,
  connections_count: 1,
  invitations_sent_count: 2,
  invitations_accepted_count: 1,
  items_purchased_count: 3,
  page_views_count: 180,
  last_activity_at: 3.hours.ago
)

puts "Creating additional notifications..."

# Add more sample notifications for better testing
Notification.create!(
  user: friend2,
  notification_type: :new_item_added,
  notifiable: WishlistItem.find_by(name: "Apple AirPods Pro (2nd Gen)"),
  data: { user_name: "Hel Rabelo", item_name: "Apple AirPods Pro (2nd Gen)" },
  read: false,
  created_at: 2.hours.ago
)

Notification.create!(
  user: family1,
  notification_type: :wishlist_shared,
  notifiable: Wishlist.find_by(name: "Natal 2025 🎄"),
  data: { sharer_name: "Hel Rabelo" },
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
puts "🎉 Welcome to Wishare - Where Being Bad at Choosing Gifts is Finally an Advantage! 🎁"
puts ""
puts "📧 Test Accounts Created (Enhanced Profile Testing Ready!):"
puts "  👑 Hel Rabelo (Main): test@wishare.xyz / SecurePassword123! - Complete profile with full social media (ADMIN, Portuguese) 👟"
puts "      Lives at: Copacabana Palace area, Rio de Janeiro + Rich bio & social presence 🌟"
puts "  🧩 Ylana Moreira (The Puzzle Queen): ylana@wishare.xyz / PuzzleMaster2024! - Puzzle enthusiast with tea obsession (Portuguese)"
puts "      Lives at: Rua Oscar Freire, São Paulo + Full social media & bio ✨"
puts "  🚀 Michael Chen: friend2@wishare.xyz / TechGuru2024$ - Tech professional with public profile (English)"
puts "      Lives at: Palácio da Alvorada, Brasília + Complete social & website 💻"
puts "  📚 Emma Davis: family1@wishare.xyz / BookLover2024# - Book lover with cultural focus (Portuguese)"
puts "      Lives at: historic Pelourinho, Salvador + Reading blog & social presence 📖"
puts "  🤷‍♂️ David Wilson: pending@wishare.xyz / PendingConnection123! - Minimal profile for testing incomplete data (English)"
puts "      Basic bio, partial social media - perfect for testing profile completion features"
puts "  🏖️ Alex Thompson: public@wishare.xyz / BeachLife2024@ - Wedding planner with fully public profile (Portuguese)"
puts "      Lives at: Jurerê Internacional beach + Full social media suite & website 📸"
puts "  🛡️ Super Admin: admin@wishare.xyz / AdminSecure2024$! - Professional admin profile (English)"
puts "      Platform administrator with professional bio & limited social presence 💻"
puts ""
puts "🎁 What We've Created (Time to Flex on Instagram!):"
puts "  - #{User.count} users living in Brazil's most exclusive addresses 🏠✨"
puts "  - #{Connection.count} connections (because networking is everything)"
puts "  - #{Invitation.count} invitations (some people are still deciding... 🤷‍♀️)"
puts "  - #{Wishlist.count} wishlists including THE LEGENDARY 17 running shoes, Ylana's 'modest' 9+ puzzle collection & the German Spitz survival guide 🧩👟🐕"
puts "  - #{WishlistItem.count} wishlist items with hilarious descriptions (some may cause laughter-induced snorting)"
puts "  - #{NotificationPreference.count} notification preferences (because we're fancy like that)"
puts "  - #{Notification.count} sample notifications (with Brazilian charm 🇧🇷)"
puts "  - #{AnalyticsEvent.count} analytics events (we see everything... EVERYTHING 👁️)"
puts "  - #{UserAnalytic.count} user analytics (stalking made professional)"
puts ""
puts "🏠 Famous Brazilian Addresses Included:"
puts "  - Copacabana Palace area (because Hel deserves luxury 👑)"
puts "  - Rua Oscar Freire luxury shopping (perfect for Ylana's puzzle addiction)"
puts "  - Palácio da Alvorada (Michael living the presidential life)"
puts "  - Historic Pelourinho (Emma keeping it cultural)"
puts "  - Jurerê Internacional beach life (Alex living the dream)"
puts ""
puts "🤣 Comedy Gold Features:"
puts "  - Sarcastic wishlist descriptions that'll make your audience laugh"
puts "  - Self-aware humor about being bad at choosing gifts"
puts "  - Brazilian cultural references and pricing (R$)"
puts "  - The legendary 'German Spitz Survival Guide' wishlist (Cacao is basically a tiny dictator 👑🐕)"
puts ""
puts "📱 Instagram Story Content Ready:"
puts "  '🎬 DEMO TIME: Login as Hel (test@wishare.xyz) to see my chaotic wishlist life'"
puts "  '🧩 Or login as Ylana (ylana@wishare.xyz) to witness the puzzle empire'"
puts "  '🔧 Admin panel at /admin shows off the technical skills (impress the nerds)'"
puts ""
# Add test URLs for metadata extraction testing
puts "Adding URL metadata extraction test items..."

# Real Brazilian e-commerce URLs for testing our extraction system
test_extraction_urls = [
  # Working URLs (extraction successful)
  {
    name: "Tênis Nike Air Zoom Alphafly Next% 3 - TF",
    url: "https://www.tf.com.br/tenis-masculino-on-cloudsurfer-max/p",
    description: "Track & Field - Extraction works perfectly with price and BRL currency",
    price: 1399.0,
    currency: 'BRL'
  },
  {
    name: "Samsung Galaxy A56 - Magazine Luiza",
    url: "https://www.magazineluiza.com.br/smartphone-samsung-galaxy-a56-128gb-5g-8gb-ram-preto-67-cam-tripla-selfie-12mp/p/240095600/te/ga56/",
    description: "Magazine Luiza - Perfect extraction with complete metadata",
    price: 2099.0,
    currency: 'BRL'
  },
  {
    name: "Whoop 5.0 Fitness Tracker - Mercado Livre",
    url: "https://produto.mercadolivre.com.br/MLB-5393424486-whoop-50-life-12-meses-de-plano-membership-incluso-_JM",
    description: "Mercado Livre - Excellent extraction with brand and pricing",
    price: 4957.26,
    currency: 'BRL'
  },
  {
    name: "Camiseta Calvin Klein - Netshoes",
    url: "https://www.netshoes.com.br/p/camiseta-calvin-klein-re-issue-masculina-N0O-2061-014",
    description: "Netshoes - Good extraction, currency fixed to BRL",
    price: 189.99,
    currency: 'BRL'
  },
  {
    name: "On Cloudboom Max Running Shoes",
    url: "https://www.on.com/en-br/products/cloudboom-max-m-3mf3031/mens/white-black-shoes-3MF30310462",
    description: "On Running BR - International brand with BRL pricing",
    price: 2099.0,
    currency: 'BRL'
  },

  # Partial success URLs (for testing improvements)
  {
    name: "Perfume Tom Ford Oud Wood - Beleza na Web",
    url: "https://www.belezanaweb.com.br/oud-wood-tom-ford-parfum-perfume-masculino-50ml/",
    description: "Beleza na Web - Gets title/image but price extraction needs work",
    price: 850.0, # Estimated
    currency: 'BRL'
  },
  {
    name: "Le Creuset Utensílios - Amazon Brasil",
    url: "https://www.amazon.com.br/CREUSET-Clássico-Utensílios-Laranja-Volcanic/dp/B07MP6T3CM",
    description: "Amazon Brasil - Title/image good, price extraction challenging",
    price: 450.0, # Estimated
    currency: 'BRL'
  },

  # Bot-protected URLs (for testing fallback strategies)
  {
    name: "Blush Dolce & Gabbana - Sephora Brasil",
    url: "https://www.sephora.com.br/blush-dolce---gabbana-cheeks-e-eyes-match-9090734147-734149.html",
    description: "Sephora Brasil - Bot protection, tests our fallback mechanisms",
    price: 280.0, # Estimated
    currency: 'BRL'
  },
  {
    name: "Bermuda On Running - Centauro",
    url: "https://www.centauro.com.br/bermuda-masculina-on-running-performance-hybrid-987684.html",
    description: "Centauro - Perfect JSON-LD schema but bot protected",
    price: 584.99,
    currency: 'BRL'
  },
  {
    name: "Smart TV LG OLED 83\" - Casas Bahia",
    url: "https://www.casasbahia.com.br/smart-tv-83-lg-oled-4k-ultra-hd-83c4psa-com-processador-ai-alpha9-ger7-webos-24-120hz-nvidia-g-sync-dolby-vision-e-atmos/p/55067720",
    description: "Casas Bahia - Major retailer, bot protection tests",
    price: 25999.0,
    currency: 'BRL'
  },
  {
    name: "Camisa Linho 100% - Zara Brasil",
    url: "https://www.zara.com/br/en/100-linen-shirt-p04334181.html",
    description: "Zara Brasil - International brand with local pricing",
    price: 199.0,
    currency: 'BRL'
  },
  {
    name: "Calça Jeans Diesel - Dafiti",
    url: "https://www.dafiti.com.br/Calca-Diesel-Jeans-Slim-Fit-2019-D-Strukt-L.32-Pantaloni-A03558-Azul-Marinho-14481621.html",
    description: "Dafiti - Fashion e-commerce testing",
    price: 899.0,
    currency: 'BRL'
  }
]

# Add these as wishlist items to the metadata testing list
metadata_test_list = Wishlist.find_or_create_by!(
  user: main_user,
  name: "🔧 URL Extraction Testing",
  description: "Real Brazilian e-commerce URLs for testing our metadata extraction system. These URLs test different scenarios: working extraction, partial success, and bot protection.",
  event_type: "none",
  is_default: false,
  visibility: :private_list
)

test_extraction_urls.each do |item_data|
  unless metadata_test_list.wishlist_items.exists?(url: item_data[:url])
    WishlistItem.create!(
      wishlist: metadata_test_list,
      name: item_data[:name],
      description: item_data[:description],
      url: item_data[:url],
      price: item_data[:price],
      currency: item_data[:currency],
      priority: :medium,
      status: :available
    )
  end
end

puts "✅ Added #{test_extraction_urls.count} URL extraction test items to private testing list"

puts "🎉 NOW GO MAKE THAT VIRAL INSTAGRAM STORY! 🚀"
puts "🎯 Your audience will love the humor, relate to the gift-giving struggles, and see your coding skills!"

puts ""
puts "🔧 URL Metadata Extraction Testing:"
puts "  - Test the extraction endpoint: POST /api/v1/wishlists/:id/items with these URLs"
puts "  - URLs include successful extractions (TF, Magazine Luiza, Mercado Livre)"
puts "  - Bot-protected sites (Sephora, Centauro) for fallback testing"
puts "  - Partial success cases (Beleza na Web, Amazon BR) for improvement testing"
