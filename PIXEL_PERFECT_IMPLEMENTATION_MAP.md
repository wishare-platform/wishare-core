# Wishare Pixel-Perfect Implementation Map

**Goal**: Transform ALL Rails pages to match HTML prototypes pixel-perfectly

**Status**: 1/26 Complete (Design System ✅)

---

## Implementation Priority & Mapping

### ✅ PHASE 0: COMPLETE (1/26)
1. **Design System** ✅
   - Prototype: `design-system-demo.html`
   - Rails: `/styleguide`
   - Status: PIXEL-PERFECT (commit 3f4c271)

---

### 🔥 PHASE 1: Critical Auth Flow (4 pages)
**Priority**: HIGHEST - Blocks all user acquisition

1. **Login Page**
   - Prototype: `login.html`
   - Rails: `app/views/devise/sessions/new.html.erb`
   - Route: `/users/sign_in`
   - Status: ❌ NOT PIXEL-PERFECT

2. **Signup Page**
   - Prototype: `signup.html`
   - Rails: `app/views/devise/registrations/new.html.erb`
   - Route: `/users/sign_up`
   - Status: ❌ NOT PIXEL-PERFECT

3. **Forgot Password**
   - Prototype: `forgot-password.html`
   - Rails: `app/views/devise/passwords/new.html.erb`
   - Route: `/users/password/new`
   - Status: ❌ NOT PIXEL-PERFECT

4. **Reset Password**
   - Prototype: `reset-password.html`
   - Rails: `app/views/devise/passwords/edit.html.erb`
   - Route: `/users/password/edit`
   - Status: ❌ NOT PIXEL-PERFECT

**Estimated Time**: 4-6 hours
**Business Impact**: 🔴 CRITICAL - First impression, conversion rate

---

### 🎯 PHASE 2: Core User Journey (3 pages)
**Priority**: HIGH - Main user experience flow

5. **Landing Page**
   - Prototype: `landing-page.html`
   - Rails: `app/views/landing/index.html.erb`
   - Route: `/`
   - Status: ❌ NOT PIXEL-PERFECT

6. **Dashboard**
   - Prototype: `dashboard.html`
   - Rails: `app/views/dashboard/index.html.erb`
   - Route: `/dashboard`
   - Status: ⚠️ PARTIAL - Has animations but needs visual match
   - Notes: Already has delight framework, focus on visual accuracy

7. **Wishlist Show**
   - Prototype: `wishlist-show.html`
   - Rails: `app/views/wishlists/show.html.erb`
   - Route: `/wishlists/:id`
   - Status: ❌ NOT PIXEL-PERFECT
   - Alternative: `wishlist-pinterest-masonry.html` (v1 & v2)

**Estimated Time**: 6-8 hours
**Business Impact**: 🟠 HIGH - Core product experience

---

### 🛠️ PHASE 3: CRUD Operations (6 pages)
**Priority**: MEDIUM-HIGH - Essential functionality

8. **Create Wishlist**
   - Prototype: `create-wishlist.html`
   - Rails: `app/views/wishlists/new.html.erb`
   - Route: `/wishlists/new`
   - Status: ❌ NOT PIXEL-PERFECT

9. **Edit Wishlist**
   - Prototype: `edit-wishlist.html`
   - Rails: `app/views/wishlists/edit.html.erb`
   - Route: `/wishlists/:id/edit`
   - Status: ❌ NOT PIXEL-PERFECT

10. **Add Item** (Multiple Scenarios)
    - Prototypes:
      - `add-item.html` (base)
      - `add-item-v2.html` (improved)
      - `add-item-scenario-a.html` (URL paste)
      - `add-item-scenario-b.html` (manual entry)
      - `add-item-scenario-c.html` (quick add)
    - Rails: `app/views/wishlist_items/new.html.erb`
    - Route: `/wishlists/:wishlist_id/items/new`
    - Status: ❌ NOT PIXEL-PERFECT
    - Notes: 5 different UX scenarios to choose from

11. **Edit Item**
    - Prototype: `edit-item.html`
    - Rails: `app/views/wishlist_items/edit.html.erb`
    - Route: `/wishlists/:wishlist_id/items/:id/edit`
    - Status: ❌ NOT PIXEL-PERFECT

12. **Item Detail**
    - Prototype: `item-detail.html`
    - Rails: `app/views/wishlist_items/show.html.erb`
    - Route: `/wishlists/:wishlist_id/items/:id`
    - Status: ❌ NOT PIXEL-PERFECT

13. **Wishlist Index**
    - Prototype: N/A (may need to create)
    - Rails: `app/views/wishlists/index.html.erb`
    - Route: `/wishlists`
    - Status: ❌ NOT PIXEL-PERFECT

**Estimated Time**: 8-12 hours
**Business Impact**: 🟡 MEDIUM-HIGH - Core content creation

---

### 👥 PHASE 4: Social Features (5 pages)
**Priority**: MEDIUM - Growth & engagement

14. **Connections**
    - Prototype: `connections.html`
    - Rails: `app/views/connections/index.html.erb`
    - Route: `/connections`
    - Status: ❌ NOT PIXEL-PERFECT

15. **Invitations**
    - Prototype: `invitations.html`
    - Rails: `app/views/invitations/new.html.erb` or `show.html.erb`
    - Route: `/invitations`
    - Status: ❌ NOT PIXEL-PERFECT

