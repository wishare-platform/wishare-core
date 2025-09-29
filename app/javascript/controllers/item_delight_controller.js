import { Controller } from "@hotwired/stimulus"

// Item Delight Controller - Creating engaging moments for wishlist item pages
export default class extends Controller {
  static targets = [
    "breadcrumb", "mainCard", "itemTitle", "itemEmoji", "wishBadge",
    "statCard", "viewCount", "heartCount", "heartIcon", "popularityIcon",
    "purchaseButton", "shareButton", "shareConfetti", "purchaseSuccess"
  ]
  static values = {
    itemName: String,
    wishlistName: String,
    isPurchased: Boolean
  }

  connect() {
    this.initializeDelightMoments()
    this.trackPageView()
    this.createCelebrationElements()
    this.addItemAppearanceAnimation()
    this.checkForSpecialMoments()
  }

  disconnect() {
    if (this.heartBeatInterval) {
      clearInterval(this.heartBeatInterval)
    }
  }

  initializeDelightMoments() {
    // Add subtle emoji pulse every 8 seconds
    setInterval(() => {
      if (this.hasItemEmojiTarget) {
        this.itemEmojiTarget.classList.add('animate-pulse')
        setTimeout(() => {
          this.itemEmojiTarget.classList.remove('animate-pulse')
        }, 1000)
      }
    }, 8000)

    // Add floating sparkles occasionally
    setInterval(() => {
      this.createFloatingSparkles()
    }, 15000)
  }

  trackPageView() {
    // Simulate incrementing view count with animation
    if (this.hasViewCountTarget) {
      setTimeout(() => {
        const currentCount = parseInt(this.viewCountTarget.textContent)
        this.viewCountTarget.textContent = currentCount + 1
        this.animateNumberIncrement(this.viewCountTarget)
      }, 2000)
    }
  }

  createCelebrationElements() {
    // Create floating elements container
    this.floatingContainer = document.createElement('div')
    this.floatingContainer.className = 'fixed inset-0 pointer-events-none z-40'
    document.body.appendChild(this.floatingContainer)
  }

  addItemAppearanceAnimation() {
    // Animate item entry
    if (this.hasMainCardTarget) {
      this.mainCardTarget.style.opacity = '0'
      this.mainCardTarget.style.transform = 'translateY(20px)'

      setTimeout(() => {
        this.mainCardTarget.style.transition = 'all 0.6s cubic-bezier(0.25, 0.46, 0.45, 0.94)'
        this.mainCardTarget.style.opacity = '1'
        this.mainCardTarget.style.transform = 'translateY(0)'
      }, 100)
    }

    // Stagger animation for stat cards
    this.statCardTargets.forEach((card, index) => {
      card.style.opacity = '0'
      card.style.transform = 'translateY(10px)'

      setTimeout(() => {
        card.style.transition = 'all 0.4s ease-out'
        card.style.opacity = '1'
        card.style.transform = 'translateY(0)'
      }, 200 + (index * 100))
    })
  }

  checkForSpecialMoments() {
    // Check if item is getting lots of attention
    const viewCount = this.hasViewCountTarget ? parseInt(this.viewCountTarget.textContent) : 0
    const heartCount = this.hasHeartCountTarget ? parseInt(this.heartCountTarget.textContent) : 0

    if (viewCount > 20) {
      setTimeout(() => {
        this.showPopularityBurst()
      }, 3000)
    }

    if (heartCount > 2) {
      this.startHeartBeat()
    }
  }

  // Event handlers
  onBreadcrumbHover(event) {
    const breadcrumb = event.currentTarget
    this.addTrailSparkles(breadcrumb)
  }

  onBreadcrumbLeave(event) {
    // Subtle bounce back
    const breadcrumb = event.currentTarget
    breadcrumb.style.transform = 'scale(1)'
  }

  onCardHover(event) {
    const card = event.currentTarget
    // Enhanced glow effect
    card.style.boxShadow = '0 25px 50px rgba(236, 72, 153, 0.2), 0 0 0 1px rgba(236, 72, 153, 0.1)'

    // Subtle emoji bounce
    if (this.hasItemEmojiTarget) {
      this.itemEmojiTarget.style.transform = 'scale(1.1) rotate(5deg)'
    }
  }

