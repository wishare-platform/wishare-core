# Login Page Switchers Design Specification

## Project Context
**Page**: Login page (`app/views/devise/sessions/new.html.erb`)
**Layout**: `auth.html.erb` (clean, no navigation)
**Design Goal**: Add SMALL, ELEGANT switchers for language and theme in top-right corner without interfering with login card visual hierarchy

---

## 1. Visual Design Overview

### Design Philosophy
- **Minimal & Elegant**: Settings-like controls, not navigation
- **Glass Morphism**: Match login card aesthetic with subtle transparency
- **Compact Size**: Small pill-shaped or icon buttons (40x40px max)
- **Non-Intrusive**: Fixed position that doesn't distract from login flow
- **Delightful**: Smooth transitions with subtle hover effects

### Color Palette Reference
- **Light Mode**: Purple/Pink gradient accents, gray backgrounds
- **Dark Mode**: Darker backgrounds with proper contrast
- **Primary**: `from-purple-600 via-pink-600 to-rose-600`
- **Accent**: `purple-500`, `pink-500`, `rose-500`

---

## 2. Component Design Options

### Option 1: MINIMAL PILL (Recommended)
**Visual Description**:
```
┌─────────────────────────────┐
│   [EN 🇺🇸]  [☀️]           │  ← Top-right corner
│                              │
│                              │
│     [Login Card]            │
└─────────────────────────────┘
```

**Characteristics**:
- Two separate small pill buttons side by side
- 40px height, auto width (60-80px)
- Glass morphism effect matching login card
- Horizontal layout with 8px gap
- Flag emoji + language code for locale
- Sun/Moon icon for theme

**Best For**: Maximum simplicity, separate concerns

---

### Option 2: COMBINED PILL
**Visual Description**:
```
┌─────────────────────────────┐
│   [EN 🇺🇸 | ☀️]            │  ← Top-right corner
│                              │
│     [Login Card]            │
└─────────────────────────────┘
```

**Characteristics**:
- Single pill containing both controls
- 40px height, ~120px width
- Divider line between language and theme
- More compact, unified appearance
- Same glass morphism aesthetic

**Best For**: Space efficiency, cohesive look

---

### Option 3: ICON-ONLY MINIMAL
**Visual Description**:
```
┌─────────────────────────────┐
│        [🇺🇸] [🌙]          │  ← Top-right corner
│                              │
│     [Login Card]            │
└─────────────────────────────┘
```

**Characteristics**:
- Two circular icon buttons (40x40px each)
- Flag emoji only (no text)
- Sun/Moon icon only
- Ultra-minimal, maximum space saving
- Tooltips on hover for clarity

**Best For**: Ultra-clean aesthetic, experienced users

---

## 3. Detailed HTML Structure

### Option 1: Minimal Pill (Recommended Implementation)

