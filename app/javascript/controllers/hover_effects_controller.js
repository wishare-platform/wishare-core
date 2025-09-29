import { Controller } from "@hotwired/stimulus"

// Hover Effects Controller - Advanced micro-interactions for Wishare
export default class extends Controller {
  static targets = [
    "hoverCard", "hoverButton", "hoverImage", "hoverText",
    "magneticElement", "parallaxElement", "tiltElement", "glowElement"
  ]
  static values = {
    intensity: { type: Number, default: 1 },
    magnetic: { type: Boolean, default: false },
    tilt: { type: Boolean, default: false },
    glow: { type: Boolean, default: false },
    parallax: { type: Boolean, default: false },
    duration: { type: Number, default: 300 }
  }

  connect() {
    this.setupHoverEffects()
    this.setupMagneticEffects()
    this.setupTiltEffects()
    this.checkReducedMotion()
  }

  checkReducedMotion() {
    this.reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    if (this.reducedMotion) {
      this.element.classList.add('reduced-motion')
    }
  }

  setupHoverEffects() {
    // Card hover effects
    this.hoverCardTargets.forEach(card => {
      this.addCardInteractions(card)
    })

    // Button hover effects
    this.hoverButtonTargets.forEach(button => {
      this.addButtonInteractions(button)
    })

    // Image hover effects
    this.hoverImageTargets.forEach(image => {
      this.addImageInteractions(image)
    })

    // Text hover effects
    this.hoverTextTargets.forEach(text => {
      this.addTextInteractions(text)
    })
  }

  addCardInteractions(card) {
    if (this.reducedMotion) return

    let isHovering = false

    card.addEventListener('mouseenter', (e) => {
      if (isHovering) return
      isHovering = true

      // Lift and glow effect
      card.style.transition = 'all 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275)'
      card.style.transform = `translateY(-8px) scale(1.02)`
      card.style.boxShadow = '0 20px 40px rgba(0, 0, 0, 0.1), 0 0 20px rgba(236, 72, 153, 0.2)'

      // Add subtle rotation based on mouse position
      this.addCardTilt(card, e)

      // Animate child elements
      this.animateCardChildren(card, 'enter')
    })

    card.addEventListener('mousemove', (e) => {
      if (!isHovering) return
      this.updateCardTilt(card, e)
    })

    card.addEventListener('mouseleave', () => {
      isHovering = false

      card.style.transform = 'translateY(0) scale(1) rotateX(0) rotateY(0)'
      card.style.boxShadow = ''

      // Reset child elements
      this.animateCardChildren(card, 'leave')
    })
  }

  addCardTilt(card, event) {
    const rect = card.getBoundingClientRect()
    const centerX = rect.left + rect.width / 2
    const centerY = rect.top + rect.height / 2
    const mouseX = event.clientX
    const mouseY = event.clientY

    const rotateX = (mouseY - centerY) / rect.height * -10
    const rotateY = (mouseX - centerX) / rect.width * 10

    card.style.transform = `translateY(-8px) scale(1.02) rotateX(${rotateX}deg) rotateY(${rotateY}deg)`
  }

  updateCardTilt(card, event) {
    if (this.reducedMotion) return
    this.addCardTilt(card, event)
  }

  animateCardChildren(card, state) {
    const children = card.querySelectorAll('.hover-child')

    children.forEach((child, index) => {
      if (state === 'enter') {
        child.style.transition = `transform 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275)`
        child.style.transitionDelay = `${index * 50}ms`
        child.style.transform = 'translateY(-4px)'
      } else {
        child.style.transform = 'translateY(0)'
      }
    })
  }

  addButtonInteractions(button) {
    if (this.reducedMotion) return

    button.addEventListener('mouseenter', () => {
      button.style.transition = 'all 0.2s ease-out'
      button.style.transform = 'translateY(-2px) scale(1.05)'
      button.style.boxShadow = '0 8px 25px rgba(236, 72, 153, 0.4)'

      // Add ripple preparation
      this.prepareRipple(button)
    })

    button.addEventListener('mouseleave', () => {
      button.style.transform = 'translateY(0) scale(1)'
      button.style.boxShadow = ''
    })

    button.addEventListener('mousedown', (e) => {
      this.createRipple(e, button)
    })
  }

  prepareRipple(button) {
    if (button.querySelector('.ripple')) return

    const ripple = document.createElement('span')
    ripple.className = 'ripple'
    ripple.style.cssText = `
      position: absolute;
      border-radius: 50%;
      background: rgba(255, 255, 255, 0.6);
      transform: scale(0);
      pointer-events: none;
      z-index: 1;
    `
    button.style.position = 'relative'
    button.style.overflow = 'hidden'
    button.appendChild(ripple)
  }

  createRipple(event, button) {
    const ripple = button.querySelector('.ripple')
    if (!ripple) return

    const rect = button.getBoundingClientRect()
    const size = Math.max(rect.width, rect.height)
    const x = event.clientX - rect.left - size / 2
    const y = event.clientY - rect.top - size / 2

    ripple.style.width = ripple.style.height = size + 'px'
    ripple.style.left = x + 'px'
    ripple.style.top = y + 'px'
    ripple.style.animation = 'ripple-animation 0.6s ease-out'

    setTimeout(() => {
      ripple.style.animation = ''
    }, 600)
  }

  addImageInteractions(image) {
    if (this.reducedMotion) return

    image.addEventListener('mouseenter', () => {
      image.style.transition = 'transform 0.4s ease-out, filter 0.4s ease-out'
      image.style.transform = 'scale(1.08)'
      image.style.filter = 'brightness(1.1) contrast(1.05)'
    })

    image.addEventListener('mouseleave', () => {
      image.style.transform = 'scale(1)'
      image.style.filter = 'brightness(1) contrast(1)'
    })
  }