  onCardLeave(event) {
    const card = event.currentTarget
    card.style.boxShadow = ''

    if (this.hasItemEmojiTarget) {
      this.itemEmojiTarget.style.transform = 'scale(1) rotate(0deg)'
    }
  }

  onStatClick(event) {
    const card = event.currentTarget
    const statType = card.dataset.statType

    // Create ripple effect
    this.createRippleEffect(event, card)

    // Type-specific celebrations
    switch (statType) {
      case 'views':
        this.celebrateViews()
        break
      case 'hearts':
        this.celebrateHearts()
        break
      case 'popularity':
        this.celebratePopularity()
        break
    }

    // Add to wishlist badge if hearts clicked
    if (statType === 'hearts' && this.hasWishBadgeTarget) {
      this.showWishBadge()
    }
  }

  onPurchaseClick(event) {
    const button = event.currentTarget

    // Prevent double-click
    button.style.pointerEvents = 'none'

    // Epic celebration sequence
    this.createPurchaseCelebration()

    // Button animation
    button.style.transform = 'scale(0.95)'
    setTimeout(() => {
      button.style.transform = 'scale(1)'
      button.style.pointerEvents = 'auto'
    }, 200)

    // Add haptic feedback
    if ('vibrate' in navigator) {
      navigator.vibrate([100, 50, 200, 50, 300])
    }
  }

  onShareClick(event) {
    event.preventDefault()

    // Share celebration
    this.createShareCelebration()

    // Simulate native share or copy link
    if (navigator.share) {
      navigator.share({
        title: `${this.itemNameValue} - ${this.wishlistNameValue}`,
        text: `Check out this amazing item I found on Wishare!`,
        url: window.location.href
      }).catch(() => {
        this.copyToClipboard()
      })
    } else {
      this.copyToClipboard()
    }
  }

  // Celebration methods
  celebrateViews() {
    // Eye sparkles
    const eyes = ['👀', '👁️', '🔍', '✨']
    this.createFloatingElements(eyes, 'from-blue-400 to-cyan-400')
  }

  celebrateHearts() {
    // Heart explosion
    const hearts = ['💖', '💕', '💗', '❤️', '💝']
    this.createFloatingElements(hearts, 'from-pink-400 to-rose-400')

    // Animate heart icon
    if (this.hasHeartIconTarget) {
      this.heartIconTarget.style.transform = 'scale(1.3)'
      this.heartIconTarget.style.fill = 'currentColor'
      setTimeout(() => {
        this.heartIconTarget.style.transform = 'scale(1)'
        this.heartIconTarget.style.fill = 'none'
      }, 300)
    }
  }

  celebratePopularity() {
    // Star burst
    const stars = ['⭐', '🌟', '✨', '💫', '🎇']
    this.createFloatingElements(stars, 'from-purple-400 to-pink-400')

    // Popularity icon spin
    if (this.hasPopularityIconTarget) {
      this.popularityIconTarget.style.transform = 'rotate(360deg) scale(1.2)'
      setTimeout(() => {
        this.popularityIconTarget.style.transform = 'rotate(0deg) scale(1)'
      }, 500)
    }
  }

  createPurchaseCelebration() {
    // Multi-stage celebration
    // Stage 1: Confetti burst
    this.createConfettiBurst()

    // Stage 2: Success message (after 500ms)
    setTimeout(() => {
      this.showPurchaseSuccessMessage()
    }, 500)

    // Stage 3: Floating celebration emojis (after 1s)
    setTimeout(() => {
      const celebration = ['🎉', '🥳', '🎊', '🎁', '🛍️']
      this.createFloatingElements(celebration, 'from-green-400 to-emerald-400', 8)
    }, 1000)
  }