```erb
<!-- Language & Theme Switchers -->
<div class="fixed top-4 right-4 z-50 flex items-center gap-2">

  <!-- Language Switcher -->
  <div class="relative" data-controller="dropdown">
    <button
      type="button"
      data-action="click->dropdown#toggle"
      class="switcher-pill flex items-center gap-2 px-3 py-2 glass-strong rounded-full shadow-lg hover:shadow-xl transition-all duration-300 hover:scale-105 group"
    >
      <span class="text-base"><%= I18n.locale == :en ? '🇺🇸' : '🇧🇷' %></span>
      <span class="text-xs font-semibold text-gray-700 dark:text-gray-200 uppercase">
        <%= I18n.locale %>
      </span>
      <svg class="w-3 h-3 text-gray-500 dark:text-gray-400 group-hover:text-purple-500 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
      </svg>
    </button>

    <!-- Dropdown Menu -->
    <div
      data-dropdown-target="menu"
      class="dropdown-menu absolute top-full right-0 mt-2 w-32 glass-strong rounded-xl shadow-xl overflow-hidden opacity-0 scale-95 pointer-events-none transition-all duration-200"
    >
      <%= link_to url_for(locale: :en),
            class: "flex items-center gap-2 px-4 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-purple-50 dark:hover:bg-purple-900/20 transition-colors" do %>
        <span>🇺🇸</span>
        <span>English</span>
        <% if I18n.locale == :en %>
          <svg class="w-4 h-4 ml-auto text-purple-600" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
          </svg>
        <% end %>
      <% end %>

      <%= link_to url_for(locale: :'pt-BR'),
            class: "flex items-center gap-2 px-4 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-purple-50 dark:hover:bg-purple-900/20 transition-colors" do %>
        <span>🇧🇷</span>
        <span>Português</span>
        <% if I18n.locale == :'pt-BR' %>
          <svg class="w-4 h-4 ml-auto text-purple-600" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
          </svg>
        <% end %>
      <% end %>
    </div>
  </div>

  <!-- Theme Switcher -->
  <button
    type="button"
    data-controller="theme"
    data-action="click->theme#toggle"
    class="switcher-pill w-10 h-10 glass-strong rounded-full shadow-lg hover:shadow-xl transition-all duration-300 hover:scale-105 flex items-center justify-center group"
  >
    <!-- Light Mode Icon -->
    <svg data-theme-target="lightIcon" class="w-5 h-5 text-amber-500 dark:hidden group-hover:rotate-90 transition-transform duration-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"/>
    </svg>

    <!-- Dark Mode Icon -->
    <svg data-theme-target="darkIcon" class="w-5 h-5 text-purple-400 hidden dark:block group-hover:rotate-12 transition-transform duration-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"/>
    </svg>
  </button>

</div>
```

---

## 4. CSS Specifications

### New Classes to Add

```css
/* Login Switcher Components */
.switcher-pill {
  background: rgba(255, 255, 255, 0.9);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.3);
}

.dark .switcher-pill {
  background: rgba(31, 41, 55, 0.9);
  border: 1px solid rgba(75, 85, 99, 0.3);
}

.switcher-pill:hover {
  background: rgba(255, 255, 255, 0.95);
  border-color: rgba(168, 85, 247, 0.3);
}

.dark .switcher-pill:hover {
  background: rgba(31, 41, 55, 0.95);
  border-color: rgba(168, 85, 247, 0.5);
}

/* Dropdown Menu for Language Switcher */
.dropdown-menu {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.3);
}

.dark .dropdown-menu {
  background: rgba(31, 41, 55, 0.95);
  border: 1px solid rgba(75, 85, 99, 0.3);
}

.dropdown-menu.show {
  opacity: 1;
  transform: scale(1);
  pointer-events: all;
}

/* Reduced Motion Support */
@media (prefers-reduced-motion: reduce) {
  .switcher-pill,
  .dropdown-menu,
  .switcher-pill svg {
    transition: none !important;
    transform: none !important;
  }
}
```

---

## 5. Positioning Strategies

### Fixed vs Absolute

**Recommended: FIXED positioning**
```css
.switchers-container {
  position: fixed;
  top: 1rem;      /* 16px */
  right: 1rem;    /* 16px */
  z-index: 50;
}
```

**Why Fixed?**
- ✅ Always visible regardless of scroll
- ✅ Consistent position across devices
- ✅ Simple implementation
- ✅ No parent positioning concerns

**Responsive Behavior**:
```css
/* Mobile adjustments */
@media (max-width: 640px) {
  .switchers-container {
    top: 0.75rem;    /* 12px - closer to edge */
    right: 0.75rem;  /* 12px - closer to edge */
  }

  .switcher-pill {
    height: 36px;    /* Slightly smaller on mobile */
    font-size: 0.75rem;
  }
}
```

---

## 6. Integration with Stimulus Controllers

### Language Switcher Controller

