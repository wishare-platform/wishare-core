import { Controller } from "@hotwired/stimulus"
import { useIntersection, useResize, useTimeout } from "stimulus-use"

// Animation Foundation Controller - Core animation infrastructure for Wishare
export default class extends Controller {
  static targets = ["animateOnScroll", "staggerItem", "fadeIn", "slideUp", "scaleIn"]
  static values = {
    threshold: { type: Number, default: 0.1 },
    staggerDelay: { type: Number, default: 100 },
    animationDuration: { type: Number, default: 300 },
    reducedMotion: { type: Boolean, default: false }
  }

  connect() {
    this.setupMotionPreferences()
    useIntersection(this, {
      threshold: this.thresholdValue
    })
    useResize(this)

    this.initializeAnimationQueue()
    this.setupStaggeredAnimations()
  }

  // Check user's motion preferences
  setupMotionPreferences() {
    const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    this.reducedMotionValue = prefersReducedMotion

    if (prefersReducedMotion) {
      this.element.classList.add('reduced-motion')
    }
  }

  // Intersection Observer callback for scroll animations
  appear(entry) {
    if (this.reducedMotionValue) return

    // Animate elements when they come into view
    this.animateOnScrollTargets.forEach((element, index) => {
      setTimeout(() => {
        this.triggerAnimation(element, 'fadeInUp')
      }, index * this.staggerDelayValue)
    })

    // Stagger item animations
    this.staggerItemTargets.forEach((element, index) => {
      setTimeout(() => {
        this.triggerAnimation(element, 'staggerIn')
      }, index * (this.staggerDelayValue / 2))
    })
  }

  disappear(entry) {
    // Optional: animate out when leaving viewport
    if (this.data.get('animateOut') === 'true' && !this.reducedMotionValue) {
      this.animateOnScrollTargets.forEach(element => {
        element.style.opacity = '0.7'
      })
    }
  }

  // Core animation trigger method
  triggerAnimation(element, animationType) {
    if (this.reducedMotionValue) {
      // Instant show for reduced motion
      element.style.opacity = '1'
      element.style.transform = 'none'
      return
    }

    element.classList.add(`animate-${animationType}`)

    // Clean up animation class after completion
    setTimeout(() => {
      element.classList.remove(`animate-${animationType}`)
    }, this.animationDurationValue + 100)
  }

  // Staggered animation setup
  setupStaggeredAnimations() {
    const staggerGroups = this.element.querySelectorAll('[data-stagger-group]')

    staggerGroups.forEach(group => {
      const items = group.querySelectorAll('[data-stagger-item]')
      items.forEach((item, index) => {
        item.style.animationDelay = `${index * this.staggerDelayValue}ms`
      })
    })
  }

  // Animation queue for complex sequences
  initializeAnimationQueue() {
    this.animationQueue = []
    this.isAnimating = false
  }

  // Queue animation for later execution
  queueAnimation(element, animationType, delay = 0) {
    this.animationQueue.push({
      element,
      animationType,
      delay
    })

    if (!this.isAnimating) {
      this.processAnimationQueue()
    }
  }

  // Process queued animations
  async processAnimationQueue() {
    if (this.animationQueue.length === 0) {
      this.isAnimating = false
      return
    }

    this.isAnimating = true
    const { element, animationType, delay } = this.animationQueue.shift()

    if (delay > 0) {
      await this.wait(delay)
    }

    this.triggerAnimation(element, animationType)

    // Continue processing queue
    setTimeout(() => {
      this.processAnimationQueue()
    }, this.animationDurationValue / 2)
  }

  // Utility: Wait function
  wait(ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
  }

  // Enhanced fade in animation
  fadeIn({ target = this.element, duration = this.animationDurationValue } = {}) {
    if (this.reducedMotionValue) {
      target.style.opacity = '1'
      return Promise.resolve()
    }

    return new Promise(resolve => {
      target.style.transition = `opacity ${duration}ms ease-out`
      target.style.opacity = '1'

      setTimeout(resolve, duration)
    })
  }

