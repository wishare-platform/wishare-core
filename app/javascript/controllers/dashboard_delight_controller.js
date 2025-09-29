import { Controller } from "@hotwired/stimulus"

// Dashboard Delight Controller - Creating magical moments for the main dashboard experience
export default class extends Controller {
  static targets = [
    "profileCard", "profileAvatar", "progressRing", "statsCard", "quickAction",
    "friendCard", "activityItem", "eventCard", "celebrationCanvas",
    "welcomeMessage", "achievementBadge", "notificationDot", "actionButton"
  ]
  static values = {
    userName: String,
    profileCompletion: Number,
    friendsCount: Number,
    wishlistsCount: Number,
    welcomeFlow: Boolean
  }

  connect() {
    this.initializeDashboardMagic()
    this.setupProgressCelebrations()
    this.createCelebrationElements()
    this.startWelcomeFlow()
    this.addDashboardAnimations()
  }


  disconnect() {
    if (this.celebrationCanvas) {
      this.celebrationCanvas.remove()
    }
    if (this.progressInterval) {
      clearInterval(this.progressInterval)
    }
  }

  initializeDashboardMagic() {
    // Welcome user with personalized greeting
    if (this.hasWelcomeMessageTarget && this.userNameValue) {
      this.createPersonalizedWelcome()
    }

    // Add breathing animation to profile avatar
    if (this.hasProfileAvatarTarget) {
      this.addAvatarBreathing()
    }

    // Setup periodic dashboard celebrations
    this.setupPeriodicDelights()
  }

  createPersonalizedWelcome() {
    const welcomeMessages = [
      `✨ Bem-vindo de volta, ${this.userNameValue}!`,
      `🌟 Olá ${this.userNameValue}, que bom ter você aqui!`,
      `🎉 ${this.userNameValue}, pronto para descobrir novos desejos?`,
      `💖 Que alegria ver você, ${this.userNameValue}!`
    ]

    const message = welcomeMessages[Math.floor(Math.random() * welcomeMessages.length)]

    // Show personalized welcome with fade in
    setTimeout(() => {
      this.showWelcomeToast(message)
    }, 500)
  }

  showWelcomeToast(message) {
    const toast = document.createElement('div')
    toast.className = 'fixed top-4 left-1/2 transform -translate-x-1/2 bg-gradient-to-r from-rose-500 to-pink-500 text-white px-6 py-3 rounded-full shadow-lg z-50 font-medium text-sm'
    toast.textContent = message
    toast.style.opacity = '0'
    toast.style.transform = 'translate(-50%, -20px)'

    document.body.appendChild(toast)

    // Animate in
    setTimeout(() => {
      toast.style.transition = 'all 0.4s cubic-bezier(0.25, 0.46, 0.45, 0.94)'
      toast.style.opacity = '1'
      toast.style.transform = 'translate(-50%, 0)'
    }, 100)

    // Auto dismiss
    setTimeout(() => {
      toast.style.opacity = '0'
      toast.style.transform = 'translate(-50%, -20px)'
      setTimeout(() => toast.remove(), 400)
    }, 3000)
  }

  setupProgressCelebrations() {
    if (this.profileCompletionValue >= 75 && !this.hasShownProgressCelebration) {
      this.triggerProgressMilestone()
      this.hasShownProgressCelebration = true
    }

    // Animate progress ring if exists
    if (this.hasProgressRingTarget) {
      this.animateProgressRing()
    }
  }

  triggerProgressMilestone() {
    // Show milestone celebration
    setTimeout(() => {
      this.showMilestoneCelebration()
      this.createProgressConfetti()
    }, 2000)
  }

  showMilestoneCelebration() {
    const celebration = document.createElement('div')
    celebration.className = 'fixed top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 bg-gradient-to-r from-purple-500 via-pink-500 to-rose-500 text-white px-8 py-6 rounded-2xl shadow-2xl z-50 text-center'
    celebration.innerHTML = `
      <div class="flex flex-col items-center gap-3">
        <div class="text-4xl animate-bounce">🎉</div>
        <div class="font-bold text-lg">Profile Quase Completo!</div>
        <div class="text-sm opacity-90">Você está com ${this.profileCompletionValue}% do perfil preenchido</div>
        <div class="text-xs opacity-75 mt-2">Continue assim! 💪</div>
      </div>
    `

    document.body.appendChild(celebration)

    // Animate in with scale
    celebration.style.opacity = '0'
    celebration.style.transform = 'translate(-50%, -50%) scale(0.8)'
    setTimeout(() => {
      celebration.style.transition = 'all 0.4s cubic-bezier(0.25, 0.46, 0.45, 0.94)'
      celebration.style.opacity = '1'
      celebration.style.transform = 'translate(-50%, -50%) scale(1)'
    }, 100)

    // Auto dismiss
    setTimeout(() => {
      celebration.style.opacity = '0'
      celebration.style.transform = 'translate(-50%, -50%) scale(0.8)'
      setTimeout(() => celebration.remove(), 400)
    }, 4000)
  }