**File**: `app/javascript/controllers/dropdown_controller.js`

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  toggle(event) {
    event.stopPropagation()
    this.menuTarget.classList.toggle("show")

    // Close on outside click
    if (this.menuTarget.classList.contains("show")) {
      document.addEventListener("click", this.close.bind(this), { once: true })
    }
  }

  close() {
    this.menuTarget.classList.remove("show")
  }
}
```

### Theme Switcher Controller

**File**: `app/javascript/controllers/theme_controller.js` (existing)

**Enhancement Needed**:
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["lightIcon", "darkIcon"]

  connect() {
    this.updateIcons()
  }

  toggle() {
    document.documentElement.classList.toggle("dark")
    this.updateIcons()

    // Save preference
    const isDark = document.documentElement.classList.contains("dark")
    localStorage.setItem("theme", isDark ? "dark" : "light")

    // Optional: Analytics tracking
    this.trackThemeChange(isDark)
  }

  updateIcons() {
    const isDark = document.documentElement.classList.contains("dark")
    // Icons will toggle via CSS (dark:hidden, dark:block)
  }

  trackThemeChange(isDark) {
    if (window.analytics) {
      window.analytics.track("theme_toggled", {
        theme: isDark ? "dark" : "light",
        page: "login"
      })
    }
  }
}
```

---

## 7. Implementation Variants Comparison

| Feature | Minimal Pill | Combined Pill | Icon-Only |
|---------|-------------|---------------|-----------|
| **Width** | ~140px total | ~120px | ~88px |
| **Clarity** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Space Efficiency** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **User Friendliness** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Visual Weight** | Medium | Light | Very Light |
| **Mobile Performance** | Good | Better | Best |
| **Accessibility** | Excellent | Good | Needs tooltips |

**Recommendation**: **Minimal Pill** for best balance of clarity and elegance

---

## 8. Dark Mode Specifications

### Light Mode
```css
.switcher-pill {
  background: rgba(255, 255, 255, 0.9);
  border: 1px solid rgba(255, 255, 255, 0.3);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.switcher-pill:hover {
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.15);
  border-color: rgba(168, 85, 247, 0.3); /* Purple accent */
}
```

### Dark Mode
```css
.dark .switcher-pill {
  background: rgba(31, 41, 55, 0.9);
  border: 1px solid rgba(75, 85, 99, 0.3);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
}

.dark .switcher-pill:hover {
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.4);
  border-color: rgba(168, 85, 247, 0.5);
}
```

### Text Colors
```css
/* Language Text */
.switcher-pill span {
  color: rgb(55, 65, 81);  /* gray-700 */
}

.dark .switcher-pill span {
  color: rgb(243, 244, 246);  /* gray-100 */
}
```

---

## 9. Animation & Interaction Specs

### Hover Effects
```css
/* Scale on hover */
.switcher-pill:hover {
  transform: scale(1.05);
  transition: all 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
}

/* Icon rotation on theme toggle */
.group:hover [data-theme-target="lightIcon"] {
  transform: rotate(90deg);
  transition: transform 0.3s ease-out;
}

.group:hover [data-theme-target="darkIcon"] {
  transform: rotate(12deg);
  transition: transform 0.3s ease-out;
}
```

### Dropdown Animation
```css
.dropdown-menu {
  opacity: 0;
  transform: scale(0.95) translateY(-10px);
  transition: all 0.2s cubic-bezier(0.34, 1.56, 0.64, 1);
}

.dropdown-menu.show {
  opacity: 1;
  transform: scale(1) translateY(0);
}
```

### Focus States (Accessibility)
```css
.switcher-pill:focus-visible {
  outline: 2px solid rgb(168, 85, 247);
  outline-offset: 2px;
  box-shadow: 0 0 0 4px rgba(168, 85, 247, 0.2);
}
```

---

## 10. Component States Checklist

### Language Switcher States
- [x] Default (closed dropdown)
- [x] Hover (scale + glow)
- [x] Active/Open (dropdown visible)
- [x] Selected language indicator (checkmark)
- [x] Dark mode variant
- [x] Focus visible (keyboard navigation)
- [x] Disabled (N/A - always available)

### Theme Switcher States
- [x] Light mode (sun icon visible)
- [x] Dark mode (moon icon visible)
- [x] Hover (icon rotation)
- [x] Active/Pressed (momentary scale down)
- [x] Dark mode variant
- [x] Focus visible
- [x] Transition animation

---

## 11. Accessibility Considerations