  createShareCelebration() {
    // Social media inspired celebration
    const social = ['📱', '📢', '📤', '🔗', '✨']
    this.createFloatingElements(social, 'from-blue-400 to-purple-400')

    // Create share ripple
    const shareButton = this.shareButtonTarget
    this.createSpecialRipple(shareButton, 'rgba(59, 130, 246, 0.4)')
  }

  // Utility methods
  createRippleEffect(event, element) {
    const rect = element.getBoundingClientRect()
    const size = Math.max(rect.width, rect.height) * 1.5
    const x = event.clientX - rect.left - size / 2
    const y = event.clientY - rect.top - size / 2

    const ripple = document.createElement('div')
    ripple.style.cssText = `
      position: absolute;
      border-radius: 50%;
      background: rgba(236, 72, 153, 0.3);
      transform: scale(0);
      animation: itemRipple 0.6s ease-out;
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

  createSpecialRipple(element, color) {
    const ripple = document.createElement('div')
    ripple.className = 'absolute inset-0 rounded-xl scale-0'
    ripple.style.background = color
    ripple.style.animation = 'pulse 0.4s ease-out'

    element.style.position = 'relative'
    element.appendChild(ripple)

    setTimeout(() => {
      ripple.remove()
    }, 400)
  }

  createFloatingElements(elements, gradientColors, count = 5) {
    for (let i = 0; i < count; i++) {
      const element = document.createElement('div')
      element.innerHTML = elements[Math.floor(Math.random() * elements.length)]
      element.className = 'fixed pointer-events-none z-50 text-2xl'

      // Random position around the clicked area
      const x = Math.random() * window.innerWidth
      const y = window.innerHeight - Math.random() * 200

      element.style.left = x + 'px'
      element.style.top = y + 'px'

      this.floatingContainer.appendChild(element)

      // Animate upward and fade
      setTimeout(() => {
        element.style.transition = 'all 2s cubic-bezier(0.25, 0.46, 0.45, 0.94)'
        element.style.transform = `translateY(-${200 + Math.random() * 100}px) rotate(${Math.random() * 360}deg)`
        element.style.opacity = '0'
        element.style.scale = '0.5'
      }, 50)

      // Remove element
      setTimeout(() => {
        element.remove()
      }, 2100)
    }
  }

  createFloatingSparkles() {
    const sparkles = ['✨', '💫', '⭐']
    this.createFloatingElements(sparkles, 'from-yellow-400 to-amber-400', 2)
  }

  createConfettiBurst() {
    const colors = ['#EC4899', '#F59E0B', '#8B5CF6', '#EF4444', '#10B981', '#3B82F6']
    const confettiContainer = document.createElement('div')
    confettiContainer.className = 'fixed inset-0 pointer-events-none z-50'
    document.body.appendChild(confettiContainer)

    // Create multiple confetti pieces
    for (let i = 0; i < 30; i++) {
      const confetti = document.createElement('div')
      confetti.style.cssText = `
        position: absolute;
        width: 8px;
        height: 8px;
        background: ${colors[Math.floor(Math.random() * colors.length)]};
        left: 50%;
        top: 50%;
        animation: confettiFall ${1 + Math.random()}s ease-out forwards;
        animation-delay: ${Math.random() * 0.5}s;
      `
      confettiContainer.appendChild(confetti)
    }

    // Clean up
    setTimeout(() => {
      confettiContainer.remove()
    }, 2000)
  }

  showPurchaseSuccessMessage() {
    const message = document.createElement('div')
    message.className = 'fixed top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 bg-gradient-to-r from-green-500 to-emerald-500 text-white px-8 py-4 rounded-2xl shadow-2xl z-50 text-center font-bold text-lg'
    message.innerHTML = `
      <div class="flex items-center gap-3">
        <span class="text-2xl">🎉</span>
        <div>
          <div>Purchase Confirmed!</div>
          <div class="text-sm opacity-90 font-normal">Thank you for your purchase</div>
        </div>
        <span class="text-2xl">🎁</span>
      </div>
    `

    document.body.appendChild(message)

    // Animate in
    message.style.opacity = '0'
    message.style.transform = 'translate(-50%, -50%) scale(0.8)'
    setTimeout(() => {
      message.style.transition = 'all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94)'
      message.style.opacity = '1'
      message.style.transform = 'translate(-50%, -50%) scale(1)'
    }, 50)

    // Auto dismiss
    setTimeout(() => {
      message.style.opacity = '0'
      message.style.transform = 'translate(-50%, -50%) scale(0.8)'
      setTimeout(() => {
        message.remove()
      }, 300)
    }, 2000)
  }

  showWishBadge() {
    if (this.hasWishBadgeTarget) {
      this.wishBadgeTarget.classList.remove('hidden')
      setTimeout(() => {
        this.wishBadgeTarget.classList.add('hidden')
      }, 3000)
    }
  }

  startHeartBeat() {
    if (this.heartBeatInterval) return

    this.heartBeatInterval = setInterval(() => {
      if (this.hasHeartIconTarget) {
        this.heartIconTarget.style.transform = 'scale(1.1)'
        setTimeout(() => {
          this.heartIconTarget.style.transform = 'scale(1)'
        }, 150)
      }
    }, 2000)
  }

  showPopularityBurst() {
    // Show trending notification
    const notification = document.createElement('div')
    notification.className = 'fixed top-4 right-4 bg-gradient-to-r from-purple-500 to-pink-500 text-white p-4 rounded-xl shadow-xl z-50 transform translate-x-full transition-transform duration-300'
    notification.innerHTML = `
      <div class="flex items-center gap-3">
        <span class="text-2xl">🔥</span>
        <div>
          <div class="font-bold">Trending Item!</div>
          <div class="text-sm opacity-90">This item is getting lots of attention</div>
        </div>
      </div>
    `

    document.body.appendChild(notification)

    // Slide in
    setTimeout(() => {
      notification.classList.remove('translate-x-full')
    }, 100)

    // Auto dismiss
    setTimeout(() => {
      notification.classList.add('translate-x-full')
      setTimeout(() => {
        notification.remove()
      }, 300)
    }, 4000)
  }

  addTrailSparkles(element) {
    const rect = element.getBoundingClientRect()
    const sparkle = document.createElement('div')
    sparkle.innerHTML = '✨'
    sparkle.className = 'fixed pointer-events-none z-40 text-sm animate-ping'
    sparkle.style.left = (rect.right - 10) + 'px'
    sparkle.style.top = (rect.top + rect.height / 2) + 'px'

    document.body.appendChild(sparkle)

    setTimeout(() => {
      sparkle.remove()
    }, 1000)
  }

  animateNumberIncrement(element) {
    element.style.transform = 'scale(1.2)'
    element.style.color = '#10B981'
    element.style.fontWeight = 'bold'

    setTimeout(() => {
      element.style.transform = 'scale(1)'
      element.style.color = ''
      element.style.fontWeight = ''
    }, 400)
  }

  copyToClipboard() {
    navigator.clipboard.writeText(window.location.href).then(() => {
      // Show copy success
      const toast = document.createElement('div')
      toast.className = 'fixed bottom-4 left-1/2 transform -translate-x-1/2 bg-gray-800 text-white px-4 py-2 rounded-lg text-sm z-50'
      toast.textContent = 'Link copied to clipboard!'

      document.body.appendChild(toast)

      setTimeout(() => {
        toast.remove()
      }, 2000)
    })
  }
}

// Add required CSS animations
const style = document.createElement('style')
style.textContent = `
  @keyframes itemRipple {
    to {
      transform: scale(4);
      opacity: 0;
    }
  }

  @keyframes confettiFall {
    0% {
      transform: translate(-50%, -50%) rotate(0deg) scale(1);
      opacity: 1;
    }
    100% {
      transform: translate(
        calc(-50% + ${Math.random() * 400 - 200}px),
        calc(-50% + 300px)
      ) rotate(720deg) scale(0);
      opacity: 0;
    }
  }

  .animate-heartbeat {
    animation: heartbeat 1s ease-in-out infinite;
  }

  @keyframes heartbeat {
    0%, 100% { transform: scale(1); }
    50% { transform: scale(1.1); }
  }
`
document.head.appendChild(style)</style>