  animateProgressRing() {
    // Animated progress ring drawing
    const progressValue = this.profileCompletionValue
    let currentValue = 0
    const increment = progressValue / 30 // 30 frames for smooth animation

    const updateProgress = () => {
      if (currentValue < progressValue) {
        currentValue += increment
        // Apply progress to ring element (assuming it has CSS custom properties)
        this.progressRingTarget.style.setProperty('--progress', `${Math.min(currentValue, progressValue)}%`)
        requestAnimationFrame(updateProgress)
      }
    }

    setTimeout(updateProgress, 1000)
  }

  createCelebrationElements() {
    // Create celebration canvas for particles
    this.celebrationCanvas = document.createElement('canvas')
    this.celebrationCanvas.className = 'fixed inset-0 pointer-events-none z-50 hidden'
    this.celebrationCanvas.width = window.innerWidth
    this.celebrationCanvas.height = window.innerHeight
    document.body.appendChild(this.celebrationCanvas)
    this.celebrationCtx = this.celebrationCanvas.getContext('2d')
  }

  startWelcomeFlow() {
    // Stagger entrance animations for dashboard sections
    this.animateDashboardEntrance()
  }

  animateDashboardEntrance() {
    // Profile card animation
    if (this.hasProfileCardTarget) {
      this.animateElementEntry(this.profileCardTarget, 0, 'slideInLeft')
    }

    // Stats cards animation
    this.statsCardTargets.forEach((card, index) => {
      this.animateElementEntry(card, index * 100 + 200, 'slideInUp')
    })

    // Quick actions animation
    this.quickActionTargets.forEach((action, index) => {
      this.animateElementEntry(action, index * 50 + 400, 'slideInScale')
    })

    // Friend cards animation
    this.friendCardTargets.forEach((friend, index) => {
      this.animateElementEntry(friend, index * 80 + 600, 'slideInRight')
    })

    // Activity items animation
    this.activityItemTargets.forEach((item, index) => {
      this.animateElementEntry(item, index * 60 + 800, 'fadeInUp')
    })
  }

  animateElementEntry(element, delay, animationType) {
    element.style.opacity = '0'
    element.style.transform = this.getInitialTransform(animationType)

    setTimeout(() => {
      element.style.transition = 'all 0.6s cubic-bezier(0.25, 0.46, 0.45, 0.94)'
      element.style.opacity = '1'
      element.style.transform = 'translate(0, 0) scale(1)'
    }, delay)
  }

  getInitialTransform(type) {
    switch (type) {
      case 'slideInLeft': return 'translateX(-30px)'
      case 'slideInRight': return 'translateX(30px)'
      case 'slideInUp': return 'translateY(20px)'
      case 'slideInScale': return 'scale(0.9)'
      case 'fadeInUp': return 'translateY(10px)'
      default: return 'translateY(10px)'
    }
  }

  addDashboardAnimations() {
    // Add hover animations to interactive elements
    this.addHoverEffects()

    // Add periodic subtle animations
    this.addPeriodicAnimations()
  }

  addHoverEffects() {
    // Profile card hover
    if (this.hasProfileCardTarget) {
      this.profileCardTarget.addEventListener('mouseenter', () => {
        this.profileCardTarget.style.transform = 'translateY(-2px)'
        this.profileCardTarget.style.boxShadow = '0 10px 30px rgba(0,0,0,0.1)'
        this.addProfileSparkles()
      })
      this.profileCardTarget.addEventListener('mouseleave', () => {
        this.profileCardTarget.style.transform = 'translateY(0)'
        this.profileCardTarget.style.boxShadow = ''
      })
    }

    // Stats cards hover effects
    this.statsCardTargets.forEach(card => {
      card.addEventListener('mouseenter', () => {
        card.style.transform = 'scale(1.02) translateY(-1px)'
        this.createStatsSparkle(card)
      })
      card.addEventListener('mouseleave', () => {
        card.style.transform = 'scale(1) translateY(0)'
      })
    })

    // Quick actions hover effects
    this.quickActionTargets.forEach(action => {
      action.addEventListener('mouseenter', () => {
        action.style.transform = 'scale(1.05)'
        this.addActionGlow(action)
      })
      action.addEventListener('mouseleave', () => {
        action.style.transform = 'scale(1)'
        this.removeActionGlow(action)
      })
    })
  }

