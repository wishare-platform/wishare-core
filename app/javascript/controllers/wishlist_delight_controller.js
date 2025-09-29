import { Controller } from "@hotwired/stimulus"
import { useIntersection, useWindowResize, useTimeout, useDebounce } from "stimulus-use"

// Wishlist Delight Controller - Enhanced with stimulus-use for advanced micro-interactions
export default class extends Controller {
  static targets = [
    "headerContent", "titleEmoji", "celebrationBadge", "createButton",
    "wishlistCard", "cardEmoji", "confettiCanvas", "achievementModal"
  ]
  static values = {
    celebrationReady: Boolean
  }

  connect() {
    // Initialize stimulus-use composables
    useIntersection(this, { threshold: 0.1 })
    useWindowResize(this)
    useTimeout(this)
    useDebounce(this)

    this.initializeDelightfulMoments()
    this.setupAchievementTracking()
    this.createConfettiCanvas()
    this.addTitlePulse()
    this.checkForCelebrationMoments()
  }

  // Intersection Observer callback - triggered when cards come into view
  appear(entry) {
    this.animateCardsOnScroll()
  }

  disappear(entry) {
    // Optional: fade out animation when leaving viewport
  }

  // Window resize callback
  resize({ width, height }) {
    // Recalculate confetti canvas size
    if (this.confettiCanvas) {
      this.confettiCanvas.width = width
      this.confettiCanvas.height = height
    }
  }

  // Enhanced card animation when scrolling into view
  animateCardsOnScroll() {
    this.wishlistCardTargets.forEach((card, index) => {
      setTimeout(() => {
        card.style.opacity = '1'
        card.style.transform = 'translateY(0) scale(1)'
        card.style.transition = 'all 0.6s cubic-bezier(0.175, 0.885, 0.32, 1.275)'
      }, index * 100)
    })
  }

  disconnect() {
    if (this.confettiCanvas) {
      this.confettiCanvas.remove()
    }
    if (this.achievementTimer) {
      clearTimeout(this.achievementTimer)
    }
  }

  initializeDelightfulMoments() {
    // Add subtle "bounce" to title emoji every 10 seconds
    setInterval(() => {
      if (this.hasTitleEmojiTarget) {
        this.titleEmojiTarget.classList.add('animate-bounce')
        setTimeout(() => {
          this.titleEmojiTarget.classList.remove('animate-bounce')
        }, 1000)
      }
    }, 10000)

    // Add floating hearts on page load if user has wishlists
    const cards = this.wishlistCardTargets
    if (cards.length > 0) {
      setTimeout(() => {
        this.showFloatingHearts()
      }, 1000)
    }
  }

  setupAchievementTracking() {
    this.achievements = {
      'first_wishlist': { unlocked: false, title: '🎯 First Wish!', message: 'You created your very first wishlist!' },
      'wish_collector': { unlocked: false, title: '📚 Wish Collector', message: 'Amazing! You have 5+ wishlists!' },
      'birthday_planner': { unlocked: false, title: '🎂 Birthday Planner', message: 'Perfect timing for birthday planning!' },
      'wishlist_explorer': { unlocked: false, title: '🔍 Wishlist Explorer', message: 'You love discovering new wishlists!' }
    }
  }

  createConfettiCanvas() {
    // Create hidden canvas for confetti celebrations
    this.confettiCanvas = document.createElement('canvas')
    this.confettiCanvas.className = 'fixed inset-0 pointer-events-none z-50 hidden'
    this.confettiCanvas.width = window.innerWidth
    this.confettiCanvas.height = window.innerHeight
    document.body.appendChild(this.confettiCanvas)
    this.confettiCtx = this.confettiCanvas.getContext('2d')
  }

  addTitlePulse() {
    // Add subtle pulse to main title when cards are loaded
    if (this.hasHeaderContentTarget) {
      setTimeout(() => {
        this.headerContentTarget.classList.add('animate-pulse')
        setTimeout(() => {
          this.headerContentTarget.classList.remove('animate-pulse')
        }, 2000)
      }, 500)
    }
  }

  checkForCelebrationMoments() {
    const cards = this.wishlistCardTargets
    const count = cards.length

    // Check achievements based on wishlists count
    if (count === 1) {
      this.triggerAchievement('first_wishlist')
    } else if (count >= 5) {
      this.triggerAchievement('wish_collector')
    }

    // Check for birthday wishlists
    const hasBirthdayWishlist = cards.some(card => {
      return card.innerHTML.includes('🎂') || card.innerHTML.includes('birthday')
    })
    if (hasBirthdayWishlist) {
      this.triggerAchievement('birthday_planner')
    }
  }

