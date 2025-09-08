# Wishare - Universal Gifting Platform

A thoughtful gifting platform that helps friends and family share wishlists for any occasion - birthdays, holidays, weddings, baby showers, and more. Built with Rails 8.0 and designed with a beautiful rose-pink theme.

## Features

### Core Functionality
- **User Authentication**: Email/password registration with Google OAuth support
- **Friend & Family Connections**: Send invitations and manage connections
- **Wishlist Management**: Create multiple wishlists with different visibility settings
- **Gift Items**: Add items with URLs, descriptions, prices, and priorities
- **Purchase Tracking**: Mark items as purchased (hidden from wishlist owner)
- **Public Profiles**: Share public wishlists with anyone via profile links

### Design & UX
- **Rose Pink Theme**: Modern, warm color palette suitable for all occasions
- **Responsive Design**: Mobile-first approach with Tailwind CSS
- **Card-Based UI**: Clean, intuitive interface with smooth transitions
- **Empty States**: Helpful guidance when content is missing
- **Accessibility**: WCAG-compliant color contrast and keyboard navigation

## Technology Stack

- **Ruby**: 3.2.0+
- **Rails**: 8.0+
- **Database**: PostgreSQL
- **CSS Framework**: Tailwind CSS
- **JavaScript**: Stimulus & Turbo (Hotwire)
- **Authentication**: Devise with OmniAuth
- **Email**: ActionMailer
- **Background Jobs**: ActiveJob (async adapter in development)

## Getting Started

### Prerequisites

- Ruby 3.2.0 or higher
- PostgreSQL 14+
- Node.js 18+ and Yarn
- Git

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd wishare/wishare
```

2. Install dependencies:
```bash
bundle install
yarn install
```

3. Set up environment variables:
```bash
cp .env.example .env
```

Edit `.env` and add your credentials:
```
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
```

4. Set up the database:
```bash
rails db:create
rails db:migrate
rails db:seed # Optional: loads sample data
```

5. Start the server:
```bash
rails server
```

Visit `http://localhost:3000` to see the application.

## Development

### Running Tests
```bash
# Run all tests
rails test

# Run specific test file
rails test test/models/user_test.rb

# Run system tests
rails test:system
```

### Code Style
```bash
# Run RuboCop for Ruby code
bundle exec rubocop

# Run Prettier for JavaScript/CSS
yarn prettier --check .
```

### Database Commands
```bash
# Create a new migration
rails generate migration AddFieldToModel field:type

# Run migrations
rails db:migrate

# Rollback last migration
rails db:rollback

# Reset database (drop, create, migrate, seed)
rails db:reset
```

### Debugging
- Use `binding.pry` or `debugger` in Ruby code
- Rails console: `rails console` or `rails c`
- Database console: `rails dbconsole` or `rails db`
- View logs: `tail -f log/development.log`

## Project Structure

```
wishare/
├── app/
│   ├── controllers/       # Request handling
│   ├── models/            # Business logic and data
│   ├── views/             # HTML templates
│   ├── mailers/           # Email templates
│   ├── javascript/        # Stimulus controllers
│   └── assets/            # CSS and images
├── config/
│   ├── routes.rb          # URL routing
│   ├── database.yml       # Database configuration
│   └── application.rb     # App configuration
├── db/
│   ├── migrate/           # Database migrations
│   └── schema.rb          # Database schema
├── test/                  # Test files
├── public/                # Static files
└── Gemfile               # Ruby dependencies
```

## Core Models

### User
- Authentication and profile management
- Connections with other users
- Multiple wishlists

### Connection
- Bidirectional friendship between users
- Status tracking (pending, accepted, declined)

### Wishlist
- Belongs to a user
- Visibility settings (private, friends & family, public)
- Contains multiple items

### WishlistItem
- Belongs to a wishlist
- URL metadata extraction
- Purchase tracking
- Priority levels

### Invitation
- Email-based invitation system
- Token-based acceptance flow
- Automatic connection creation

## API Documentation

The application is being prepared to serve as an API backend for a React Native mobile app.

### Authentication
- Session-based for web (Devise)
- Token-based for API (planned)

### Endpoints (Planned)
```
GET    /api/v1/wishlists
POST   /api/v1/wishlists
GET    /api/v1/wishlists/:id
PUT    /api/v1/wishlists/:id
DELETE /api/v1/wishlists/:id

GET    /api/v1/connections
POST   /api/v1/invitations
GET    /api/v1/users/:id
```

## Environment Variables

Required environment variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `GOOGLE_CLIENT_ID` | Google OAuth client ID | `xxx.apps.googleusercontent.com` |
| `GOOGLE_CLIENT_SECRET` | Google OAuth client secret | `GOCSPX-xxx` |
| `DATABASE_URL` | Production database URL | `postgresql://user:pass@host/db` |
| `RAILS_MASTER_KEY` | Rails credentials key | Auto-generated |
| `MAIL_HOST` | SMTP server host | `smtp.gmail.com` |
| `MAIL_PORT` | SMTP server port | `587` |
| `MAIL_USERNAME` | SMTP username | `your-email@gmail.com` |
| `MAIL_PASSWORD` | SMTP password | `app-specific-password` |

## Deployment

### Heroku

1. Create a new Heroku app:
```bash
heroku create your-app-name
```

2. Add PostgreSQL:
```bash
heroku addons:create heroku-postgresql:mini
```

3. Set environment variables:
```bash
heroku config:set GOOGLE_CLIENT_ID=xxx
heroku config:set GOOGLE_CLIENT_SECRET=xxx
```

4. Deploy:
```bash
git push heroku main
```

5. Run migrations:
```bash
heroku run rails db:migrate
```

### Railway

1. Install Railway CLI
2. Run `railway login`
3. Run `railway init`
4. Configure environment variables in Railway dashboard
5. Deploy with `railway up`

## Upcoming Features

### Phase 1: Notification System
- In-app notifications with ActionCable
- Email notification preferences
- Push notifications for mobile app
- Real-time updates for gift purchases

### Phase 2: Internationalization (i18n)
- Portuguese (pt-BR) support
- Language switcher
- Localized email templates
- Date/time/currency formatting

### Phase 3: React Native Mobile App
- API authentication with JWT
- Native mobile UI
- Push notifications
- Offline support

### Phase 4: Enhanced Features
- Image uploads for items (ActiveStorage)
- Advanced search and filtering
- Occasion-based theming
- Gift recommendations
- Social sharing

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Support

For issues, questions, or suggestions, please open an issue on GitHub.

## License

This project is proprietary software. All rights reserved.

## Acknowledgments

- Built with Ruby on Rails
- Styled with Tailwind CSS
- Icons from Heroicons
- Authentication by Devise