### Keyboard Navigation
```erb
<!-- Ensure tab order -->
<div class="fixed top-4 right-4 z-50 flex items-center gap-2">

  <!-- Language: Tab stop 1 -->
  <button type="button" aria-label="Change language" aria-haspopup="true" aria-expanded="false">
    <!-- ... -->
  </button>

  <!-- Theme: Tab stop 2 -->
  <button type="button" aria-label="Toggle dark mode">
    <!-- ... -->
  </button>

</div>
```

### Screen Reader Support
```erb
<!-- Language Switcher -->
<button
  type="button"
  aria-label="<%= t('accessibility.change_language') %>"
  aria-haspopup="true"
  aria-expanded="false"
  data-action="click->dropdown#toggle"
>
  <!-- ... -->
</button>

<!-- Theme Switcher -->
<button
  type="button"
  aria-label="<%= t('accessibility.toggle_theme') %>"
  data-controller="theme"
  data-action="click->theme#toggle"
>
  <!-- ... -->
</button>
```

### ARIA Labels Needed
```yaml
# config/locales/en.yml
en:
  accessibility:
    change_language: "Change language"
    toggle_theme: "Toggle dark mode"
    current_language: "Current language: %{language}"
    light_mode: "Switch to light mode"
    dark_mode: "Switch to dark mode"
```

---

## 12. i18n Integration

### Required Translations

**English** (`config/locales/en.yml`):
```yaml
en:
  auth:
    switchers:
      language: "Language"
      theme: "Theme"
      light_mode: "Light"
      dark_mode: "Dark"
```

**Portuguese** (`config/locales/pt-BR.yml`):
```yaml
pt-BR:
  auth:
    switchers:
      language: "Idioma"
      theme: "Tema"
      light_mode: "Claro"
      dark_mode: "Escuro"
```

---

## 13. Implementation Checklist

### Phase 1: HTML Structure
- [ ] Add switchers container to `auth.html.erb` layout
- [ ] Implement language switcher with dropdown
- [ ] Implement theme switcher button
- [ ] Add proper semantic HTML and ARIA attributes
- [ ] Test keyboard navigation

### Phase 2: CSS Styling
- [ ] Add `.switcher-pill` class to application.css
- [ ] Implement glass morphism effects
- [ ] Add hover animations
- [ ] Add dropdown menu styles
- [ ] Test dark mode styling
- [ ] Add responsive mobile styles
- [ ] Add reduced motion support

### Phase 3: JavaScript Integration
- [ ] Create/enhance `dropdown_controller.js`
- [ ] Enhance `theme_controller.js` with icon targets
- [ ] Add localStorage persistence for theme
- [ ] Add outside-click handling for dropdown
- [ ] Add analytics tracking (optional)
- [ ] Test all interactions

### Phase 4: Accessibility
- [ ] Add ARIA labels and attributes
- [ ] Add i18n translations for labels
- [ ] Test keyboard navigation (Tab, Enter, Escape)
- [ ] Test screen reader compatibility
- [ ] Add focus-visible styles
- [ ] Test with VoiceOver/NVDA

### Phase 5: Testing
- [ ] Test on Chrome, Firefox, Safari
- [ ] Test on mobile devices (iOS/Android)
- [ ] Test dark/light mode transitions
- [ ] Test language switching
- [ ] Test with slow 3G connection
- [ ] Test with JavaScript disabled (graceful degradation)
- [ ] Verify no interference with login flow

### Phase 6: Polish
- [ ] Fine-tune animation timing
- [ ] Optimize z-index layering
- [ ] Add subtle glow on interaction
- [ ] Ensure proper spacing on all screen sizes
- [ ] Add tooltip for icon-only variant (if used)
- [ ] Performance check (no layout shifts)

---

## 14. Edge Cases & Considerations

### Mobile Responsiveness
```css
/* Ensure switchers don't overlap with page content */
@media (max-width: 640px) {
  .auth-container {
    padding-top: 4rem; /* Space for switchers */
  }
}
```

### Long Language Names
```css
/* Prevent text overflow */
.dropdown-menu a {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
```

### Z-Index Management
```
z-index hierarchy:
- Switchers container: 50
- Dropdown menu: 51
- Login card: auto (default)
```

