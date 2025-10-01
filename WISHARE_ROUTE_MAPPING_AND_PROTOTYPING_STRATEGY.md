# Wishare Route Mapping & Prototyping Strategy

## Executive Summary
This document maps ALL Wishare routes (public + private) and provides a strategic prototyping plan using the approved Pinterest Masonry card design as the foundation for the entire app. User approved the /wishlists page design and wants to apply consistent design patterns across all routes.

## Table of Contents
1. [Complete Route Inventory](#complete-route-inventory)
2. [Design System Standards](#design-system-standards)
3. [Prioritized Prototyping Order](#prioritized-prototyping-order)
4. [Enhanced /wishlists Specifications](#enhanced-wishlists-specifications)
5. [Prototype Specifications (Top 10)](#prototype-specifications-top-10)

---

## Complete Route Inventory

### PUBLIC ROUTES (Unauthenticated)

#### Landing & Marketing
| Route | Purpose | Current Status |
|-------|---------|----------------|
| `GET /` | Landing page with value proposition | ✅ Implemented |
| `GET /:locale` | Localized landing page | ✅ Implemented |
| `GET /for/birthdays` | Birthday use case landing | ✅ Implemented |
| `GET /for/weddings` | Wedding use case landing | ✅ Implemented |
| `GET /for/holidays` | Holiday use case landing | ✅ Implemented |
| `GET /for/couples` | Couples use case landing | ✅ Implemented |
| `GET /for/families` | Families use case landing | ✅ Implemented |

#### Authentication
| Route | Purpose | Current Status |
|-------|---------|----------------|
| `GET /users/sign_in` | Login page | ✅ Devise |
| `POST /users/sign_in` | Login action | ✅ Devise |
| `GET /users/sign_up` | Registration page | ✅ Devise |
| `POST /users/sign_up` | Registration action | ✅ Devise |
| `GET /users/password/new` | Forgot password | ✅ Devise |
| `POST /users/password` | Password reset request | ✅ Devise |
| `GET /users/password/edit` | Reset password form | ✅ Devise |
| `PATCH /users/password` | Update password | ✅ Devise |
| `GET /users/auth/google_oauth2` | Google OAuth initiate | ✅ OmniAuth |
| `GET /users/auth/google_oauth2/callback` | Google OAuth callback | ✅ OmniAuth |

#### Legal & Utility
| Route | Purpose | Current Status |
|-------|---------|----------------|
| `GET /terms-of-service` | Terms of service | ✅ Implemented |
| `GET /privacy-policy` | Privacy policy | ✅ Implemented |
| `GET /cookie-preferences` | Cookie consent management | ✅ Implemented |
| `POST /cookie-consent` | Save cookie preferences | ✅ Implemented |
| `GET /invite/:token` | Public invitation accept | ✅ Implemented |

---

### PRIVATE ROUTES (Authenticated)

#### Dashboard & Home
| Route | Purpose | Current Status | Priority |
|-------|---------|----------------|----------|
| `GET /dashboard` | Main dashboard/home | ✅ Implemented | **HIGHEST** |
| `GET /dashboard/api_data` | Dashboard activity feed API | ✅ Implemented | High |

#### Wishlists (Core Feature)
| Route | Purpose | Current Status | Priority |
|-------|---------|----------------|----------|
| `GET /wishlists` | Wishlist index (masonry grid) | ✅ APPROVED DESIGN | **HIGHEST** |
| `GET /wishlists/new` | Create wishlist form | ✅ Implemented | High |
| `POST /wishlists` | Create wishlist action | ✅ Implemented | High |
| `GET /wishlists/:id` | Wishlist detail/show | ✅ Implemented | **HIGHEST** |
| `GET /wishlists/:id/edit` | Edit wishlist form | ✅ Implemented | High |
| `PATCH /wishlists/:id` | Update wishlist | ✅ Implemented | High |
| `DELETE /wishlists/:id` | Delete wishlist | ✅ Implemented | High |

#### Wishlist Items (Nested Resource)
| Route | Purpose | Current Status | Priority |
|-------|---------|----------------|----------|
| `GET /wishlists/:id/items` | Item index within wishlist | ✅ Implemented | High |
| `GET /wishlists/:id/items/new` | Add item form | ✅ Implemented | **HIGH** |
| `POST /wishlists/:id/items` | Create item | ✅ Implemented | High |
| `GET /wishlists/:id/items/:item_id` | Item detail page | ✅ Implemented | **HIGH** |
| `GET /wishlists/:id/items/:item_id/edit` | Edit item form | ✅ Implemented | Medium |
| `PATCH /wishlists/:id/items/:item_id` | Update item | ✅ Implemented | Medium |
| `DELETE /wishlists/:id/items/:item_id` | Delete item | ✅ Implemented | Medium |
| `PATCH /wishlists/:id/items/:item_id/purchase` | Mark as purchased | ✅ Implemented | High |
| `PATCH /wishlists/:id/items/:item_id/unpurchase` | Unmark purchase | ✅ Implemented | High |

#### Social & Connections
| Route | Purpose | Current Status | Priority |
|-------|---------|----------------|----------|
| `GET /connections` | Connections management | ✅ Implemented | **HIGH** |
| `GET /connections/:id` | Connection detail | ✅ Implemented | Medium |
| `PATCH /connections/:id` | Accept/decline connection | ✅ Implemented | Medium |
| `DELETE /connections/:id` | Remove connection | ✅ Implemented | Medium |
| `GET /invitations` | Invitations page | ✅ Implemented | Medium |
| `GET /invitations/new` | Send invitation form | ✅ Implemented | High |
| `POST /invitations` | Send invitation | ✅ Implemented | High |
| `DELETE /invitations/:id` | Cancel invitation | ✅ Implemented | Low |

#### Notifications
| Route | Purpose | Current Status | Priority |
|-------|---------|----------------|----------|
| `GET /notifications` | Notification center | ✅ Implemented | **HIGH** |
| `PATCH /notifications/:id/mark_as_read` | Mark single as read | ✅ Implemented | Medium |
| `PATCH /notifications/mark_all_as_read` | Mark all as read | ✅ Implemented | Medium |

#### User Profile & Settings
| Route | Purpose | Current Status | Priority |
|-------|---------|----------------|----------|
| `GET /profile` | Own profile view | ✅ Implemented | **HIGH** |
| `GET /profile/edit` | Edit profile form | ✅ Implemented | **HIGH** |
| `PATCH /profile` | Update profile | ✅ Implemented | High |
| `PATCH /profile/update_avatar` | Update profile picture | ✅ Implemented | High |
| `DELETE /profile/remove_avatar` | Remove profile picture | ✅ Implemented | Low |
| `GET /users/:id` | Public user profile | ✅ Implemented | High |
| `GET /notification_preferences` | Notification settings | ✅ Implemented | Medium |
| `PATCH /notification_preferences` | Update notification settings | ✅ Implemented | Medium |

#### Utility Endpoints
| Route | Purpose | Current Status | Priority |
|-------|---------|----------------|----------|
| `POST /wishlist_items/extract_url_metadata` | URL metadata extraction | ✅ Implemented | High |
| `POST /address_lookups/lookup` | Address API lookup | ✅ Implemented | Medium |
| `PATCH /theme` | Theme toggle (light/dark) | ✅ Implemented | Low |
| `PATCH /locale` | Language switcher | ✅ Implemented | Low |

---

### ADMIN ROUTES (Super Admin Only)

| Route | Purpose | Current Status | Priority |
|-------|---------|----------------|----------|
| `GET /admin` | Admin dashboard | ✅ Implemented | Low |
| `GET /admin/users` | User management | ✅ Implemented | Low |
| `GET /admin/users/:id` | User detail | ✅ Implemented | Low |
| `PATCH /admin/users/:id` | Update user | ✅ Implemented | Low |
| `DELETE /admin/users/:id` | Delete user | ✅ Implemented | Low |
| `GET /admin/wishlists` | Wishlist management | ✅ Implemented | Low |
| `GET /admin/wishlists/:id` | Wishlist detail | ✅ Implemented | Low |
| `DELETE /admin/wishlists/:id` | Delete wishlist | ✅ Implemented | Low |

---

### API ROUTES (Mobile App & Third-Party)

#### Authentication API
| Route | Purpose | Status |
|-------|---------|--------|
| `POST /api/v1/auth/login` | JWT login | ✅ Implemented |
| `DELETE /api/v1/auth/logout` | JWT logout | ✅ Implemented |
| `POST /api/v1/auth/refresh` | Refresh JWT token | ✅ Implemented |
| `GET /api/v1/auth/validate` | Validate JWT token | ✅ Implemented |

#### Mobile-Specific API
| Route | Purpose | Status |
|-------|---------|--------|
| `GET /api/v1/mobile/health` | Health check | ✅ Implemented |
| `GET /api/v1/mobile/config` | App configuration | ✅ Implemented |
| `GET /api/v1/mobile/feature-flags` | Feature flags | ✅ Implemented |
| `POST /api/v1/mobile/device-info` | Device registration | ✅ Implemented |
| `GET /api/v1/mobile/sync` | Data sync | ✅ Implemented |
| `POST /api/v1/mobile/track-event` | Analytics tracking | ✅ Implemented |

*Full API route listing available in CLAUDE.md - 40+ additional routes*

---

## Design System Standards

### Approved Card Pattern (Pinterest Masonry Inspiration)

Based on the approved `/wishlists` page, we've established these core patterns:

#### 1. Card Architecture

```html
<!-- Standard Wishare Card -->
<div class="card-enhanced bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm rounded-3xl
            border border-rose-100 dark:border-gray-700
            hover:border-rose-200 dark:hover:border-gray-600
            overflow-hidden group transition-all duration-300
            hover:shadow-xl hover:scale-[1.02]">

  <!-- Optional Cover Image -->
  <div class="h-32 sm:h-40 overflow-hidden">
    <img class="w-full h-full object-cover" />
  </div>

  <!-- Card Content -->
  <div class="p-4 sm:p-6">
    <!-- Header with Icon/Emoji -->
    <h3 class="heading-card text-gray-800 dark:text-gray-100 flex items-center gap-2">
      <span class="transform group-hover:scale-110 transition-transform">🎁</span>
      <span>Card Title</span>
    </h3>

    <!-- Description -->
    <p class="text-gray-600 dark:text-gray-400 text-sm mb-4">
      Card description with truncation...
    </p>

    <!-- Stats/Metadata -->
    <div class="flex items-center gap-4 text-sm text-gray-500 dark:text-gray-400 mb-4">
      <div class="flex items-center gap-1">
        <svg><!-- icon --></svg>
        <span>Metadata</span>
      </div>
    </div>

    <!-- Actions -->
    <div class="flex gap-2">
      <button class="btn-enhanced flex-1 bg-gradient-to-r from-rose-500 to-rose-600
                     text-white px-3 py-2 rounded-xl">
        Primary Action
      </button>
    </div>
  </div>
</div>
```

#### 2. Color System (Purple/Pink/Rose Gradients)

```css
/* Primary Colors */
--rose-primary: from-rose-500 to-rose-600      /* Main CTAs */
--purple-accent: from-purple-500 to-purple-600  /* Friend content */
--pink-gradient: from-pink-500 to-pink-600      /* Social features */
--amber-warning: from-amber-500 to-orange-600   /* Events/dates */
--green-success: from-green-500 to-green-600    /* Public content */

/* Background Patterns */
bg-white/90 dark:bg-gray-800/90                 /* Card backgrounds */
bg-gradient-to-br from-rose-50 to-amber-50      /* Empty states */
backdrop-blur-sm                                 /* Glass morphism */

/* Borders */
border-rose-100 dark:border-gray-700            /* Default borders */
hover:border-rose-200 dark:hover:border-gray-600 /* Hover state */
border-2 border-dashed                           /* Empty states */
```

#### 3. Typography Standards

```css
/* Headings */
.heading-page      /* Playfair Display, text-3xl sm:text-4xl font-bold */
.heading-section   /* Playfair Display, text-2xl font-bold */
.heading-card      /* Playfair Display, text-xl font-semibold */
.heading-sub       /* Inter, text-lg font-semibold */

/* Body Text */
.text-body         /* Inter, text-base (16px) */
.text-body-sm      /* Inter, text-sm (14px) */
.text-body-xs      /* Inter, text-xs (12px) */
```

#### 4. Spacing System (Tailwind Standard)

```css
/* Component Spacing */
p-4 sm:p-6         /* Card padding (mobile/desktop) */
gap-2              /* Small gaps (8px) */
gap-4              /* Medium gaps (16px) */
gap-6              /* Large gaps (24px) */
space-y-4          /* Vertical stack spacing */
mb-4, mb-6, mb-8   /* Margin bottom variations */

/* Page Padding */
px-4 sm:px-6 lg:px-8  /* Responsive horizontal padding */
py-4 lg:py-8          /* Responsive vertical padding */
```

#### 5. Animation Patterns

```css
/* Micro-interactions */
transition-all duration-300              /* Standard transition */
hover:scale-[1.02]                       /* Subtle card lift */
transform group-hover:scale-110          /* Icon/emoji scale */
animate-bounce                           /* Attention grabber */
animate-pulse                            /* Loading states */

/* Stagger Animations (Stimulus) */
data-animation-foundation-stagger-delay-value="100"  /* 100ms stagger */
```

#### 6. Interactive Elements

```css
/* Buttons */
.btn-primary       /* Gradient background, rounded-xl, shadow-lg */
.btn-secondary     /* Border + bg-white, rounded-xl */
.btn-enhanced      /* Additional hover effects + haptics */

/* Hover Effects */
hover:shadow-xl                   /* Depth on hover */
hover:from-rose-600              /* Gradient shift */
group-hover:opacity-100          /* Reveal on hover */
```

#### 7. Badge & Status Indicators

```css
/* Event Type Badges */
bg-gradient-to-r from-amber-50 to-orange-50     /* Event highlight */
border border-amber-200                          /* Event border */
text-amber-700                                   /* Event text */

/* Visibility Badges */
bg-green-100 text-green-700     /* Public */
bg-blue-100 text-blue-700       /* Friends only */
bg-gray-100 text-gray-700       /* Private */
bg-rose-100 text-rose-700       /* Default */
```

#### 8. Empty States

```css
/* Empty State Container */
bg-gradient-to-br from-rose-50 to-amber-50 dark:from-rose-900/20
rounded-3xl border-2 border-dashed border-rose-200
p-12 text-center

/* Empty State Icon Container */
bg-white/80 dark:bg-gray-800/80 backdrop-blur-sm
rounded-full w-16 h-16 mx-auto mb-4
flex items-center justify-center shadow-lg
```

#### 9. Mobile Optimization

```css
/* Responsive Grid */
grid grid-cols-1 lg:grid-cols-2 gap-4 sm:gap-6

/* Mobile-First Typography */
text-base sm:text-lg lg:text-xl

/* Touch Targets */
min-h-[44px]  /* iOS minimum tap target */
px-4 py-3     /* Adequate touch padding */

/* Mobile Navigation */
fixed bottom-0 left-0 right-0    /* Bottom nav bar */
safe-area-inset-bottom           /* iOS notch handling */
```

#### 10. Dark Mode Patterns

```css
/* Text Colors */
text-gray-800 dark:text-gray-100     /* Headings */
text-gray-600 dark:text-gray-400     /* Body text */
text-gray-500 dark:text-gray-500     /* Metadata */

/* Backgrounds */
bg-white dark:bg-gray-800           /* Surfaces */
bg-gray-50 dark:bg-gray-900         /* Page backgrounds */
bg-gray-100 dark:bg-gray-700        /* Secondary surfaces */

/* Borders */
border-gray-200 dark:border-gray-700   /* Standard */
border-rose-100 dark:border-gray-700   /* Accent borders */
```

---

## Prioritized Prototyping Order

### Phase 1: Core User Journeys (Weeks 1-2)
*Most critical for daily use - should prototype first*

1. **Dashboard (/dashboard)** - Priority: CRITICAL
   - Main landing after login
   - Activity feed with social updates
   - Quick actions for common tasks
   - Mobile-first with pull-to-refresh

2. **Wishlist Detail (/wishlists/:id)** - Priority: CRITICAL
   - Item display (masonry grid)
   - Add/edit/delete items
   - Purchase tracking
   - Share functionality

3. **Add/Edit Item Form (/wishlists/:id/items/new)** - Priority: HIGH
   - URL metadata extraction
   - Image upload/preview
   - Price and currency
   - Purchase status

4. **Item Detail Page (/wishlists/:id/items/:item_id)** - Priority: HIGH
   - Full item information
   - Purchase celebration animations
   - Social sharing
   - Stats (views, hearts, popularity)

5. **Profile View (/profile)** - Priority: HIGH
   - User information display
   - Wishlist showcase
   - Social media links
   - Profile strength indicator

### Phase 2: Social Features (Week 3)
*Important for engagement and virality*

6. **Connections Page (/connections)** - Priority: HIGH
   - Friend list with search
   - Pending invitations
   - Connection management
   - Friend wishlists preview

7. **Send Invitation (/invitations/new)** - Priority: HIGH
   - Email/link invitation
   - Social sharing
   - Connection context
   - Success celebration

8. **User Profile (/users/:id)** - Priority: MEDIUM
   - Public profile view
   - Wishlist browsing
   - Connection status
   - Social links

9. **Notifications Center (/notifications)** - Priority: MEDIUM
   - Real-time notifications
   - Activity updates
   - Mark as read
   - Notification filters

### Phase 3: Settings & Management (Week 4)
*Essential for personalization but lower urgency*

10. **Profile Edit (/profile/edit)** - Priority: MEDIUM
    - Collapsible sections (already implemented)
    - Avatar upload
    - Social media fields
    - Privacy settings

11. **Create Wishlist (/wishlists/new)** - Priority: MEDIUM
    - Event type selection
    - Visibility settings
    - Cover image upload
    - Description and details

12. **Edit Wishlist (/wishlists/:id/edit)** - Priority: MEDIUM
    - Same as create but with existing data
    - Delete confirmation
    - Visibility changes
    - Event date updates

13. **Notification Preferences (/notification_preferences)** - Priority: LOW
    - Email preferences
    - Push notification settings
    - Activity notifications
    - Connection updates

### Phase 4: Public Routes (Week 5)
*Marketing and conversion focused*

14. **Landing Page (/)** - Priority: MEDIUM
    - Hero section
    - Feature showcase
    - Social proof
    - CTA to sign up

15. **Use Case Pages (/for/*)** - Priority: LOW
    - Birthdays, weddings, holidays
    - Event-specific messaging
    - Templates/examples
    - Conversion CTAs

16. **Sign Up/Sign In** - Priority: MEDIUM
    - Registration form
    - Google OAuth
    - Password reset
    - Welcome flow

### Phase 5: Edge Cases & Admin (Week 6)
*Low priority but needed for completeness*

17. **Legal Pages** - Priority: LOW
    - Terms of Service
    - Privacy Policy
    - Cookie Consent

18. **Admin Dashboard** - Priority: LOW
    - User management
    - Wishlist moderation
    - Analytics overview

19. **404/Error Pages** - Priority: LOW
    - Custom 404 page
    - Error states
    - Recovery options

20. **Mobile Web Optimizations** - Priority: MEDIUM
    - PWA enhancements
    - Offline support
    - Touch gestures
    - Bottom navigation

---

## Enhanced /wishlists Specifications

### Current Implementation Analysis
The current `/wishlists` page has:
- ✅ Animated emoji title (🎁)
- ✅ Create wishlist button with hover effects
- ✅ Filter buttons (My Wishlists, Friends & Family, Public, All)
- ✅ Sort dropdown (Newest, Oldest, Recently Updated, Name A-Z, Name Z-A)
- ✅ Pinterest-inspired masonry grid
- ✅ Card hover effects and animations
- ✅ Item preview thumbnails (3 recent items)
- ✅ Event type badges with countdown
- ✅ Visibility indicators
- ✅ Three-dot menu for actions
- ✅ Empty states for each filter

### Missing Header/Actions Elements

Based on modern wishlist apps and social platforms, here's what should be added:

#### 1. Search Bar (HIGH PRIORITY)
```html
<div class="flex-1 max-w-md">
  <div class="relative">
    <input type="text"
           placeholder="Search wishlists..."
           class="w-full bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700
                  rounded-xl px-4 py-2 pl-10 focus:ring-2 focus:ring-rose-500">
    <svg class="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400">
      <!-- Search icon -->
    </svg>
  </div>
</div>
```

**Features:**
- Real-time search with debounce
- Search by wishlist name, description, event type
- Clear button when text is entered
- Mobile-optimized with proper focus states

#### 2. View Toggle (Grid/List) (MEDIUM PRIORITY)
```html
<div class="flex bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700">
  <button data-view="grid" class="px-3 py-2 rounded-l-xl bg-rose-50 text-rose-600">
    <svg><!-- Grid icon --></svg>
  </button>
  <button data-view="list" class="px-3 py-2 rounded-r-xl text-gray-600">
    <svg><!-- List icon --></svg>
  </button>
</div>
```

**Views:**
- Grid view (current Pinterest masonry - default)
- List view (compact rows with less visual weight)
- Preference saved to localStorage

#### 3. Bulk Actions (LOW PRIORITY - Future)
```html
<div class="flex items-center gap-2" data-bulk-actions>
  <input type="checkbox" class="rounded border-gray-300" />
  <span class="text-sm text-gray-600">Select All</span>
  <button class="text-sm text-rose-600 hidden" data-bulk-action="delete">
    Delete Selected
  </button>
</div>
```

**Actions when wishlists are selected:**
- Delete multiple wishlists
- Change visibility in bulk
- Export selected wishlists

#### 4. User Info Badge (MEDIUM PRIORITY)
```html
<div class="flex items-center gap-2 bg-white dark:bg-gray-800 rounded-xl px-3 py-2 border border-gray-200">
  <img src="avatar" class="w-8 h-8 rounded-full" />
  <div class="hidden sm:block">
    <p class="text-sm font-medium text-gray-800 dark:text-gray-100">Hel Rabelo</p>
    <p class="text-xs text-gray-500">12 wishlists</p>
  </div>
</div>
```

**Shows:**
- User avatar
- Total wishlist count
- Optional: Quick profile link

#### 5. Achievement/Stats Banner (LOW PRIORITY - Gamification)
```html
<div class="bg-gradient-to-r from-amber-50 to-rose-50 rounded-xl p-3 mb-4">
  <div class="flex items-center justify-between">
    <div class="flex items-center gap-2">
      <span class="text-2xl">🎉</span>
      <p class="text-sm font-medium text-gray-800">
        <strong>Achievement Unlocked!</strong> Created 5 wishlists
      </p>
    </div>
    <button class="text-gray-400 hover:text-gray-600">
      <svg><!-- X icon --></svg>
    </button>
  </div>
</div>
```

**Achievements:**
- First Wish (created 1 wishlist)
- Wish Collector (5 wishlists)
- Birthday Planner (created birthday wishlist)
- Wishlist Explorer (viewed 10+ friend wishlists)

### Proposed Enhanced Header Structure

```html
<div class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4 mb-8">
  <!-- Left Side: Title + Search -->
  <div class="flex-1">
    <div class="flex items-center gap-3 mb-3">
      <h1 class="heading-page text-gray-800 dark:text-gray-100 flex items-center gap-3">
        <span class="text-4xl animate-bounce">🎁</span>
        Your Wishlists
      </h1>
      <span class="bg-rose-100 text-rose-700 text-sm px-3 py-1 rounded-full">
        12 total
      </span>
    </div>

    <!-- Search Bar (Mobile: full width, Desktop: max-w-md) -->
    <div class="relative max-w-md">
      <input type="text"
             placeholder="Search wishlists..."
             data-action="input->wishlist-filter#search"
             class="w-full bg-white dark:bg-gray-800 border border-gray-200
                    dark:border-gray-700 rounded-xl px-4 py-2 pl-10">
      <svg class="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400">
        <!-- Search icon -->
      </svg>
    </div>
  </div>

  <!-- Right Side: Actions -->
  <div class="flex items-center gap-3">
    <!-- View Toggle -->
    <div class="hidden sm:flex bg-white dark:bg-gray-800 rounded-xl border border-gray-200">
      <button data-view="grid"
              class="px-3 py-2 rounded-l-xl bg-rose-50 text-rose-600">
        <svg><!-- Grid icon --></svg>
      </button>
      <button data-view="list"
              class="px-3 py-2 rounded-r-xl text-gray-600">
        <svg><!-- List icon --></svg>
      </button>
    </div>

    <!-- Create Wishlist Button (existing) -->
    <a href="/wishlists/new"
       class="btn-primary bg-gradient-to-r from-rose-500 to-rose-600
              text-white px-4 py-2 rounded-xl hover:shadow-xl">
      <svg><!-- Plus icon --></svg>
      <span class="hidden xs:inline">New Wishlist</span>
    </a>
  </div>
</div>

<!-- Filter Bar (existing but moved below header) -->
<div class="flex flex-wrap gap-2 mb-6">
  <!-- Existing filter buttons -->
</div>

<!-- Sort Dropdown (existing but refined position) -->
<div class="flex justify-end mb-6">
  <!-- Existing sort dropdown -->
</div>
```

### Mobile Considerations for Header

```html
<!-- Mobile: Stacked layout -->
<div class="lg:hidden space-y-4 mb-6">
  <!-- Title + Count -->
  <div class="flex items-center justify-between">
    <h1 class="heading-page flex items-center gap-2">
      <span class="text-3xl">🎁</span>
      Wishlists
    </h1>
    <span class="bg-rose-100 text-rose-700 text-sm px-3 py-1 rounded-full">12</span>
  </div>

  <!-- Search Bar (full width) -->
  <div class="relative">
    <input type="text" placeholder="Search..." class="w-full ..." />
  </div>

  <!-- Create Button (full width) -->
  <a href="/wishlists/new" class="btn-primary w-full justify-center">
    New Wishlist
  </a>
</div>
```

---

## Prototype Specifications (Top 10)

### 1. DASHBOARD (/dashboard)

**Purpose:** Main landing page after login - activity feed + quick actions

**Layout Structure:**
```
Desktop (1440px):
├─ Left Sidebar (40%)
│  ├─ Profile Card (avatar, stats, progress)
│  ├─ Quick Actions (4 buttons grid)
│  ├─ Upcoming Events (3 cards max)
│  └─ Friends List (5 friends + see all)
│
└─ Main Feed (60%)
   ├─ Feed Header (filters: For You, Friends, Following, All)
   ├─ Activity Stream (infinite scroll)
   └─ Pull-to-Refresh

Mobile (375px):
├─ Profile Summary (collapsed)
├─ Quick Actions (2x2 grid)
├─ Activity Feed (full width)
└─ Collapsible Events + Friends
```

**Key Components:**
- **Profile Card:**
  ```html
  <div class="card-enhanced bg-gradient-to-br from-rose-50 to-pink-50 p-6">
    <div class="flex items-center gap-4 mb-4">
      <img src="avatar" class="w-16 h-16 rounded-full border-4 border-white shadow-lg" />
      <div>
        <h2 class="heading-card">Welcome back, Hel!</h2>
        <p class="text-sm text-gray-600">12 wishlists • 24 friends</p>
      </div>
    </div>

    <!-- Profile Completion Progress -->
    <div class="mb-4">
      <div class="flex justify-between mb-1">
        <span class="text-sm font-medium">Profile Strength</span>
        <span class="text-sm text-gray-600">85%</span>
      </div>
      <div class="w-full bg-gray-200 rounded-full h-2">
        <div class="bg-gradient-to-r from-rose-500 to-pink-500 h-2 rounded-full"
             style="width: 85%"></div>
      </div>
    </div>

    <!-- Quick Stats (clickable) -->
    <div class="grid grid-cols-3 gap-3">
      <div class="stat-card bg-white rounded-xl p-3 text-center cursor-pointer
                  hover:shadow-lg transition-all"
           data-action="click->dashboard-delight#celebrateViews">
        <p class="text-2xl font-bold text-rose-600">243</p>
        <p class="text-xs text-gray-600">Profile Views</p>
      </div>
      <div class="stat-card bg-white rounded-xl p-3 text-center cursor-pointer">
        <p class="text-2xl font-bold text-purple-600">18</p>
        <p class="text-xs text-gray-600">Items Bought</p>
      </div>
      <div class="stat-card bg-white rounded-xl p-3 text-center cursor-pointer">
        <p class="text-2xl font-bold text-amber-600">5</p>
        <p class="text-xs text-gray-600">Events Soon</p>
      </div>
    </div>
  </div>
  ```

- **Quick Actions Grid:**
  ```html
  <div class="grid grid-cols-2 gap-3"
       data-dashboard-delight-target="quickActions">

    <!-- Create Wishlist -->
    <button class="action-card bg-gradient-to-br from-rose-400 to-rose-600
                   text-white rounded-2xl p-4 text-left
                   hover:scale-105 transition-transform"
            data-action="click->dashboard-delight#celebrateCreate">
      <svg class="w-8 h-8 mb-2"><!-- Gift icon --></svg>
      <p class="font-semibold">Create Wishlist</p>
      <p class="text-xs opacity-90">Start a new list</p>
    </button>

    <!-- Invite Friend -->
    <button class="action-card bg-gradient-to-br from-purple-400 to-purple-600
                   text-white rounded-2xl p-4 text-left">
      <svg class="w-8 h-8 mb-2"><!-- User Plus icon --></svg>
      <p class="font-semibold">Invite Friend</p>
      <p class="text-xs opacity-90">Share wishlists</p>
    </button>

    <!-- Discover -->
    <button class="action-card bg-gradient-to-br from-amber-400 to-orange-600
                   text-white rounded-2xl p-4 text-left">
      <svg class="w-8 h-8 mb-2"><!-- Compass icon --></svg>
      <p class="font-semibold">Discover</p>
      <p class="text-xs opacity-90">Explore wishlists</p>
    </button>

    <!-- Edit Profile -->
    <button class="action-card bg-gradient-to-br from-pink-400 to-pink-600
                   text-white rounded-2xl p-4 text-left">
      <svg class="w-8 h-8 mb-2"><!-- User icon --></svg>
      <p class="font-semibold">Edit Profile</p>
      <p class="text-xs opacity-90">Update settings</p>
    </button>
  </div>
  ```

- **Activity Feed Item:**
  ```html
  <div class="activity-item bg-white dark:bg-gray-800 rounded-2xl p-4 mb-3
              border border-gray-100 dark:border-gray-700
              hover:shadow-lg transition-all">
    <div class="flex gap-3">
      <!-- Avatar -->
      <img src="friend-avatar" class="w-10 h-10 rounded-full flex-shrink-0" />

      <!-- Content -->
      <div class="flex-1 min-w-0">
        <p class="text-sm text-gray-800 dark:text-gray-100 mb-1">
          <strong>Sarah Martinez</strong> added 3 items to
          <a href="#" class="text-rose-600 hover:underline">Birthday 2025</a>
        </p>
        <p class="text-xs text-gray-500">2 hours ago</p>

        <!-- Preview Images if applicable -->
        <div class="flex gap-2 mt-2">
          <img src="item1" class="w-16 h-16 rounded-lg object-cover" />
          <img src="item2" class="w-16 h-16 rounded-lg object-cover" />
          <div class="w-16 h-16 rounded-lg bg-gray-100 flex items-center justify-center">
            <span class="text-sm text-gray-600">+1</span>
          </div>
        </div>
      </div>

      <!-- Action Buttons -->
      <div class="flex flex-col gap-2">
        <button class="text-rose-500 hover:bg-rose-50 p-2 rounded-lg">
          <svg class="w-5 h-5"><!-- Heart icon --></svg>
        </button>
      </div>
    </div>
  </div>
  ```

**Interactive Elements:**
- Pull-to-refresh on mobile
- Infinite scroll for activity feed
- Clickable stat cards with celebrations
- Quick action animations (sparkles, confetti)
- Feed filters with smooth transitions
- Friend milestone celebrations

**Mobile Optimization:**
- Bottom navigation bar (Home, Wishlists, Friends, Profile)
- Collapsible sections (Events, Friends)
- Swipe gestures for actions
- Thumb-reach optimized buttons

**Unique Features:**
- Personalized welcome message (time-based: "Good morning, Hel!")
- Achievement notifications (profile milestones)
- Friend activity highlights (3+ friends = celebration)
- Event countdown badges
- Real-time activity updates (ActionCable)

---

### 2. WISHLIST DETAIL (/wishlists/:id)

**Purpose:** Show all items in a wishlist + manage items + purchase tracking

**Layout Structure:**
```
Desktop (1440px):
├─ Wishlist Header (cover image, title, description)
├─ Action Bar (Add Item, Share, Edit, Settings)
├─ Item Grid (Pinterest masonry - 3-4 columns)
└─ Stats Sidebar (progress, stats, purchases)

Mobile (375px):
├─ Cover Image (full width)
├─ Sticky Header (title + actions)
├─ Item Grid (2 columns masonry)
└─ Floating Add Button
```

**Key Components:**
- **Wishlist Header:**
  ```html
  <!-- Cover Image with Gradient Overlay -->
  <div class="relative h-64 overflow-hidden rounded-b-3xl">
    <img src="cover" class="w-full h-full object-cover" />
    <div class="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent"></div>

    <!-- Wishlist Info (overlaid) -->
    <div class="absolute bottom-0 left-0 right-0 p-6 text-white">
      <div class="flex items-center gap-2 mb-2">
        <span class="text-3xl">🎂</span>
        <span class="bg-white/20 backdrop-blur-sm px-3 py-1 rounded-full text-sm">
          Birthday
        </span>
        <span class="bg-rose-500/90 px-3 py-1 rounded-full text-sm font-semibold">
          15 days left
        </span>
      </div>

      <h1 class="heading-page text-white mb-2">Hel's 30th Birthday</h1>
      <p class="text-sm text-white/90">
        Celebrating three decades of awesome! 🎉
      </p>

      <!-- Stats Row -->
      <div class="flex items-center gap-6 mt-4 text-sm">
        <div class="flex items-center gap-1">
          <svg class="w-4 h-4"><!-- Tag icon --></svg>
          <span>24 items</span>
        </div>
        <div class="flex items-center gap-1">
          <svg class="w-4 h-4"><!-- Check icon --></svg>
          <span>8 purchased</span>
        </div>
        <div class="flex items-center gap-1">
          <svg class="w-4 h-4"><!-- Eye icon --></svg>
          <span>142 views</span>
        </div>
      </div>
    </div>
  </div>
  ```

- **Action Bar:**
  ```html
  <div class="sticky top-0 z-10 bg-white/95 dark:bg-gray-900/95 backdrop-blur-sm
              border-b border-gray-200 dark:border-gray-700 px-4 py-3
              flex items-center justify-between gap-3">

    <!-- Left: Primary Actions -->
    <div class="flex items-center gap-2">
      <a href="/wishlists/:id/items/new"
         class="btn-primary bg-gradient-to-r from-rose-500 to-rose-600
                text-white px-4 py-2 rounded-xl flex items-center gap-2">
        <svg class="w-4 h-4"><!-- Plus icon --></svg>
        <span>Add Item</span>
      </a>

      <button class="btn-secondary bg-white dark:bg-gray-800 border border-gray-200
                     px-4 py-2 rounded-xl flex items-center gap-2"
              data-action="click->item-delight#shareWishlist">
        <svg class="w-4 h-4"><!-- Share icon --></svg>
        <span class="hidden sm:inline">Share</span>
      </button>
    </div>

    <!-- Right: Secondary Actions -->
    <div class="flex items-center gap-2">
      <!-- Filter/Sort -->
      <div class="relative" data-controller="dropdown">
        <button class="text-gray-600 dark:text-gray-400 hover:bg-gray-100
                       p-2 rounded-lg">
          <svg class="w-5 h-5"><!-- Filter icon --></svg>
        </button>
        <!-- Dropdown menu -->
      </div>

      <!-- Settings/Edit -->
      <a href="/wishlists/:id/edit"
         class="text-gray-600 dark:text-gray-400 hover:bg-gray-100 p-2 rounded-lg">
        <svg class="w-5 h-5"><!-- Settings icon --></svg>
      </a>
    </div>
  </div>
  ```

- **Item Card (Masonry):**
  ```html
  <div class="item-card bg-white dark:bg-gray-800 rounded-2xl overflow-hidden
              border border-gray-100 dark:border-gray-700
              hover:shadow-2xl hover:scale-[1.02] transition-all duration-300
              group cursor-pointer"
       data-action="click->wishlist-detail#viewItem"
       data-item-id="123">

    <!-- Item Image -->
    <div class="relative aspect-square overflow-hidden">
      <img src="item-image"
           class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500" />

      <!-- Purchase Overlay -->
      <div class="absolute inset-0 bg-black/50 flex items-center justify-center
                  opacity-0 group-hover:opacity-100 transition-opacity">
        <div class="text-center text-white">
          <svg class="w-12 h-12 mx-auto mb-2"><!-- Check circle --></svg>
          <p class="font-semibold">Purchased by Sarah</p>
        </div>
      </div>

      <!-- Quick Actions (top right) -->
      <div class="absolute top-2 right-2 flex gap-2">
        <button class="bg-white/90 hover:bg-white p-2 rounded-full shadow-lg">
          <svg class="w-4 h-4 text-gray-700"><!-- Heart icon --></svg>
        </button>
        <button class="bg-white/90 hover:bg-white p-2 rounded-full shadow-lg">
          <svg class="w-4 h-4 text-gray-700"><!-- Share icon --></svg>
        </button>
      </div>

      <!-- Price Badge (bottom left) -->
      <div class="absolute bottom-2 left-2 bg-white/95 backdrop-blur-sm
                  px-3 py-1 rounded-full shadow-lg">
        <p class="text-sm font-bold text-gray-800">$49.99</p>
      </div>
    </div>

    <!-- Item Info -->
    <div class="p-4">
      <h3 class="heading-card text-gray-800 dark:text-gray-100 mb-1 line-clamp-2">
        Wireless Noise Cancelling Headphones
      </h3>

      <p class="text-sm text-gray-600 dark:text-gray-400 mb-3 line-clamp-2">
        Premium audio with 30-hour battery life and active noise cancellation
      </p>

      <!-- Metadata -->
      <div class="flex items-center justify-between text-xs text-gray-500">
        <div class="flex items-center gap-1">
          <svg class="w-4 h-4"><!-- Eye icon --></svg>
          <span>24 views</span>
        </div>
        <div class="flex items-center gap-1">
          <svg class="w-4 h-4"><!-- Heart icon --></svg>
          <span>5 hearts</span>
        </div>
      </div>

      <!-- Purchase Status -->
      <div class="mt-3 pt-3 border-t border-gray-100 dark:border-gray-700">
        <div class="flex items-center justify-between">
          <span class="text-xs text-gray-600">Status:</span>
          <span class="bg-amber-100 text-amber-700 text-xs px-2 py-1 rounded-full">
            Available
          </span>
        </div>
      </div>
    </div>
  </div>
  ```

**Interactive Elements:**
- Masonry grid with stagger animations on load
- Item hover reveals purchase status + actions
- Quick heart/share buttons
- Filter items (All, Available, Purchased)
- Sort items (Newest, Price, Popularity)
- Drag-to-reorder items (future)

**Mobile Optimization:**
- 2-column masonry grid
- Floating "+ Add Item" button (bottom right)
- Swipe item card for quick actions
- Long-press for item menu

**Unique Features:**
- Purchase celebration animation (confetti when marked purchased)
- Progress ring showing % of items purchased
- "Trending" badge for most viewed/hearted items
- Collaborative purchase (multiple people can mark as "interested")
- Auto-hide purchased items option

---

### 3. ADD/EDIT ITEM FORM (/wishlists/:id/items/new)

**Purpose:** Add new item to wishlist with URL extraction + image upload

**Layout Structure:**
```
Desktop (1440px):
├─ Split View (50/50)
│  ├─ Left: Form Fields
│  └─ Right: Live Preview
│
Mobile (375px):
├─ Full-width form
├─ Bottom sheet preview (swipe up)
└─ Sticky save button
```

**Key Components:**
- **URL Extraction Section:**
  ```html
  <div class="url-extraction-section mb-6">
    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
      Add Item from URL
    </label>

    <div class="relative">
      <input type="url"
             name="item_url"
             placeholder="Paste Amazon, Nike, or any product URL..."
             class="w-full bg-white dark:bg-gray-800 border border-gray-300
                    dark:border-gray-600 rounded-xl px-4 py-3 pr-24
                    focus:ring-2 focus:ring-rose-500"
             data-action="paste->item-form#extractMetadata">

      <button type="button"
              class="absolute right-2 top-1/2 transform -translate-y-1/2
                     bg-gradient-to-r from-rose-500 to-rose-600 text-white
                     px-4 py-2 rounded-lg text-sm font-medium
                     hover:shadow-lg transition-all"
              data-action="click->item-form#extractMetadata"
              data-item-form-target="extractButton">
        Extract
      </button>
    </div>

    <!-- Loading State -->
    <div class="mt-2 hidden" data-item-form-target="loadingState">
      <div class="flex items-center gap-2 text-sm text-gray-600">
        <svg class="animate-spin w-4 h-4"><!-- Spinner --></svg>
        <span>Extracting product details...</span>
      </div>
    </div>

    <!-- Success State -->
    <div class="mt-2 hidden bg-green-50 border border-green-200 rounded-lg p-3"
         data-item-form-target="successState">
      <div class="flex items-center gap-2 text-sm text-green-700">
        <svg class="w-4 h-4"><!-- Check icon --></svg>
        <span>Product details extracted successfully!</span>
      </div>
    </div>

    <!-- Divider -->
    <div class="relative my-6">
      <div class="absolute inset-0 flex items-center">
        <div class="w-full border-t border-gray-200 dark:border-gray-700"></div>
      </div>
      <div class="relative flex justify-center text-sm">
        <span class="px-4 bg-gray-50 dark:bg-gray-900 text-gray-500">
          or add manually
        </span>
      </div>
    </div>
  </div>
  ```

- **Form Fields:**
  ```html
  <form class="space-y-6" data-controller="item-form">

    <!-- Item Name (Required) -->
    <div>
      <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
        Item Name *
      </label>
      <input type="text"
             name="item[name]"
             required
             placeholder="e.g., Wireless Headphones"
             class="w-full bg-white dark:bg-gray-800 border border-gray-300
                    rounded-xl px-4 py-3"
             data-item-form-target="nameField">
      <p class="mt-1 text-xs text-gray-500">Give your item a descriptive name</p>
    </div>

    <!-- Description (Optional) -->
    <div>
      <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
        Description
      </label>
      <textarea name="item[description]"
                rows="3"
                placeholder="Add details like color, size, or why you want this..."
                class="w-full bg-white dark:bg-gray-800 border border-gray-300
                       rounded-xl px-4 py-3 resize-none"></textarea>
      <div class="flex justify-between mt-1">
        <p class="text-xs text-gray-500">Help others understand why this matters</p>
        <span class="text-xs text-gray-500" data-item-form-target="charCount">0/500</span>
      </div>
    </div>

    <!-- Image Upload -->
    <div>
      <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
        Product Image
      </label>

      <!-- Image Preview -->
      <div class="mb-3" data-item-form-target="imagePreview">
        <div class="relative w-full h-48 bg-gray-100 dark:bg-gray-800 rounded-xl
                    border-2 border-dashed border-gray-300 dark:border-gray-600
                    flex items-center justify-center overflow-hidden">
          <!-- Preview image -->
          <img src="" class="hidden w-full h-full object-cover"
               data-item-form-target="previewImage" />

          <!-- Placeholder -->
          <div class="text-center" data-item-form-target="placeholderText">
            <svg class="w-12 h-12 text-gray-400 mx-auto mb-2"><!-- Image icon --></svg>
            <p class="text-sm text-gray-600">Drop image or click to upload</p>
            <p class="text-xs text-gray-500 mt-1">PNG, JPG up to 5MB</p>
          </div>
        </div>
      </div>

      <!-- Upload Buttons -->
      <div class="flex gap-2">
        <label class="flex-1 btn-secondary bg-white border border-gray-300
                      px-4 py-2 rounded-xl cursor-pointer text-center
                      hover:bg-gray-50 transition-colors">
          <span class="flex items-center justify-center gap-2">
            <svg class="w-4 h-4"><!-- Upload icon --></svg>
            Choose File
          </span>
          <input type="file"
                 accept="image/*"
                 class="hidden"
                 data-action="change->item-form#previewImage">
        </label>

        <button type="button"
                class="flex-1 btn-secondary bg-white border border-gray-300
                       px-4 py-2 rounded-xl hover:bg-gray-50"
                data-action="click->item-form#openCamera">
          <span class="flex items-center justify-center gap-2">
            <svg class="w-4 h-4"><!-- Camera icon --></svg>
            Take Photo
          </span>
        </button>
      </div>
    </div>

    <!-- Price & Currency -->
    <div class="grid grid-cols-2 gap-4">
      <div>
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Price
        </label>
        <div class="relative">
          <span class="absolute left-3 top-1/2 transform -translate-y-1/2
                       text-gray-500">$</span>
          <input type="number"
                 name="item[price]"
                 step="0.01"
                 placeholder="0.00"
                 class="w-full bg-white dark:bg-gray-800 border border-gray-300
                        rounded-xl pl-8 pr-4 py-3">
        </div>
      </div>

      <div>
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Currency
        </label>
        <select name="item[currency]"
                class="w-full bg-white dark:bg-gray-800 border border-gray-300
                       rounded-xl px-4 py-3">
          <option value="USD">USD ($)</option>
          <option value="BRL">BRL (R$)</option>
          <option value="EUR">EUR (€)</option>
          <!-- More currencies -->
        </select>
      </div>
    </div>

    <!-- URL (Optional) -->
    <div>
      <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
        Product URL
      </label>
      <input type="url"
             name="item[url]"
             placeholder="https://www.amazon.com/..."
             class="w-full bg-white dark:bg-gray-800 border border-gray-300
                    rounded-xl px-4 py-3">
      <p class="mt-1 text-xs text-gray-500">
        Link to where this item can be purchased
      </p>
    </div>

    <!-- Priority (Optional) -->
    <div>
      <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
        Priority
      </label>
      <div class="grid grid-cols-3 gap-2">
        <label class="priority-option">
          <input type="radio"
                 name="item[priority]"
                 value="low"
                 class="sr-only peer">
          <div class="border-2 border-gray-300 peer-checked:border-green-500
                      peer-checked:bg-green-50 rounded-xl p-3 cursor-pointer
                      text-center transition-all">
            <span class="text-2xl">😊</span>
            <p class="text-sm font-medium mt-1">Nice to Have</p>
          </div>
        </label>

        <label class="priority-option">
          <input type="radio"
                 name="item[priority]"
                 value="medium"
                 class="sr-only peer"
                 checked>
          <div class="border-2 border-gray-300 peer-checked:border-amber-500
                      peer-checked:bg-amber-50 rounded-xl p-3 cursor-pointer
                      text-center transition-all">
            <span class="text-2xl">🙂</span>
            <p class="text-sm font-medium mt-1">Would Love</p>
          </div>
        </label>

        <label class="priority-option">
          <input type="radio"
                 name="item[priority]"
                 value="high"
                 class="sr-only peer">
          <div class="border-2 border-gray-300 peer-checked:border-rose-500
                      peer-checked:bg-rose-50 rounded-xl p-3 cursor-pointer
                      text-center transition-all">
            <span class="text-2xl">😍</span>
            <p class="text-sm font-medium mt-1">Really Want</p>
          </div>
        </label>
      </div>
    </div>

    <!-- Form Actions -->
    <div class="flex gap-3 pt-4 border-t border-gray-200 dark:border-gray-700">
      <a href="/wishlists/:id"
         class="flex-1 btn-secondary bg-white border border-gray-300
                px-4 py-3 rounded-xl text-center">
        Cancel
      </a>

      <button type="submit"
              class="flex-1 btn-primary bg-gradient-to-r from-rose-500 to-rose-600
                     text-white px-4 py-3 rounded-xl font-medium
                     hover:shadow-xl transition-all">
        Add to Wishlist
      </button>
    </div>
  </form>
  ```

- **Live Preview Sidebar (Desktop Only):**
  ```html
  <div class="sticky top-24 hidden lg:block">
    <div class="bg-gradient-to-br from-gray-50 to-rose-50 dark:from-gray-900
                dark:to-rose-900/20 rounded-3xl p-6 border border-gray-200">
      <h3 class="heading-section mb-4 flex items-center gap-2">
        <svg class="w-5 h-5 text-rose-500"><!-- Eye icon --></svg>
        Live Preview
      </h3>

      <!-- Item Card Preview (Same as wishlist detail card) -->
      <div class="item-card-preview bg-white dark:bg-gray-800 rounded-2xl
                  overflow-hidden shadow-lg">
        <!-- Dynamic preview updates as user types -->
        <div class="aspect-square bg-gray-100 dark:bg-gray-700 flex items-center justify-center">
          <img data-item-form-target="livePreviewImage" class="hidden w-full h-full object-cover" />
          <svg class="w-16 h-16 text-gray-400" data-item-form-target="placeholderIcon">
            <!-- Image placeholder icon -->
          </svg>
        </div>

        <div class="p-4">
          <h4 class="heading-card text-gray-800 dark:text-gray-100 mb-2"
              data-item-form-target="livePreviewName">
            Item Name
          </h4>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-3 line-clamp-2"
             data-item-form-target="livePreviewDescription">
            Description will appear here...
          </p>

          <div class="flex justify-between items-center">
            <span class="text-lg font-bold text-rose-600"
                  data-item-form-target="livePreviewPrice">
              $0.00
            </span>
            <span class="bg-gray-100 px-2 py-1 rounded-full text-xs"
                  data-item-form-target="livePreviewPriority">
              Medium
            </span>
          </div>
        </div>
      </div>

      <!-- Tips Section -->
      <div class="mt-6 bg-white dark:bg-gray-800 rounded-xl p-4">
        <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2">
          💡 Pro Tips
        </h4>
        <ul class="text-xs text-gray-600 dark:text-gray-400 space-y-1">
          <li>• Add product URL for automatic metadata extraction</li>
          <li>• Upload high-quality images for better visibility</li>
          <li>• Include size/color preferences in description</li>
          <li>• Set priority to help gift-givers choose</li>
        </ul>
      </div>
    </div>
  </div>
  ```

**Interactive Elements:**
- URL paste triggers automatic metadata extraction
- Real-time character count for description
- Live preview updates as user types
- Image drag-and-drop support
- Camera access for photo capture (mobile)
- Priority selector with emoji feedback

**Mobile Optimization:**
- Bottom sheet for preview (swipe up to see)
- Sticky "Add to Wishlist" button at bottom
- Camera button for direct photo capture
- Optimized keyboard handling

**Unique Features:**
- **Smart URL Extraction:** Automatically fills name, price, image, description from URL
- **Multiple Image Upload:** Add 3-5 images per item (carousel in detail view)
- **Size/Color Variants:** Add multiple options for same item
- **Duplicate Detection:** Warns if similar item already exists
- **Save as Draft:** Auto-saves form progress every 30 seconds

---

### 4. ITEM DETAIL PAGE (/wishlists/:id/items/:item_id)

**Purpose:** Full item information + purchase tracking + sharing

**Layout Structure:**
```
Desktop (1440px):
├─ Left: Image Gallery (60%)
│  ├─ Main Image (large)
│  └─ Thumbnail carousel
│
└─ Right: Item Details (40%)
   ├─ Title + Price
   ├─ Description
   ├─ Purchase Status
   ├─ Stats (views, hearts)
   ├─ Action Buttons
   └─ Comments

Mobile (375px):
├─ Image Carousel (full width)
├─ Item Info Card
├─ Purchase Button (sticky)
└─ Comments Section
```

**Key Components:**
- **Image Gallery:**
  ```html
  <div class="item-gallery">
    <!-- Main Image -->
    <div class="main-image-container relative bg-gray-100 dark:bg-gray-800
                rounded-3xl overflow-hidden aspect-square mb-4"
         data-controller="image-zoom">
      <img src="item-image-large"
           class="w-full h-full object-cover cursor-zoom-in"
           data-action="click->image-zoom#zoom"
           alt="Product image" />

      <!-- Navigation Arrows -->
      <button class="absolute left-4 top-1/2 transform -translate-y-1/2
                     bg-white/90 hover:bg-white p-3 rounded-full shadow-lg"
              data-action="click->image-gallery#prev">
        <svg class="w-6 h-6"><!-- Left arrow --></svg>
      </button>
      <button class="absolute right-4 top-1/2 transform -translate-y-1/2
                     bg-white/90 hover:bg-white p-3 rounded-full shadow-lg"
              data-action="click->image-gallery#next">
        <svg class="w-6 h-6"><!-- Right arrow --></svg>
      </button>

      <!-- Image Counter -->
      <div class="absolute bottom-4 left-1/2 transform -translate-x-1/2
                  bg-black/70 text-white px-3 py-1 rounded-full text-sm">
        1 / 5
      </div>
    </div>

    <!-- Thumbnail Carousel -->
    <div class="flex gap-2 overflow-x-auto pb-2">
      <button class="thumbnail w-20 h-20 rounded-xl overflow-hidden
                     border-2 border-rose-500 flex-shrink-0">
        <img src="thumb1" class="w-full h-full object-cover" />
      </button>
      <button class="thumbnail w-20 h-20 rounded-xl overflow-hidden
                     border-2 border-gray-200 flex-shrink-0">
        <img src="thumb2" class="w-full h-full object-cover" />
      </button>
      <!-- More thumbnails -->
    </div>
  </div>
  ```

- **Item Details Card:**
  ```html
  <div class="item-details-card bg-white dark:bg-gray-800 rounded-3xl
              p-6 border border-gray-200 dark:border-gray-700 sticky top-24">

    <!-- Header -->
    <div class="mb-6">
      <div class="flex items-start justify-between mb-3">
        <h1 class="heading-page text-gray-800 dark:text-gray-100 flex-1 pr-4">
          Wireless Noise Cancelling Headphones
        </h1>

        <!-- Wishlist Badge -->
        <a href="/wishlists/:id"
           class="flex-shrink-0 bg-rose-100 text-rose-700 px-3 py-1 rounded-full
                  text-sm font-medium hover:bg-rose-200 transition-colors">
          🎂 Birthday
        </a>
      </div>

      <!-- Price -->
      <div class="flex items-baseline gap-3 mb-4">
        <p class="text-4xl font-bold text-rose-600">$249.99</p>
        <span class="text-lg text-gray-500 line-through">$299.99</span>
        <span class="bg-green-100 text-green-700 px-2 py-1 rounded-full text-sm font-medium">
          17% off
        </span>
      </div>

      <!-- Stats Bar -->
      <div class="grid grid-cols-3 gap-4 p-4 bg-gray-50 dark:bg-gray-900/50 rounded-xl">
        <div class="stat-item text-center cursor-pointer hover:bg-white
                    dark:hover:bg-gray-800 rounded-lg p-2 transition-colors"
             data-action="click->item-delight#celebrateViews">
          <svg class="w-5 h-5 mx-auto mb-1 text-gray-600"><!-- Eye icon --></svg>
          <p class="text-xl font-bold text-gray-800 dark:text-gray-100">243</p>
          <p class="text-xs text-gray-600 dark:text-gray-400">Views</p>
        </div>

        <div class="stat-item text-center cursor-pointer hover:bg-white
                    dark:hover:bg-gray-800 rounded-lg p-2 transition-colors"
             data-action="click->item-delight#celebrateHearts">
          <svg class="w-5 h-5 mx-auto mb-1 text-rose-500"><!-- Heart icon --></svg>
          <p class="text-xl font-bold text-gray-800 dark:text-gray-100">47</p>
          <p class="text-xs text-gray-600 dark:text-gray-400">Hearts</p>
        </div>

        <div class="stat-item text-center cursor-pointer hover:bg-white
                    dark:hover:bg-gray-800 rounded-lg p-2 transition-colors"
             data-action="click->item-delight#showPopularity">
          <svg class="w-5 h-5 mx-auto mb-1 text-amber-500"><!-- Fire icon --></svg>
          <p class="text-xl font-bold text-gray-800 dark:text-gray-100">8.5</p>
          <p class="text-xs text-gray-600 dark:text-gray-400">Popular</p>
        </div>
      </div>
    </div>

    <!-- Description -->
    <div class="mb-6">
      <h3 class="heading-sub text-gray-800 dark:text-gray-100 mb-2">
        About This Item
      </h3>
      <p class="text-body text-gray-600 dark:text-gray-400 leading-relaxed">
        Premium wireless headphones with industry-leading noise cancellation.
        Features 30-hour battery life, touch controls, and exceptional comfort
        for all-day wear. Perfect for travel, work, and music lovers.
      </p>
    </div>

    <!-- Priority Badge -->
    <div class="mb-6 p-4 bg-amber-50 dark:bg-amber-900/20 rounded-xl
                border border-amber-200 dark:border-amber-800">
      <div class="flex items-center gap-2">
        <span class="text-2xl">😍</span>
        <div>
          <p class="text-sm font-semibold text-amber-800 dark:text-amber-300">
            High Priority
          </p>
          <p class="text-xs text-amber-700 dark:text-amber-400">
            I really want this item!
          </p>
        </div>
      </div>
    </div>

    <!-- Purchase Status -->
    <div class="mb-6 p-5 bg-gradient-to-br from-green-50 to-emerald-50
                dark:from-green-900/20 dark:to-emerald-900/20 rounded-2xl
                border-2 border-green-200 dark:border-green-800">
      <div class="flex items-center justify-between mb-3">
        <div class="flex items-center gap-2">
          <svg class="w-6 h-6 text-green-600"><!-- Check circle --></svg>
          <p class="text-sm font-semibold text-green-800 dark:text-green-300">
            Purchased by Sarah Martinez
          </p>
        </div>
        <span class="bg-green-200 text-green-800 text-xs px-2 py-1 rounded-full">
          2 days ago
        </span>
      </div>
      <p class="text-xs text-green-700 dark:text-green-400">
        This item has been purchased! Delivery expected by June 15th.
      </p>
    </div>

    <!-- Action Buttons -->
    <div class="space-y-3">
      <!-- If NOT purchased -->
      <button class="btn-primary w-full bg-gradient-to-r from-rose-500 to-rose-600
                     text-white px-6 py-4 rounded-xl font-semibold text-lg
                     hover:shadow-2xl hover:scale-[1.02] transition-all
                     flex items-center justify-center gap-2"
              data-action="click->item-delight#purchaseCelebration">
        <svg class="w-6 h-6"><!-- Check icon --></svg>
        Mark as Purchased
      </button>

      <!-- If purchased (undo option) -->
      <button class="btn-secondary w-full bg-white border-2 border-gray-300
                     text-gray-700 px-6 py-3 rounded-xl font-medium
                     hover:bg-gray-50 transition-colors">
        Undo Purchase
      </button>

      <!-- Secondary Actions -->
      <div class="grid grid-cols-2 gap-3">
        <button class="btn-secondary bg-white border border-gray-300
                       px-4 py-3 rounded-xl flex items-center justify-center gap-2
                       hover:bg-gray-50 transition-colors"
                data-action="click->item-delight#shareItem">
          <svg class="w-5 h-5"><!-- Share icon --></svg>
          <span>Share</span>
        </button>

        <button class="btn-secondary bg-white border border-gray-300
                       px-4 py-3 rounded-xl flex items-center justify-center gap-2
                       hover:bg-rose-50 hover:border-rose-300 transition-colors"
                data-action="click->item-delight#heartItem">
          <svg class="w-5 h-5 text-rose-500"><!-- Heart icon --></svg>
          <span>Heart</span>
        </button>
      </div>

      <!-- Product Link -->
      <a href="https://amazon.com/..."
         target="_blank"
         class="block w-full bg-gradient-to-r from-purple-500 to-purple-600
                text-white px-6 py-3 rounded-xl font-medium text-center
                hover:shadow-xl transition-all">
        View on Amazon →
      </a>
    </div>

    <!-- Owner Actions (if own wishlist) -->
    <div class="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700
                flex gap-2">
      <a href="/wishlists/:id/items/:item_id/edit"
         class="flex-1 text-center text-gray-600 hover:text-gray-800
                py-2 text-sm font-medium">
        Edit Item
      </a>
      <button class="flex-1 text-center text-red-600 hover:text-red-800
                     py-2 text-sm font-medium"
              data-action="click->item-delight#confirmDelete">
        Delete Item
      </button>
    </div>
  </div>
  ```

- **Comments Section:**
  ```html
  <div class="comments-section mt-8">
    <h3 class="heading-section text-gray-800 dark:text-gray-100 mb-4">
      Comments & Notes
    </h3>

    <!-- Add Comment Form -->
    <div class="mb-6">
      <div class="flex gap-3">
        <img src="current-user-avatar"
             class="w-10 h-10 rounded-full flex-shrink-0" />
        <div class="flex-1">
          <textarea placeholder="Add a note or comment..."
                    rows="2"
                    class="w-full bg-white dark:bg-gray-800 border border-gray-300
                           rounded-xl px-4 py-3 resize-none
                           focus:ring-2 focus:ring-rose-500"></textarea>
          <button class="mt-2 bg-gradient-to-r from-rose-500 to-rose-600
                         text-white px-4 py-2 rounded-lg text-sm font-medium">
            Post Comment
          </button>
        </div>
      </div>
    </div>

    <!-- Comment List -->
    <div class="space-y-4">
      <div class="comment bg-gray-50 dark:bg-gray-900/50 rounded-xl p-4">
        <div class="flex gap-3">
          <img src="commenter-avatar" class="w-8 h-8 rounded-full flex-shrink-0" />
          <div class="flex-1">
            <div class="flex items-center justify-between mb-1">
              <p class="text-sm font-semibold text-gray-800 dark:text-gray-100">
                Sarah Martinez
              </p>
              <span class="text-xs text-gray-500">2 hours ago</span>
            </div>
            <p class="text-sm text-gray-600 dark:text-gray-400">
              These look amazing! I've added them to your wishlist.
              Can't wait for your birthday! 🎉
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
  ```

**Interactive Elements:**
- **Multi-stage Purchase Celebration:**
  1. Button click triggers confetti
  2. Success message with animation
  3. Status card transforms with green gradient
  4. Floating emojis (🎉, 🎁, ✨)

- **Stat Cards:** Clickable stats with micro-celebrations
- **Share Button:** Opens native share sheet with social media options
- **Heart Button:** Adds to favorites with heart animation
- **Image Zoom:** Click main image to zoom, pinch-to-zoom on mobile

**Mobile Optimization:**
- Swipeable image carousel
- Sticky purchase button at bottom
- Bottom sheet for comments
- Optimized for one-handed use

**Unique Features:**
- **Trending Badge:** Shows if item is popular (high views/hearts)
- **Price Drop Alert:** Notifies if price decreases
- **Similar Items:** Suggests related items from friends' wishlists
- **Purchase Confirmation:** Prevents accidental purchases with double-tap
- **Screenshot-Worthy:** Celebration animations optimized for sharing

---

### 5. PROFILE VIEW (/profile)

**Purpose:** Display own profile with wishlists + stats + social links

**Layout Structure:**
```
Desktop (1440px):
├─ Profile Header (cover image + avatar + bio)
├─ Stats Bar (wishlists, items, friends, views)
├─ Tab Navigation (Wishlists, Activity, About)
└─ Content Area (based on active tab)

Mobile (375px):
├─ Profile Header (compact)
├─ Stats Grid (2x2)
├─ Tabs (swipeable)
└─ Content
```

**Key Components:**
- **Profile Header:**
  ```html
  <div class="profile-header relative mb-8">
    <!-- Cover Image -->
    <div class="relative h-48 sm:h-64 overflow-hidden rounded-b-3xl">
      <img src="cover-image"
           class="w-full h-full object-cover" />
      <div class="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent"></div>

      <!-- Edit Button (if own profile) -->
      <a href="/profile/edit"
         class="absolute top-4 right-4 bg-white/90 hover:bg-white
                text-gray-800 px-4 py-2 rounded-xl text-sm font-medium
                flex items-center gap-2 shadow-lg">
        <svg class="w-4 h-4"><!-- Pencil icon --></svg>
        Edit Profile
      </a>
    </div>

    <!-- Profile Info (overlaid at bottom) -->
    <div class="relative px-4 sm:px-6 lg:px-8 -mt-16">
      <div class="flex flex-col sm:flex-row items-center sm:items-end gap-4">
        <!-- Avatar -->
        <div class="relative">
          <img src="profile-avatar"
               class="w-32 h-32 rounded-full border-4 border-white
                      dark:border-gray-900 shadow-xl" />

          <!-- Online Status Indicator -->
          <div class="absolute bottom-2 right-2 w-6 h-6 bg-green-500
                      border-4 border-white dark:border-gray-900 rounded-full"></div>
        </div>

        <!-- Info -->
        <div class="flex-1 text-center sm:text-left">
          <h1 class="heading-page text-gray-800 dark:text-gray-100 mb-1">
            Hel Rabelo
          </h1>
          <p class="text-body text-gray-600 dark:text-gray-400 mb-2">
            @helrabelo • Joined March 2025
          </p>

          <!-- Bio -->
          <p class="text-body-sm text-gray-700 dark:text-gray-300 max-w-2xl">
            Product designer & developer 🎨 Building delightful experiences
            ✨ Coffee enthusiast ☕️
          </p>
        </div>

        <!-- Social Links -->
        <div class="flex gap-2">
          <a href="https://instagram.com/helrabelo"
             class="p-2 bg-white dark:bg-gray-800 rounded-lg border border-gray-200
                    hover:bg-gray-50 transition-colors">
            <svg class="w-5 h-5 text-pink-600"><!-- Instagram icon --></svg>
          </a>
          <a href="https://twitter.com/helrabelo"
             class="p-2 bg-white dark:bg-gray-800 rounded-lg border border-gray-200
                    hover:bg-gray-50 transition-colors">
            <svg class="w-5 h-5 text-blue-400"><!-- Twitter icon --></svg>
          </a>
          <a href="https://helrabelo.dev"
             class="p-2 bg-white dark:bg-gray-800 rounded-lg border border-gray-200
                    hover:bg-gray-50 transition-colors">
            <svg class="w-5 h-5 text-gray-600"><!-- Link icon --></svg>
          </a>
        </div>
      </div>
    </div>
  </div>
  ```

- **Stats Bar:**
  ```html
  <div class="stats-bar grid grid-cols-2 sm:grid-cols-4 gap-4 mb-8 px-4">
    <!-- Wishlists -->
    <a href="#wishlists-tab"
       class="stat-card bg-gradient-to-br from-rose-50 to-pink-50
              dark:from-rose-900/20 dark:to-pink-900/20
              rounded-2xl p-5 border border-rose-200 dark:border-rose-800
              hover:shadow-xl hover:scale-105 transition-all cursor-pointer">
      <div class="flex items-center justify-between mb-2">
        <svg class="w-8 h-8 text-rose-500"><!-- Gift icon --></svg>
        <span class="bg-rose-500 text-white text-xs px-2 py-1 rounded-full">
          Active
        </span>
      </div>
      <p class="text-3xl font-bold text-gray-800 dark:text-gray-100 mb-1">12</p>
      <p class="text-sm text-gray-600 dark:text-gray-400">Wishlists</p>
    </a>

    <!-- Items -->
    <div class="stat-card bg-gradient-to-br from-purple-50 to-indigo-50
                dark:from-purple-900/20 dark:to-indigo-900/20
                rounded-2xl p-5 border border-purple-200 dark:border-purple-800
                hover:shadow-xl hover:scale-105 transition-all">
      <svg class="w-8 h-8 text-purple-500 mb-2"><!-- Tag icon --></svg>
      <p class="text-3xl font-bold text-gray-800 dark:text-gray-100 mb-1">87</p>
      <p class="text-sm text-gray-600 dark:text-gray-400">Items</p>
    </div>

    <!-- Friends -->
    <a href="/connections"
       class="stat-card bg-gradient-to-br from-amber-50 to-orange-50
              dark:from-amber-900/20 dark:to-orange-900/20
              rounded-2xl p-5 border border-amber-200 dark:border-amber-800
              hover:shadow-xl hover:scale-105 transition-all cursor-pointer">
      <svg class="w-8 h-8 text-amber-500 mb-2"><!-- Users icon --></svg>
      <p class="text-3xl font-bold text-gray-800 dark:text-gray-100 mb-1">24</p>
      <p class="text-sm text-gray-600 dark:text-gray-400">Friends</p>
    </a>

    <!-- Profile Views -->
    <div class="stat-card bg-gradient-to-br from-green-50 to-emerald-50
                dark:from-green-900/20 dark:to-emerald-900/20
                rounded-2xl p-5 border border-green-200 dark:border-green-800
                hover:shadow-xl hover:scale-105 transition-all">
      <svg class="w-8 h-8 text-green-500 mb-2"><!-- Eye icon --></svg>
      <p class="text-3xl font-bold text-gray-800 dark:text-gray-100 mb-1">1.2K</p>
      <p class="text-sm text-gray-600 dark:text-gray-400">Views</p>
    </div>
  </div>
  ```

- **Tab Navigation:**
  ```html
  <div class="tabs-container mb-8 px-4" data-controller="tabs">
    <div class="flex border-b border-gray-200 dark:border-gray-700 overflow-x-auto">
      <button data-tabs-target="tab"
              data-tab="wishlists"
              data-action="click->tabs#switch"
              class="tab-button flex items-center gap-2 px-6 py-3 font-medium
                     border-b-2 border-rose-500 text-rose-600
                     dark:text-rose-400 whitespace-nowrap">
        <svg class="w-5 h-5"><!-- Gift icon --></svg>
        Wishlists (12)
      </button>

      <button data-tabs-target="tab"
              data-tab="activity"
              data-action="click->tabs#switch"
              class="tab-button flex items-center gap-2 px-6 py-3 font-medium
                     border-b-2 border-transparent text-gray-600
                     dark:text-gray-400 hover:text-gray-800 whitespace-nowrap">
        <svg class="w-5 h-5"><!-- Activity icon --></svg>
        Activity
      </button>

      <button data-tabs-target="tab"
              data-tab="about"
              data-action="click->tabs#switch"
              class="tab-button flex items-center gap-2 px-6 py-3 font-medium
                     border-b-2 border-transparent text-gray-600
                     dark:text-gray-400 hover:text-gray-800 whitespace-nowrap">
        <svg class="w-5 h-5"><!-- Info icon --></svg>
        About
      </button>
    </div>
  </div>
  ```

- **Wishlists Tab Content:**
  ```html
  <div data-tabs-target="content"
       data-tab="wishlists"
       class="tab-content px-4">

    <!-- Featured Wishlist (if has featured) -->
    <div class="featured-wishlist mb-8 bg-gradient-to-br from-rose-50 via-pink-50 to-purple-50
                dark:from-rose-900/20 dark:via-pink-900/20 dark:to-purple-900/20
                rounded-3xl p-6 border-2 border-rose-200 dark:border-rose-800">
      <div class="flex items-center gap-2 mb-3">
        <svg class="w-5 h-5 text-rose-500"><!-- Star icon --></svg>
        <span class="text-sm font-semibold text-rose-700 dark:text-rose-400">
          Featured Wishlist
        </span>
      </div>

      <div class="flex flex-col sm:flex-row gap-6">
        <img src="wishlist-cover"
             class="w-full sm:w-48 h-48 object-cover rounded-2xl flex-shrink-0" />

        <div class="flex-1">
          <h3 class="heading-card text-gray-800 dark:text-gray-100 mb-2">
            30th Birthday Celebration 🎂
          </h3>
          <p class="text-body-sm text-gray-600 dark:text-gray-400 mb-4">
            Celebrating three decades! Here's everything I'm dreaming of
            for my milestone birthday.
          </p>

          <div class="flex items-center gap-4 text-sm text-gray-600 mb-4">
            <span>24 items</span>
            <span>•</span>
            <span>8 purchased</span>
            <span>•</span>
            <span>15 days left</span>
          </div>

          <a href="/wishlists/:id"
             class="btn-primary bg-gradient-to-r from-rose-500 to-rose-600
                    text-white px-6 py-2 rounded-xl inline-block">
            View Wishlist
          </a>
        </div>
      </div>
    </div>

    <!-- Wishlists Grid (same as /wishlists page) -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Wishlist cards... -->
    </div>
  </div>
  ```

**Interactive Elements:**
- Swipeable tabs on mobile
- Clickable stat cards with animations
- Hover effects on social links
- Achievement badges (if applicable)
- Edit profile quick access

**Mobile Optimization:**
- Compact header with mobile-optimized layout
- 2x2 stats grid
- Horizontal scrolling tabs
- Bottom navigation integration

**Unique Features:**
- **Profile Strength Indicator:** Shows completion percentage
- **Achievement Showcase:** Display earned badges/milestones
- **Featured Wishlist:** Highlight most important wishlist
- **Recent Activity Feed:** Show latest actions
- **Social Proof:** Display total profile views and engagement

---

## Additional Prototypes (6-10)

Due to length constraints, here are brief specifications for remaining top 10:

### 6. CONNECTIONS PAGE (/connections)
- **Grid layout** of friend cards with avatars, names, wishlist counts
- **Search/filter** friends by name
- **Pending invitations** section at top
- **Quick actions:** View wishlists, Remove connection
- **Empty state:** Encourage sending invitations

### 7. SEND INVITATION (/invitations/new)
- **Email input** with validation
- **Personal message** textarea (optional)
- **Connection context:** Select relationship type
- **Preview** of invitation email
- **Success celebration:** Confetti + share link options

### 8. USER PROFILE (/users/:id)
- **Similar to own profile** but read-only
- **Connection status** badge (Friend, Not Connected, Pending)
- **Public wishlists only** (filtered)
- **Send connection request** button if not connected
- **Share profile** button

### 9. NOTIFICATIONS CENTER (/notifications)
- **Tabbed interface:** All, Unread, Purchases, Social
- **Notification cards** with icons, messages, timestamps
- **Mark as read** inline action
- **Clear all** button
- **Real-time updates** via ActionCable

### 10. PROFILE EDIT (/profile/edit)
- **Already well-implemented** with collapsible sections
- **Additional enhancements:**
  - Live avatar preview during upload
  - Social media URL validation
  - Profile preview button (shows public view)
  - Success toast on save

---

## Implementation Recommendations

### Sprint Planning (6 Weeks Total)

**Week 1-2: Core Journeys**
- Dashboard prototype
- Wishlist detail enhancement
- Item form with URL extraction
- Item detail page

**Week 3: Social Features**
- Connections page
- Invitation flow
- Public user profiles
- Notifications

**Week 4: Settings & Management**
- Profile edit refinements
- Create/edit wishlist
- Notification preferences

**Week 5: Public Routes**
- Landing page redesign
- Use case pages
- Auth flow improvements

**Week 6: Polish & Mobile**
- Mobile optimizations
- PWA enhancements
- Performance tuning
- Animation refinements

### Design Handoff Checklist

For each prototype:
- ✅ Figma mockups (desktop + mobile)
- ✅ Component breakdown
- ✅ Animation specifications
- ✅ Copy/content guidelines
- ✅ Accessibility notes
- ✅ Dark mode variants
- ✅ Empty states
- ✅ Error states
- ✅ Loading states

### Development Strategy

1. **Component Library First:** Build reusable Stimulus controllers
2. **Mobile-First Always:** Start with mobile, enhance for desktop
3. **Progressive Enhancement:** Core functionality works without JS
4. **Animation Last:** Get layout right, then add delight
5. **Test on Devices:** Real iOS/Android testing throughout

---

## Success Metrics

### Prototype Approval Criteria
- User can complete task without confusion
- Visual hierarchy guides attention correctly
- Animations enhance (don't distract)
- Performance feels instant (<100ms interactions)
- Mobile thumb-reach optimization
- Dark mode looks intentional
- Delightful moments encourage sharing

### User Testing Questions
1. Can you find and add an item to your wishlist?
2. How would you share your wishlist with a friend?
3. What does this button do? (pointing at various CTAs)
4. Is anything confusing or unclear?
5. What moment made you smile?

---

## Next Steps

1. **Review this document** with user
2. **Approve prototyping order** (modify if needed)
3. **Start with /wishlists header enhancements** (quickest win)
4. **Create Dashboard prototype** (highest impact)
5. **Iterate based on feedback**

---

**Document Version:** 1.0
**Created:** 2025-09-30
**Last Updated:** 2025-09-30
**Status:** Ready for Review