  triggerAchievement(achievementKey) {
    const achievement = this.achievements[achievementKey]
    if (!achievement || achievement.unlocked) return

    achievement.unlocked = true

    // Show confetti burst
    this.showConfetti()

    // Show achievement notification
    setTimeout(() => {
      this.showAchievementNotification(achievement)
    }, 500)

    // Add haptic feedback if available
    if ('vibrate' in navigator) {
      navigator.vibrate([100, 50, 100])
    }
  }

  showAchievementNotification(achievement) {
    const notification = document.createElement('div')
    notification.className = 'fixed top-4 right-4 bg-gradient-to-r from-purple-500 to-pink-500 text-white p-4 rounded-xl shadow-xl z-50 max-w-sm transform translate-x-full transition-transform duration-300'
    notification.innerHTML = `
      <div class="flex items-start gap-3">
        <div class="text-2xl">${achievement.title.split(' ')[0]}</div>
        <div class="flex-1">
          <div class="font-bold text-lg">${achievement.title.substring(2)}</div>
          <div class="text-sm opacity-90">${achievement.message}</div>
          <div class="text-xs opacity-75 mt-1">Tap to dismiss</div>
        </div>
      </div>
    `

    document.body.appendChild(notification)

    // Slide in
    setTimeout(() => {
      notification.classList.remove('translate-x-full')
    }, 100)

    // Auto-dismiss after 5 seconds
    setTimeout(() => {
      this.dismissNotification(notification)
    }, 5000)

    // Click to dismiss
    notification.addEventListener('click', () => {
      this.dismissNotification(notification)
    })
  }

  dismissNotification(notification) {
    notification.classList.add('translate-x-full')
    setTimeout(() => {
      notification.remove()
    }, 300)
  }

  showConfetti() {
    this.confettiCanvas.classList.remove('hidden')

    const particles = []
    const colors = ['#EC4899', '#F59E0B', '#8B5CF6', '#EF4444', '#10B981']

    // Create confetti particles
    for (let i = 0; i < 50; i++) {
      particles.push({
        x: Math.random() * this.confettiCanvas.width,
        y: -10,
        vx: (Math.random() - 0.5) * 10,
        vy: Math.random() * 5 + 2,
        color: colors[Math.floor(Math.random() * colors.length)],
        size: Math.random() * 6 + 4,
        life: 100
      })
    }

    const animate = () => {
      this.confettiCtx.clearRect(0, 0, this.confettiCanvas.width, this.confettiCanvas.height)

      for (let i = particles.length - 1; i >= 0; i--) {
        const p = particles[i]

        p.x += p.vx
        p.y += p.vy
        p.vy += 0.1 // gravity
        p.life--

        this.confettiCtx.save()
        this.confettiCtx.globalAlpha = p.life / 100
        this.confettiCtx.fillStyle = p.color
        this.confettiCtx.fillRect(p.x, p.y, p.size, p.size)
        this.confettiCtx.restore()

        if (p.life <= 0 || p.y > this.confettiCanvas.height) {
          particles.splice(i, 1)
        }
      }

      if (particles.length > 0) {
        requestAnimationFrame(animate)
      } else {
        this.confettiCanvas.classList.add('hidden')
      }
    }

    animate()
  }

  showFloatingHearts() {
    // Create floating hearts as subtle celebration
    for (let i = 0; i < 3; i++) {
      setTimeout(() => {
        const heart = document.createElement('div')
        heart.innerHTML = '💖'
        heart.className = 'fixed text-2xl pointer-events-none z-40 animate-bounce'
        heart.style.left = Math.random() * window.innerWidth + 'px'
        heart.style.top = window.innerHeight + 'px'
        heart.style.animationDuration = '2s'

        document.body.appendChild(heart)

        // Float up and fade out
        setTimeout(() => {
          heart.style.transition = 'transform 3s ease-out, opacity 3s ease-out'
          heart.style.transform = 'translateY(-' + (window.innerHeight + 100) + 'px)'
          heart.style.opacity = '0'
        }, 100)

        // Remove element
        setTimeout(() => {
          heart.remove()
        }, 3200)
      }, i * 500)
    }
  }

  // Event handlers for card interactions
  onCardHover(event) {
    const card = event.currentTarget
    const emoji = card.querySelector('[data-wishlist-delight-target="cardEmoji"]')

    if (emoji) {
      emoji.style.transform = 'scale(1.2) rotate(10deg)'
      emoji.style.transition = 'transform 0.2s ease'
    }

    // Add subtle glow effect
    card.style.boxShadow = '0 20px 40px rgba(236, 72, 153, 0.15)'
  }

  onCardLeave(event) {
    const card = event.currentTarget
    const emoji = card.querySelector('[data-wishlist-delight-target="cardEmoji"]')

    if (emoji) {
      emoji.style.transform = 'scale(1) rotate(0deg)'
    }

    // Reset glow
    card.style.boxShadow = ''
  }