### Browser Support
- ✅ Chrome/Edge: Full support
- ✅ Firefox: Full support
- ✅ Safari: Full support (with -webkit- prefix for backdrop-filter)
- ⚠️ IE11: Fallback to solid background (no glass effect)

---

## 15. Alternative Approaches Considered

### A. Top Navigation Bar
**Rejected**: Would change auth layout significantly, adds visual weight

### B. Bottom-Right Corner
**Rejected**: Too far from expected location for settings

### C. Inside Login Card
**Rejected**: Clutters primary action area, reduces focus on login

### D. Dropdown from Avatar/Icon
**Rejected**: No avatar/profile context on login page

### E. **TOP-RIGHT CORNER** ✅
**Selected**: Standard location, non-intrusive, elegant, expected

---

## 16. Success Metrics

### User Experience
- ✅ No impact on login conversion rate
- ✅ <3 seconds to understand switcher function
- ✅ Smooth animations (60fps)
- ✅ Works on all screen sizes

### Technical
- ✅ Zero layout shift (CLS)
- ✅ <50ms interaction delay
- ✅ 100% keyboard accessible
- ✅ AA WCAG contrast compliance

### Visual
- ✅ Matches design system aesthetics
- ✅ Glass morphism renders properly
- ✅ Dark mode parity with light mode
- ✅ No visual conflicts with login card

---

## 17. File Paths Reference

### Views
```
app/views/layouts/auth.html.erb          # Add switchers here
app/views/devise/sessions/new.html.erb   # Login page (no changes needed)
```

### Stylesheets
```
app/assets/stylesheets/application.css   # Add switcher CSS classes
```

### JavaScript
```
app/javascript/controllers/dropdown_controller.js  # New controller
app/javascript/controllers/theme_controller.js     # Enhance existing
```

### Locales
```
config/locales/en.yml                    # Add switcher translations
config/locales/pt-BR.yml                 # Add switcher translations
```

---

## 18. Developer Notes

### CSS Class Naming Convention
- Use `switcher-*` prefix for switcher-specific classes
- Follow existing Wishare naming patterns
- Keep Tailwind utility classes inline for flexibility

### Stimulus Controller Pattern
```javascript
// Naming: kebab-case for HTML, camelCase for JS
data-controller="dropdown"     // HTML
import DropdownController      // JS
```

### Testing Approach
```ruby
# Feature spec for language switcher
it "changes locale when language is selected" do
  visit new_user_session_path
  click_button "EN"
  click_link "Português"
  expect(page).to have_current_path("/pt-BR/users/sign_in")
end
```

---

## 19. Quick Implementation Summary

**RECOMMENDED APPROACH: Minimal Pill Variant**

1. **Add to `auth.html.erb` layout** before `<%= yield %>`
2. **Create CSS** in `application.css` with `.switcher-pill` class
3. **Create/enhance Stimulus controllers** for dropdown and theme
4. **Add i18n translations** for accessibility labels
5. **Test** across browsers and devices
6. **Deploy** with confidence - no breaking changes

**Estimated Implementation Time**: 2-3 hours
**Complexity**: Low-Medium
**Risk**: Minimal (non-intrusive addition)

---

## 20. Final Recommendations

### DO
✅ Use **Minimal Pill** variant for best UX
✅ Match glass morphism of login card
✅ Add smooth transitions (0.3s)
✅ Include ARIA labels for accessibility
✅ Test dark mode thoroughly
✅ Ensure mobile responsiveness
✅ Use existing Stimulus patterns
✅ Keep z-index minimal (50-51)

### DON'T
❌ Don't make switchers too large
❌ Don't add complex animations
❌ Don't interfere with login flow
❌ Don't forget keyboard navigation
❌ Don't skip i18n translations
❌ Don't break existing theme controller
❌ Don't add unnecessary JavaScript
❌ Don't forget reduced motion support

---

**Ready for Implementation**: This specification provides complete guidance for building elegant, accessible language and theme switchers for the Wishare login page while maintaining the clean, modern aesthetic of the existing design system.

**Next Step**: Begin implementation with Phase 1 (HTML Structure) and iterate through the checklist systematically.