  // Enhanced slide up animation
  slideUp({ target = this.element, duration = this.animationDurationValue, distance = 20 } = {}) {
    if (this.reducedMotionValue) {
      target.style.transform = 'translateY(0)'
      target.style.opacity = '1'
      return Promise.resolve()
    }

    return new Promise(resolve => {
      target.style.transition = `transform ${duration}ms ease-out, opacity ${duration}ms ease-out`
      target.style.transform = 'translateY(0)'
      target.style.opacity = '1'

      setTimeout(resolve, duration)
    })
  }

  // Enhanced scale in animation
  scaleIn({ target = this.element, duration = this.animationDurationValue, fromScale = 0.9 } = {}) {
    if (this.reducedMotionValue) {
      target.style.transform = 'scale(1)'
      target.style.opacity = '1'
      return Promise.resolve()
    }

    return new Promise(resolve => {
      target.style.transition = `transform ${duration}ms cubic-bezier(0.175, 0.885, 0.32, 1.275), opacity ${duration}ms ease-out`
      target.style.transform = 'scale(1)'
      target.style.opacity = '1'

      setTimeout(resolve, duration)
    })
  }

  // Pulse animation for emphasis
  pulse(target = this.element, intensity = 1.05) {
    if (this.reducedMotionValue) return Promise.resolve()

    return new Promise(resolve => {
      target.style.transition = 'transform 0.15s ease-out'
      target.style.transform = `scale(${intensity})`

      setTimeout(() => {
        target.style.transform = 'scale(1)'
        setTimeout(resolve, 150)
      }, 150)
    })
  }

  // Shake animation for errors/attention
  shake(target = this.element, intensity = 5) {
    if (this.reducedMotionValue) return Promise.resolve()

    return new Promise(resolve => {
      target.style.animation = `shake 0.5s ease-in-out`
      setTimeout(() => {
        target.style.animation = ''
        resolve()
      }, 500)
    })
  }

  // Bounce animation for success
  bounce(target = this.element) {
    if (this.reducedMotionValue) return Promise.resolve()

    return new Promise(resolve => {
      target.style.animation = 'bounce 0.6s ease-in-out'
      setTimeout(() => {
        target.style.animation = ''
        resolve()
      }, 600)
    })
  }

  // Window resize handler
  resize({ width, height }) {
    // Recalculate animations based on new viewport
    this.setupStaggeredAnimations()
  }

  // Action: Trigger entrance animation
  triggerEntrance(event) {
    const target = event.currentTarget
    this.slideUp({ target, duration: 400 })
  }

  // Action: Trigger emphasis
  emphasize(event) {
    const target = event.currentTarget
    this.pulse(target, 1.1)
  }

  // Action: Trigger success celebration
  celebrate(event) {
    const target = event.currentTarget
    this.bounce(target)
  }

  // Action: Trigger attention (for errors)
  attention(event) {
    const target = event.currentTarget
    this.shake(target)
  }

  disconnect() {
    // Clean up any running animations
    this.animationQueue = []
    this.isAnimating = false
  }
}

// Inject CSS animations
const style = document.createElement('style')
style.textContent = `
  @keyframes fadeInUp {
    from {
      opacity: 0;
      transform: translateY(20px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  @keyframes staggerIn {
    from {
      opacity: 0;
      transform: translateY(10px) scale(0.95);
    }
    to {
      opacity: 1;
      transform: translateY(0) scale(1);
    }
  }

  @keyframes shake {
    0%, 100% { transform: translateX(0); }
    10%, 30%, 50%, 70%, 90% { transform: translateX(-${5}px); }
    20%, 40%, 60%, 80% { transform: translateX(${5}px); }
  }

  .animate-fadeInUp {
    animation: fadeInUp 0.4s ease-out forwards;
  }

  .animate-staggerIn {
    animation: staggerIn 0.3s ease-out forwards;
  }

  /* Reduced motion support */
  .reduced-motion * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }

  /* Prepare elements for animation */
  [data-animation-foundation-target="animateOnScroll"],
  [data-animation-foundation-target="staggerItem"] {
    opacity: 0;
    transform: translateY(20px);
  }

  [data-animation-foundation-target="fadeIn"] {
    opacity: 0;
  }

  [data-animation-foundation-target="slideUp"] {
    opacity: 0;
    transform: translateY(20px);
  }

  [data-animation-foundation-target="scaleIn"] {
    opacity: 0;
    transform: scale(0.9);
  }
`
document.head.appendChild(style)