  addTextInteractions(text) {
    if (this.reducedMotion) return

    text.addEventListener('mouseenter', () => {
      text.style.transition = 'all 0.2s ease-out'
      text.style.color = '#ec4899'
      text.style.textShadow = '0 0 8px rgba(236, 72, 153, 0.3)'
    })

    text.addEventListener('mouseleave', () => {
      text.style.color = ''
      text.style.textShadow = ''
    })
  }

  setupMagneticEffects() {
    if (this.reducedMotion) return

    this.magneticElementTargets.forEach(element => {
      this.addMagneticEffect(element)
    })
  }

  addMagneticEffect(element) {
    let isActive = false

    element.addEventListener('mouseenter', () => {
      isActive = true
    })

    element.addEventListener('mousemove', (e) => {
      if (!isActive) return

      const rect = element.getBoundingClientRect()
      const centerX = rect.left + rect.width / 2
      const centerY = rect.top + rect.height / 2
      const mouseX = e.clientX
      const mouseY = e.clientY

      const deltaX = (mouseX - centerX) * 0.3
      const deltaY = (mouseY - centerY) * 0.3

      element.style.transition = 'transform 0.1s ease-out'
      element.style.transform = `translate(${deltaX}px, ${deltaY}px)`
    })

    element.addEventListener('mouseleave', () => {
      isActive = false
      element.style.transition = 'transform 0.3s ease-out'
      element.style.transform = 'translate(0, 0)'
    })
  }

  setupTiltEffects() {
    if (this.reducedMotion) return

    this.tiltElementTargets.forEach(element => {
      this.addTiltEffect(element)
    })
  }

  addTiltEffect(element) {
    element.addEventListener('mousemove', (e) => {
      const rect = element.getBoundingClientRect()
      const centerX = rect.left + rect.width / 2
      const centerY = rect.top + rect.height / 2
      const mouseX = e.clientX
      const mouseY = e.clientY

      const rotateX = (mouseY - centerY) / rect.height * -15
      const rotateY = (mouseX - centerX) / rect.width * 15

      element.style.transition = 'transform 0.1s ease-out'
      element.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg)`
    })

    element.addEventListener('mouseleave', () => {
      element.style.transition = 'transform 0.3s ease-out'
      element.style.transform = 'perspective(1000px) rotateX(0) rotateY(0)'
    })
  }

  // Glow effect for special elements
  addGlowEffect(element, color = '#ec4899') {
    if (this.reducedMotion) return

    element.addEventListener('mouseenter', () => {
      element.style.transition = 'all 0.3s ease-out'
      element.style.boxShadow = `0 0 20px ${color}40, 0 0 40px ${color}20`
      element.style.filter = 'brightness(1.1)'
    })

    element.addEventListener('mouseleave', () => {
      element.style.boxShadow = ''
      element.style.filter = ''
    })
  }

  // Parallax effect for backgrounds
  addParallaxEffect(element, speed = 0.5) {
    if (this.reducedMotion) return

    window.addEventListener('scroll', () => {
      const scrolled = window.pageYOffset
      const rate = scrolled * -speed
      element.style.transform = `translateY(${rate}px)`
    })
  }

  // Action methods
  enhanceCard(event) {
    const card = event.currentTarget
    this.addCardInteractions(card)
  }

  enhanceButton(event) {
    const button = event.currentTarget
    this.addButtonInteractions(button)
  }

  enhanceImage(event) {
    const image = event.currentTarget
    this.addImageInteractions(image)
  }

  addMagnetic(event) {
    const element = event.currentTarget
    this.addMagneticEffect(element)
  }

  addTilt(event) {
    const element = event.currentTarget
    this.addTiltEffect(element)
  }

  addGlow(event) {
    const element = event.currentTarget
    const color = event.params?.color || '#ec4899'
    this.addGlowEffect(element, color)
  }

  disconnect() {
    // Clean up event listeners if needed
  }
}

// Inject CSS for hover effects
const style = document.createElement('style')
style.textContent = `
  @keyframes ripple-animation {
    to {
      transform: scale(2);
      opacity: 0;
    }
  }

  /* Base hover states */
  [data-hover-effects-target="hoverCard"] {
    transition: all 0.3s ease-out;
    cursor: pointer;
  }

  [data-hover-effects-target="hoverButton"] {
    transition: all 0.2s ease-out;
    cursor: pointer;
    position: relative;
    overflow: hidden;
  }

  [data-hover-effects-target="hoverImage"] {
    transition: all 0.4s ease-out;
    cursor: pointer;
  }

  [data-hover-effects-target="hoverText"] {
    transition: all 0.2s ease-out;
    cursor: pointer;
  }

  /* Magnetic elements */
  [data-hover-effects-target="magneticElement"] {
    transition: transform 0.3s ease-out;
    cursor: pointer;
  }

  /* Tilt elements */
  [data-hover-effects-target="tiltElement"] {
    transition: transform 0.3s ease-out;
    cursor: pointer;
  }

  /* Hover child elements */
  .hover-child {
    transition: transform 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
  }

  /* Reduced motion support */
  .reduced-motion [data-hover-effects-target] {
    transform: none !important;
    transition: none !important;
  }

  .reduced-motion .hover-child {
    transform: none !important;
    transition: none !important;
  }

  /* Focus states for accessibility */
  [data-hover-effects-target]:focus-visible {
    outline: 2px solid #ec4899;
    outline-offset: 2px;
  }
`
document.head.appendChild(style)