16. **Accept Invite**
    - Prototype: `accept-invite.html`
    - Rails: `app/views/invitations/show.html.erb` (with token)
    - Route: `/invitations/:token`
    - Status: ❌ NOT PIXEL-PERFECT

17. **Discover** (NEW FEATURE)
    - Prototype: `discover.html`
    - Rails: ❌ NEED TO CREATE `app/views/discover/index.html.erb`
    - Route: ❌ NEED TO CREATE `/discover`
    - Status: ❌ NOT IMPLEMENTED

18. **Search** (NEW FEATURE)
    - Prototype: `search.html`
    - Rails: ❌ NEED TO CREATE `app/views/search/index.html.erb`
    - Route: ❌ NEED TO CREATE `/search`
    - Status: ❌ NOT IMPLEMENTED

**Estimated Time**: 8-10 hours
**Business Impact**: 🟡 MEDIUM - Viral growth potential

---

### 👤 PHASE 5: Profile Pages (2 pages)
**Priority**: MEDIUM - User personalization

19. **Edit Profile**
    - Prototype: `edit-profile.html`
    - Rails: `app/views/devise/registrations/edit.html.erb`
    - Route: `/users/edit`
    - Status: ⚠️ PARTIAL - Has progressive disclosure, needs visual match

20. **Public Profile**
    - Prototype: `public-profile.html`
    - Rails: `app/views/profile/show.html.erb`
    - Route: `/profile/:username`
    - Status: ❌ NOT PIXEL-PERFECT

**Estimated Time**: 4-6 hours
**Business Impact**: 🟢 MEDIUM - Personal branding

---

### 🎨 PHASE 6: Advanced Layouts (2 pages)
**Priority**: LOW - Nice to have, alternative views

21. **Pinterest Masonry Layout v1**
    - Prototype: `wishlist-pinterest-masonry.html`
    - Rails: Alternative view for `wishlists/show.html.erb`
    - Route: `/wishlists/:id?view=masonry`
    - Status: ❌ NOT IMPLEMENTED
    - Notes: Modern Instagram/Pinterest-style grid

22. **Pinterest Masonry Layout v2**
    - Prototype: `wishlist-pinterest-masonry-v2.html`
    - Rails: Alternative view for `wishlists/show.html.erb`
    - Route: `/wishlists/:id?view=masonry_v2`
    - Status: ❌ NOT IMPLEMENTED
    - Notes: Enhanced version with better UX

**Estimated Time**: 6-8 hours
**Business Impact**: 🟢 LOW - Visual polish, shareability

---

### 🏗️ PHASE 7: App Infrastructure (1 page)
**Priority**: MEDIUM - Consistent navigation

23. **App Layout Chrome**
    - Prototype: `app-layout-chrome.html`
    - Rails: `app/views/layouts/application.html.erb`
    - Scope: Navigation, header, footer, sidebar
    - Status: ⚠️ PARTIAL - Needs navbar/footer updates

**Estimated Time**: 4-6 hours
**Business Impact**: 🟡 MEDIUM - Consistent UX across app

---

## Implementation Strategy

### Week 1: Authentication & Core Journey (Days 1-2)
- ✅ Day 1 Morning: Login + Signup pages
- ✅ Day 1 Afternoon: Forgot/Reset Password pages
- ✅ Day 2 Morning: Landing page
- ✅ Day 2 Afternoon: Dashboard visual accuracy

### Week 1: CRUD Operations (Days 3-4)
- ✅ Day 3: Create/Edit Wishlist + Wishlist Show
- ✅ Day 4: Add/Edit Item + Item Detail

### Week 2: Social & Profiles (Days 5-6)
- ✅ Day 5: Connections + Invitations + Accept Invite
- ✅ Day 6: Edit Profile + Public Profile

### Week 2: Advanced Features (Optional, Days 7+)
- ⏰ Day 7: Discover + Search (NEW features)
- ⏰ Day 8: Pinterest Masonry layouts
- ⏰ Day 9: App Layout Chrome polish

---

## Total Effort Estimate

- **Phase 1 (Auth)**: 4-6 hours ⚡ CRITICAL
- **Phase 2 (Core)**: 6-8 hours ⚡ HIGH
- **Phase 3 (CRUD)**: 8-12 hours
- **Phase 4 (Social)**: 8-10 hours
- **Phase 5 (Profile)**: 4-6 hours
- **Phase 6 (Masonry)**: 6-8 hours
- **Phase 7 (Layout)**: 4-6 hours

**TOTAL**: 40-56 hours (5-7 full work days)

---

## Success Criteria

✅ **Visual Accuracy**
- All colors match design system
- All spacing/padding matches prototypes
- All fonts/typography matches
- All hover states/animations match

✅ **Responsive Design**
- Mobile-first approach
- Tablet breakpoint works
- Desktop layout matches

✅ **Dark Mode**
- All pages support dark mode
- Dark mode matches prototypes

✅ **Accessibility**
- ARIA labels where needed
- Keyboard navigation works
- Focus states visible

---

## Next Immediate Action

**START**: Phase 1 - Login Page
- Read `login.html` prototype
- Compare with `devise/sessions/new.html.erb`
- Extract exact CSS from prototype
- Implement pixel-perfect match
- Test on multiple screen sizes
- Commit & move to Signup

**Agent Strategy**: Use `ui-designer` + `frontend-developer` agents in parallel for faster implementation.