  addPeriodicAnimations() {
    // Periodic avatar breathing
    setInterval(() => {
      if (this.hasProfileAvatarTarget) {
        this.profileAvatarTarget.style.transform = 'scale(1.02)'
        setTimeout(() => {
          this.profileAvatarTarget.style.transform = 'scale(1)'
        }, 200)
      }
    }, 8000)

    // Periodic notification dot pulse
    setInterval(() => {
      this.notificationDotTargets.forEach(dot => {
        dot.classList.add('animate-ping')
        setTimeout(() => {
          dot.classList.remove('animate-ping')
        }, 1000)
      })
    }, 15000)
  }

  setupPeriodicDelights() {
    // Show different celebrations based on milestones
    setTimeout(() => {
      if (this.wishlistsCountValue >= 5) {
        this.showWishlistMilestone()
      }
    }, 5000)

    setTimeout(() => {
      if (this.friendsCountValue >= 3) {
        this.showFriendsMilestone()
      }
    }, 8000)
  }

  showWishlistMilestone() {
    const celebration = this.createMilestoneCard(
      '🎯',
      'Wishlist Champion!',
      `Você já tem ${this.wishlistsCountValue} wishlists criadas!`,
      'from-green-500 to-emerald-500'
    )
    this.showCelebrationCard(celebration)
  }

  showFriendsMilestone() {
    const celebration = this.createMilestoneCard(
      '👥',
      'Social Butterfly!',
      `${this.friendsCountValue} amigos conectados no Wishare!`,
      'from-blue-500 to-cyan-500'
    )
    this.showCelebrationCard(celebration)
  }

  createMilestoneCard(emoji, title, message, gradient) {
    const card = document.createElement('div')
    card.className = `fixed top-4 right-4 bg-gradient-to-r ${gradient} text-white p-4 rounded-xl shadow-xl z-50 max-w-sm transform translate-x-full transition-transform duration-300`
    card.innerHTML = `
      <div class="flex items-center gap-3">
        <div class="text-2xl animate-bounce">${emoji}</div>
        <div>
          <div class="font-bold">${title}</div>
          <div class="text-sm opacity-90">${message}</div>
        </div>
      </div>
    `
    return card
  }

  showCelebrationCard(card) {
    document.body.appendChild(card)

    // Slide in
    setTimeout(() => {
      card.classList.remove('translate-x-full')
    }, 100)

    // Auto dismiss
    setTimeout(() => {
      card.classList.add('translate-x-full')
      setTimeout(() => card.remove(), 300)
    }, 4000)
  }

  // Event handlers
  onStatsClick(event) {
    const card = event.currentTarget
    this.createStatsClickEffect(card)
    this.showStatsDetails(card)
  }

  onQuickActionClick(event) {
    const action = event.currentTarget
    const actionType = action.dataset.actionType

    this.createActionClickEffect(action)
    this.trackQuickAction(actionType)
  }

  onFriendCardClick(event) {
    const card = event.currentTarget
    this.createFriendClickEffect(card)
  }

  onActivityClick(event) {
    const item = event.currentTarget
    this.createActivityClickEffect(item)
  }

  // Effect creation methods
  createStatsClickEffect(card) {
    // Ripple effect for stats
    const ripple = document.createElement('div')
    ripple.className = 'absolute inset-0 bg-gradient-to-r from-blue-400 to-purple-400 opacity-20 rounded-xl scale-0'
    ripple.style.animation = 'pulse 0.4s ease-out'

    card.style.position = 'relative'
    card.appendChild(ripple)

    setTimeout(() => ripple.remove(), 400)
  }

  createActionClickEffect(action) {
    // Scale effect with sparkles
    action.style.transform = 'scale(0.95)'
    this.createActionSparkles(action)

    setTimeout(() => {
      action.style.transform = 'scale(1)'
    }, 150)
  }

  createFriendClickEffect(card) {
    // Friend card click effect
    card.style.transform = 'scale(1.02) rotate(1deg)'
    this.createHeartFloat(card)

    setTimeout(() => {
      card.style.transform = 'scale(1) rotate(0deg)'
    }, 200)
  }

  createActivityClickEffect(item) {
    // Activity item click effect
    item.style.transform = 'translateX(5px)'
    this.createActivitySparkle(item)

    setTimeout(() => {
      item.style.transform = 'translateX(0)'
    }, 150)
  }

  // Sparkle and effect utilities
  addProfileSparkles() {
    if (!this.hasProfileCardTarget) return

    const sparkles = ['✨', '⭐', '💫']
    const rect = this.profileCardTarget.getBoundingClientRect()

    for (let i = 0; i < 2; i++) {
      const sparkle = document.createElement('div')
      sparkle.innerHTML = sparkles[Math.floor(Math.random() * sparkles.length)]
      sparkle.className = 'fixed pointer-events-none z-40 text-sm animate-ping'
      sparkle.style.left = (rect.left + Math.random() * rect.width) + 'px'
      sparkle.style.top = (rect.top + Math.random() * rect.height) + 'px'

      document.body.appendChild(sparkle)
      setTimeout(() => sparkle.remove(), 1000)
    }
  }

