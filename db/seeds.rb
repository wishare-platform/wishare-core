# Development seed data for Wishare
# Creates test users, connections, wishlists, and items for testing

puts "🌱 Seeding database..."

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
main_user = User.create!(
  email: "test@wishare.xyz",
  password: "password123",
  password_confirmation: "password123",
  name: "Hel Rabelo",
  date_of_birth: Date.new(1990, 3, 15),
  avatar_url: "https://api.dicebear.com/7.x/avataaars/svg?seed=helena",
  preferred_locale: "pt-BR"
)

# Create Ylana (the partner mentioned in the stories)
ylana = User.create!(
  email: "ylana@wishare.xyz",
  password: "password123",
  password_confirmation: "password123",
  name: "Ylana Moreira",
  date_of_birth: Date.new(1992, 8, 14),
  avatar_url: "https://api.dicebear.com/7.x/avataaars/svg?seed=ylana",
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
  partner: ylana,
  status: :accepted
)

Connection.create!(
  user: ylana,
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
[ main_user, ylana, friend2, family1, pending_user, public_user ].each do |user|
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

# Main user's wishlists - reflecting the Instagram story examples
running_shoes_list = Wishlist.create!(
  user: main_user,
  name: "Tênis de Corrida 👟",
  description: "Todos os 17 pares que quero ganhar (conforme mencionado no Instagram!)",
  event_type: "none",
  is_default: true,
  visibility: :partner_only
)

birthday_list = Wishlist.create!(
  user: main_user,
  name: "Aniversário 2025 🎂",
  description: "Coisas que adoraria ganhar no meu aniversário em março!",
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

# Fun event wishlist (as mentioned in Instagram - "até wishlists pra eventos: Natal, casamento, divórcio")
fun_event_list = Wishlist.create!(
  user: main_user,
  name: "Lista do Divórcio 😅",
  description: "Porque até isso vira evento, né? (Brincadeira!)",
  event_type: "other",
  is_default: false,
  visibility: :publicly_visible
)

# Ylana's wishlists - reflecting the Instagram story examples
ylana_puzzles = Wishlist.create!(
  user: ylana,
  name: "Quebra-cabeças 🧩",
  description: "Meus 8432 quebra-cabeças favoritos (como mencionado no Instagram!)",
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

puts "Creating wishlist items..."

# Running shoes list (Instagram story example - "todos os 17 pares que quero ganhar")
WishlistItem.create!(
  wishlist: running_shoes_list,
  name: "Nike Alphafly Next% 3",
  description: "Para quebrar recordes pessoais",
  url: "https://www.nike.com.br/tenis-alphafly-next-3-081573.html",
  price: 2999.99,
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: running_shoes_list,
  name: "Adidas Adizero Adios Pro 4",
  description: "Tecnologia de ponta para maratonas",
  url: "https://www.adidas.com.br/tenis-adizero-adios-pro-4/JR1094.html",
  price: 1899.99,
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: running_shoes_list,
  name: "Hoka Cielo X1 2.0",
  description: "Máximo retorno de energia",
  url: "https://www.tf.com.br/tenis-unissex--hoka-cielo-x1-2-0-colorido/p",
  price: 1699.99,
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: running_shoes_list,
  name: "ON Cloudboom Strike",
  description: "Inovação suíça em corrida",
  url: "https://www.on.com/pt-br/products/cloudboom-strike-3me3048/mens/white-black-shoes-3ME30480462",
  price: 1299.99,
  priority: :medium,
  status: :available
)

WishlistItem.create!(
  wishlist: running_shoes_list,
  name: "Saucony Endorphin Elite",
  description: "Para competições sérias",
  url: "https://www.tf.com.br/tenis-saucony-endorphin-elite-masculino-branco-laranja/p",
  price: 1599.99,
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
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: running_shoes_list,
  name: "Adidas Ultraboost 23",
  description: "Conforto supremo para treinos longos",
  url: "https://www.adidas.com.br/",
  price: 899.99,
  priority: :medium,
  status: :available
)

WishlistItem.create!(
  wishlist: running_shoes_list,
  name: "Hoka Mach 5",
  description: "Versatilidade para todos os treinos",
  url: "https://www.tf.com.br/",
  price: 799.99,
  priority: :medium,
  status: :available
)

WishlistItem.create!(
  wishlist: running_shoes_list,
  name: "New Balance SC Elite v4",
  description: "Placa de carbono para velocidade",
  url: "https://www.newbalance.com.br/",
  price: 1899.99,
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: running_shoes_list,
  name: "Asics Magic Speed 3",
  description: "Perfeito para tempo runs",
  url: "https://www.asics.com.br/",
  price: 1099.99,
  priority: :medium,
  status: :available
)

WishlistItem.create!(
  wishlist: running_shoes_list,
  name: "Mizuno Wave Rebellion Pro",
  description: "Inovação japonesa em running",
  url: "https://www.mizuno.com.br/",
  price: 1399.99,
  priority: :medium,
  status: :available
)

WishlistItem.create!(
  wishlist: running_shoes_list,
  name: "Brooks Hyperion Elite 4",
  description: "Para corredores sérios",
  url: "https://www.brooksrunning.com.br/",
  price: 1699.99,
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
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: birthday_list,
  name: "Kindle Paperwhite Signature Edition",
  description: "Quero ler mais este ano!",
  url: "https://www.amazon.com.br/dp/B08KTZ8249",
  price: 899.99,
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: birthday_list,
  name: "LEGO Architecture Estátua da Liberdade",
  description: "Adoro sets de arquitetura!",
  url: "https://www.lego.com/pt-br/product/statue-of-liberty-21042",
  price: 699.99,
  priority: :medium,
  status: :available
)

WishlistItem.create!(
  wishlist: birthday_list,
  name: "Kit Moleskine Classic",
  description: "Para journaling e desenhos",
  url: "https://www.moleskine.com/pt-br/",
  price: 199.90,
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
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: christmas_list,
  name: "Panela Elétrica de Pressão Mondial",
  description: "Para meal prep dos domingos",
  url: "https://www.mondial.com.br/",
  price: 299.99,
  priority: :medium,
  status: :available
)

WishlistItem.create!(
  wishlist: christmas_list,
  name: "Coleção de Meias Fofas",
  description: "Nunca é demais ter meias quentinhas!",
  price: 79.90,
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
  description: "Quero aprender eletrônica",
  price: 299.99,
  priority: :medium,
  status: :available
)

# Fun "divorce" event items (humor from Instagram story)
WishlistItem.create!(
  wishlist: fun_event_list,
  name: "Livro: Como Ser Solteiro e Feliz",
  description: "Porque informação nunca é demais! 😂",
  price: 39.90,
  priority: :low,
  status: :available
)

WishlistItem.create!(
  wishlist: fun_event_list,
  name: "Kit Spa em Casa",
  description: "Self-care é fundamental sempre",
  price: 159.99,
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: fun_event_list,
  name: "Curso Online: Culinária para Um",
  description: "Aprendendo a cozinhar porções individuais",
  price: 89.90,
  priority: :medium,
  status: :available
)

# Ylana's puzzle collection (Instagram story example - "8432 quebra-cabeças") - Real Grow puzzles!
WishlistItem.create!(
  wishlist: ylana_puzzles,
  name: "Quebra-cabeça 2000 peças - Porto Colorido",
  description: "Paisagem encantadora de um porto europeu",
  url: "https://www.lojagrow.com.br/quebra-cabeca-2000-pecas-porto-colorido/p",
  price: 89.90,
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: ylana_puzzles,
  name: "Quebra-cabeça 2000 peças - Villaggio D'Italia",
  description: "Charme italiano em cada peça",
  url: "https://www.lojagrow.com.br/quebra-cabeca-2000-pecas-villaggio-d-italia/p",
  price: 89.90,
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: ylana_puzzles,
  name: "Quebra-cabeça 2000 peças - Ateliê",
  description: "Um ateliê artístico cheio de detalhes",
  url: "https://www.lojagrow.com.br/quebra-cabeca-2000-pecas-atelie/p",
  price: 89.90,
  priority: :medium,
  status: :available
)

WishlistItem.create!(
  wishlist: ylana_puzzles,
  name: "Quebra-cabeça 2000 peças - Estante de Cachorros",
  description: "Para os amantes de pets e livros!",
  url: "https://www.lojagrow.com.br/quebra-cabeca-2000-pecas-estante-de-cachorros/p",
  price: 89.90,
  priority: :high,
  status: :purchased
)

WishlistItem.create!(
  wishlist: ylana_puzzles,
  name: "Quebra-cabeça 2000 peças - Entardecer em Paris",
  description: "O romantismo parisiense em quebra-cabeça",
  url: "https://www.lojagrow.com.br/quebra-cabeca-2000-pecas-entardecer-em-paris/p",
  price: 89.90,
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: ylana_puzzles,
  name: "Quebra-cabeça 2000 peças - Rua Americana",
  description: "Nostalgia americana dos anos 50",
  url: "https://www.lojagrow.com.br/quebra-cabeca-2000-pecas-rua-americana/p",
  price: 89.90,
  priority: :medium,
  status: :available
)

WishlistItem.create!(
  wishlist: ylana_puzzles,
  name: "Quebra-cabeça 2000 peças - Vilarejo Italiano",
  description: "A beleza da Itália rural",
  url: "https://www.lojagrow.com.br/quebra---cabeca-2000-pecas-vilarejo-italiano/p",
  price: 89.90,
  priority: :medium,
  status: :available
)

WishlistItem.create!(
  wishlist: ylana_puzzles,
  name: "Quebra-cabeça 2000 peças - Vilarejo das Fadas",
  description: "Um mundo mágico e encantado",
  url: "https://www.lojagrow.com.br/quebra-cabeca-2000-pecas-vilarejo-das-fadas/p",
  price: 89.90,
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: ylana_puzzles,
  name: "Quebra-cabeça 2000 peças - Casa na Praia",
  description: "Tranquilidade litorânea em 2000 peças",
  url: "https://www.lojagrow.com.br/quebra-cabeca-2000-pecas-casa-na-praia/p",
  price: 89.90,
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
  priority: :medium,
  status: :available
)

WishlistItem.create!(
  wishlist: ylana_puzzles,
  name: "Quebra-cabeça 3000 peças - Mapa Múndi Vintage",
  description: "Desafio máximo para exploradores!",
  url: "https://www.lojagrow.com.br/quebra-cabeca-3000-pecas-mapa-mundi-vintage/p",
  price: 139.90,
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: ylana_puzzles,
  name: "Quebra-cabeça 500 peças - Jardim Secreto",
  description: "Perfeito para relaxar no fim de semana",
  url: "https://www.lojagrow.com.br/quebra-cabeca-500-pecas-jardim-secreto/p",
  price: 39.90,
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
  priority: :high,
  status: :available
)

WishlistItem.create!(
  wishlist: ylana_birthday,
  name: "Livro: O Poder do Agora",
  description: "Leitura para mindfulness",
  price: 45.90,
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

puts "Setting up admin users for testing admin panel..."

# Set main user as admin for admin panel testing
main_user.update!(role: :admin)

# Create a super admin user for testing elevated permissions
super_admin = User.find_or_create_by(email: "admin@wishare.xyz") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.name = "Super Admin"
  user.avatar_url = "https://api.dicebear.com/7.x/avataaars/svg?seed=admin"
  user.preferred_locale = "en"
  user.role = :super_admin
end

# Ensure the super admin has the correct role (in case user already existed)
super_admin.update!(role: :super_admin) unless super_admin.super_admin?

puts "Creating analytics events for dashboard testing..."

# Create realistic analytics events for the past 30 days
users = [ main_user, ylana, friend2, family1, pending_user, public_user, super_admin ]
event_types = [ :page_view, :wishlist_created, :item_added, :invitation_sent, :connection_formed,
               :item_purchased, :wishlist_shared, :login_attempt, :sign_up_attempt,
               :invitation_accepted, :notification_clicked, :search_performed ]

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
        page: "/#{[ 'wishlists', 'dashboard', 'connections', 'profile' ].sample}",
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
puts "📧 Test Accounts Created (Instagram Demo Ready!):"
puts "  👥 Main User: test@wishare.xyz / password123 (Hel Rabelo - ADMIN, Portuguese)"
puts "  💕 Partner: ylana@wishare.xyz / password123 (Ylana Moreira - connected, Portuguese)"
puts "  🤝 Friend 2: friend2@wishare.xyz / password123 (Michael - connected, English)"
puts "  👨‍👩‍👧‍👦 Family: family1@wishare.xyz / password123 (Emma - connected, Portuguese)"
puts "  📨 Pending: pending@wishare.xyz / password123 (David - has sent invitation, English)"
puts "  🌍 Public: public@wishare.xyz / password123 (Alex - not connected, has public list, Portuguese)"
puts "  🔧 Super Admin: admin@wishare.xyz / password123 (Super Admin - full admin access, English)"
puts ""
puts "🎁 Created (Perfect for Instagram Demo + Admin Testing!):"
puts "  - #{User.count} users with language preferences (including 1 admin, 1 super admin)"
puts "  - #{Connection.count} connections"
puts "  - #{Invitation.count} invitations"
puts "  - #{Wishlist.count} wishlists with event types (including the famous 17 running shoes & 8432 puzzles!)"
puts "  - #{WishlistItem.count} wishlist items"
puts "  - #{NotificationPreference.count} notification preferences"
puts "  - #{Notification.count} sample notifications"
puts "  - #{AnalyticsEvent.count} analytics events for dashboard metrics"
puts "  - #{UserAnalytic.count} user analytics with engagement scoring"
puts ""
puts "🔔 Notification System Features:"
puts "  - Real-time in-app notifications"
puts "  - Email notification preferences (instant/daily/weekly)"
puts "  - Push notification support ready"
puts "  - Sample notifications for testing"
puts ""
puts "🌍 Internationalization Features:"
puts "  - Brazilian Portuguese content and pricing (R$)"
puts "  - Test language switching and locale formatting"
puts "  - Date formats: PT-BR (DD/MM/YYYY)"
puts ""
puts "📱 Instagram Stories Ready!"
puts "  - Login as Hel Rabelo (test@wishare.xyz) for main demo"
puts "  - Login as Ylana (ylana@wishare.xyz) to see partner perspective"
puts "  - Features the famous '17 running shoes' and '8432 puzzles' lists!"
puts "  - Brazilian content, pricing, and cultural references"
puts ""
puts "🔧 Admin Panel Testing Ready!"
puts "  - Login as Hel Rabelo (test@wishare.xyz) then visit /admin for admin dashboard"
puts "  - Login as Super Admin (admin@wishare.xyz) for full admin privileges"
puts "  - Analytics dashboard with 30 days of realistic data"
puts "  - User management with engagement scoring"
puts "  - Wishlist content management and moderation tools"
puts ""
puts "🚀 Perfect for showing off the app on Instagram! 🎥"