  onCardClick(event) {
    const card = event.currentTarget
    const wishlistName = card.dataset.wishlistName

    // Add ripple effect
    this.createRippleEffect(event, card)

    // Track exploration achievement
    this.trackWishlistExploration()

    // Add click celebration particles
    this.createClickParticles(event)
  }

  createRippleEffect(event, element) {
    const rect = element.getBoundingClientRect()
    const size = Math.max(rect.width, rect.height)
    const x = event.clientX - rect.left - size / 2
    const y = event.clientY - rect.top - size / 2

    const ripple = document.createElement('div')
    ripple.style.cssText = `
      position: absolute;
      border-radius: 50%;
      background: rgba(236, 72, 153, 0.3);
      transform: scale(0);
      animation: ripple 0.6s linear;
      left: ${x}px;
      top: ${y}px;
      width: ${size}px;
      height: ${size}px;
      pointer-events: none;
    `

    element.style.position = 'relative'
    element.style.overflow = 'hidden'
    element.appendChild(ripple)

    setTimeout(() => {
      ripple.remove()
    }, 600)
  }

  createClickParticles(event) {
    const colors = ['✨', '💫', '⭐', '🌟']

    for (let i = 0; i < 5; i++) {
      const particle = document.createElement('div')
      particle.innerHTML = colors[Math.floor(Math.random() * colors.length)]
      particle.className = 'fixed pointer-events-none z-40 text-lg'
      particle.style.left = event.clientX + 'px'
      particle.style.top = event.clientY + 'px'

      document.body.appendChild(particle)

      // Animate particle
      const angle = (Math.PI * 2 * i) / 5
      const distance = 50
      const x = Math.cos(angle) * distance
      const y = Math.sin(angle) * distance

      setTimeout(() => {
        particle.style.transition = 'all 0.8s cubic-bezier(0.25, 0.46, 0.45, 0.94)'
        particle.style.transform = `translate(${x}px, ${y}px) scale(0)`
        particle.style.opacity = '0'
      }, 50)

      setTimeout(() => {
        particle.remove()
      }, 850)
    }
  }

  trackWishlistExploration() {
    if (!this.explorationCount) this.explorationCount = 0
    this.explorationCount++

    if (this.explorationCount >= 3) {
      this.triggerAchievement('wishlist_explorer')
    }
  }

  // Button interaction handlers
  highlightCreateButton(event) {
    const button = event.currentTarget
    button.style.transform = 'scale(1.05) rotate(1deg)'
    button.style.boxShadow = '0 10px 30px rgba(236, 72, 153, 0.4)'

    // Add sparkle effect around button
    this.addSparklesAroundElement(button)
  }

  resetCreateButton(event) {
    const button = event.currentTarget
    button.style.transform = 'scale(1) rotate(0deg)'
    button.style.boxShadow = ''
  }

  addSparklesAroundElement(element) {
    const rect = element.getBoundingClientRect()
    const sparkles = ['✨', '⭐', '💫']

    for (let i = 0; i < 3; i++) {
      const sparkle = document.createElement('div')
      sparkle.innerHTML = sparkles[i]
      sparkle.className = 'fixed pointer-events-none z-40 text-sm animate-ping'
      sparkle.style.left = (rect.left + Math.random() * rect.width) + 'px'
      sparkle.style.top = (rect.top + Math.random() * rect.height) + 'px'

      document.body.appendChild(sparkle)

      setTimeout(() => {
        sparkle.remove()
      }, 1000)
    }
  }

  // Analytics tracking with celebration
  trackView(event) {
    // Add viewing celebration
    const button = event.currentTarget
    button.style.transform = 'scale(0.95)'
    setTimeout(() => {
      button.style.transform = 'scale(1)'
    }, 150)
  }

  trackAddItem(event) {
    // Add special effect for add item
    const button = event.currentTarget
    this.createSuccessRipple(button)
  }

  createSuccessRipple(element) {
    const ripple = document.createElement('div')
    ripple.className = 'absolute inset-0 bg-gradient-to-r from-green-400 to-blue-400 opacity-25 rounded-xl scale-0'
    ripple.style.animation = 'pulse 0.4s ease-out'

    element.style.position = 'relative'
    element.appendChild(ripple)

    setTimeout(() => {
      ripple.remove()
    }, 400)
  }
}

// Add required CSS animations
const style = document.createElement('style')
style.textContent = `
  @keyframes ripple {
    to {
      transform: scale(4);
      opacity: 0;
    }
  }

  @keyframes sparkle {
    0%, 100% {
      opacity: 0;
      transform: scale(0);
    }
    50% {
      opacity: 1;
      transform: scale(1);
    }
  }

  .animate-sparkle {
    animation: sparkle 0.6s ease-in-out;
  }
`
document.head.appendChild(style)