  createStatsSparkle(card) {
    const sparkle = document.createElement('div')
    sparkle.innerHTML = '📊'
    sparkle.className = 'absolute -top-2 -right-2 text-lg animate-bounce'

    card.style.position = 'relative'
    card.appendChild(sparkle)
    setTimeout(() => sparkle.remove(), 800)
  }

  createActionSparkles(action) {
    const sparkles = ['✨', '🌟', '💫']
    const rect = action.getBoundingClientRect()

    sparkles.forEach((sparkle, index) => {
      const element = document.createElement('div')
      element.innerHTML = sparkle
      element.className = 'fixed pointer-events-none z-40 text-sm'
      element.style.left = rect.left + rect.width/2 + 'px'
      element.style.top = rect.top + rect.height/2 + 'px'

      document.body.appendChild(element)

      // Animate outward
      const angle = (Math.PI * 2 * index) / sparkles.length
      const distance = 30

      setTimeout(() => {
        element.style.transition = 'all 0.6s ease-out'
        element.style.transform = `translate(${Math.cos(angle) * distance}px, ${Math.sin(angle) * distance}px) scale(0)`
        element.style.opacity = '0'
      }, 50)

      setTimeout(() => element.remove(), 650)
    })
  }

  createHeartFloat(card) {
    const heart = document.createElement('div')
    heart.innerHTML = '💖'
    heart.className = 'absolute -top-4 left-1/2 transform -translate-x-1/2 text-lg pointer-events-none z-40'

    card.style.position = 'relative'
    card.appendChild(heart)

    // Float up
    setTimeout(() => {
      heart.style.transition = 'all 1s ease-out'
      heart.style.transform = 'translate(-50%, -40px) scale(0.5)'
      heart.style.opacity = '0'
    }, 100)

    setTimeout(() => heart.remove(), 1100)
  }

  createActivitySparkle(item) {
    const sparkle = document.createElement('div')
    sparkle.innerHTML = '⚡'
    sparkle.className = 'absolute -right-2 top-1/2 transform -translate-y-1/2 text-sm animate-ping'

    item.style.position = 'relative'
    item.appendChild(sparkle)
    setTimeout(() => sparkle.remove(), 600)
  }

  addActionGlow(action) {
    action.style.boxShadow = '0 5px 20px rgba(236, 72, 153, 0.3)'
  }

  removeActionGlow(action) {
    action.style.boxShadow = ''
  }

  addAvatarBreathing() {
    if (!this.hasProfileAvatarTarget) return

    this.profileAvatarTarget.style.transition = 'transform 2s ease-in-out infinite'
  }

  createProgressConfetti() {
    this.celebrationCanvas.classList.remove('hidden')

    const particles = []
    const colors = ['#EC4899', '#8B5CF6', '#10B981', '#F59E0B', '#EF4444']

    // Create particles
    for (let i = 0; i < 40; i++) {
      particles.push({
        x: Math.random() * this.celebrationCanvas.width,
        y: -10,
        vx: (Math.random() - 0.5) * 8,
        vy: Math.random() * 4 + 2,
        color: colors[Math.floor(Math.random() * colors.length)],
        size: Math.random() * 8 + 4,
        life: 120
      })
    }

    const animate = () => {
      this.celebrationCtx.clearRect(0, 0, this.celebrationCanvas.width, this.celebrationCanvas.height)

      for (let i = particles.length - 1; i >= 0; i--) {
        const p = particles[i]

        p.x += p.vx
        p.y += p.vy
        p.vy += 0.1 // gravity
        p.life--

        this.celebrationCtx.save()
        this.celebrationCtx.globalAlpha = p.life / 120
        this.celebrationCtx.fillStyle = p.color
        this.celebrationCtx.fillRect(p.x, p.y, p.size, p.size)
        this.celebrationCtx.restore()

        if (p.life <= 0 || p.y > this.celebrationCanvas.height) {
          particles.splice(i, 1)
        }
      }

      if (particles.length > 0) {
        requestAnimationFrame(animate)
      } else {
        this.celebrationCanvas.classList.add('hidden')
      }
    }

    animate()
  }

  // Analytics and tracking
  trackQuickAction(actionType) {
    // Track user interactions for analytics
    console.log(`Quick action clicked: ${actionType}`)
  }

  showStatsDetails(card) {
    // Show more details about stats when clicked
    const statType = card.dataset.statType
    console.log(`Stats details for: ${statType}`)
  }
}