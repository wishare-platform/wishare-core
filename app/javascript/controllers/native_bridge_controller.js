import { Controller } from "@hotwired/stimulus"

/**
 * Wishare Native Bridge Controller
 * Unified JavaScript bridge for iOS and Android native features
 */
export default class extends Controller {
    static values = {
        platform: String,
        wishlistId: String,
        itemId: String,
        userId: String
    }

    static targets = ["cameraButton", "shareButton", "biometricButton", "notificationButton"]

    connect() {
        this.detectPlatform()
        this.setupNativeBridge()
        this.element.setAttribute("data-native-bridge", "ready")
        console.log("📱 Native bridge controller connected on", this.detectedPlatform)
    }

    disconnect() {
        this.cleanup()
        console.log("📱 Native bridge controller disconnected")
    }

    // Platform Detection
    detectPlatform() {
        if (this.hasPlatformValue && this.platformValue) {
            this.detectedPlatform = this.platformValue
        } else if (window.webkit && window.webkit.messageHandlers) {
            this.detectedPlatform = "ios"
        } else if (window.Android || window.HotwireNative) {
            this.detectedPlatform = "android"
        } else {
            this.detectedPlatform = "web"
        }
    }

    setupNativeBridge() {
        // Create bridge interface if not exists
        if (!window.WishareNativeBridge) {
            window.WishareNativeBridge = {
                platform: this.detectedPlatform,

                // Camera Functions
                openCamera: (wishlistId, itemId) => this.openCamera(wishlistId, itemId),
                openImagePicker: (wishlistId, itemId) => this.openImagePicker(wishlistId, itemId),

                // Sharing Functions
                shareWishlist: (wishlistId, title, url) => this.shareWishlist(wishlistId, title, url),
                shareItem: (itemId, title, url) => this.shareItem(itemId, title, url),
                shareProfile: (userId, name, url) => this.shareProfile(userId, name, url),
                shareText: (text) => this.shareText(text),

                // Biometric Functions
                authenticateWithBiometrics: () => this.authenticateWithBiometrics(),
                isBiometricAvailable: () => this.isBiometricAvailable(),

                // Notification Functions
                requestPushPermissions: () => this.requestPushPermissions(),
                registerDeviceToken: (token) => this.registerDeviceToken(token),

                // Utility Functions
                vibrate: (pattern) => this.vibrate(pattern),
                showToast: (message) => this.showToast(message),
                copyToClipboard: (text) => this.copyToClipboard(text)
            }
        }

        // Setup event listeners for native responses
        this.setupEventListeners()
    }

    setupEventListeners() {
        // Listen for native events
        document.addEventListener("wishare:image-captured", (event) => {
            this.handleImageCaptured(event.detail)
        })

        document.addEventListener("wishare:share-completed", (event) => {
            this.handleShareCompleted(event.detail)
        })

        document.addEventListener("wishare:biometric-result", (event) => {
            this.handleBiometricResult(event.detail)
        })

        document.addEventListener("wishare:push-permission-result", (event) => {
            this.handlePushPermissionResult(event.detail)
        })

        document.addEventListener("wishare:native-error", (event) => {
            this.handleNativeError(event.detail)
        })
    }

    // Camera Functions
    openCamera(wishlistId = null, itemId = null) {
        const targetWishlistId = wishlistId || this.wishlistIdValue
        const targetItemId = itemId || this.itemIdValue

        console.log("📷 Opening camera for wishlist:", targetWishlistId, "item:", targetItemId)

        switch (this.detectedPlatform) {
            case "ios":
                this.callIOSMethod("openCamera", {
                    wishlistId: targetWishlistId,
                    itemId: targetItemId
                })
                break
            case "android":
                this.callAndroidMethod("openCamera", {
                    wishlistId: targetWishlistId,
                    itemId: targetItemId
                })
                break
            default:
                this.openWebCamera(targetWishlistId, targetItemId)
                break
        }
    }

    openImagePicker(wishlistId = null, itemId = null) {
        const targetWishlistId = wishlistId || this.wishlistIdValue
        const targetItemId = itemId || this.itemIdValue

        console.log("🖼️ Opening image picker for wishlist:", targetWishlistId, "item:", targetItemId)

        switch (this.detectedPlatform) {
            case "ios":
                this.callIOSMethod("openImagePicker", {
                    wishlistId: targetWishlistId,
                    itemId: targetItemId
                })
                break
            case "android":
                this.callAndroidMethod("openImagePicker", {
                    wishlistId: targetWishlistId,
                    itemId: targetItemId
                })
                break
            default:
                this.openWebImagePicker(targetWishlistId, targetItemId)
                break
        }
    }

    // Sharing Functions
    shareWishlist(wishlistId, title, url) {
        const shareData = {
            type: "wishlist",
            id: wishlistId,
            title: title,
            url: url
        }

        console.log("🔗 Sharing wishlist:", shareData)

        switch (this.detectedPlatform) {
            case "ios":
                this.callIOSMethod("shareContent", shareData)
                break
            case "android":
                this.callAndroidMethod("shareContent", shareData)
                break
            default:
                this.webShare(shareData)
                break
        }
    }

    shareItem(itemId, title, url) {
        const shareData = {
            type: "item",
            id: itemId,
            title: title,
            url: url
        }

        console.log("🔗 Sharing item:", shareData)

        switch (this.detectedPlatform) {
            case "ios":
                this.callIOSMethod("shareContent", shareData)
                break
            case "android":
                this.callAndroidMethod("shareContent", shareData)
                break
            default:
                this.webShare(shareData)
                break
        }
    }

    shareProfile(userId, name, url) {
        const shareData = {
            type: "profile",
            id: userId,
            title: `${name}'s Profile`,
            url: url
        }

        console.log("🔗 Sharing profile:", shareData)

        switch (this.detectedPlatform) {
            case "ios":
                this.callIOSMethod("shareContent", shareData)
                break
            case "android":
                this.callAndroidMethod("shareContent", shareData)
                break
            default:
                this.webShare(shareData)
                break
        }
    }

    shareText(text) {
        console.log("🔗 Sharing text:", text)

        switch (this.detectedPlatform) {
            case "ios":
                this.callIOSMethod("shareText", { text: text })
                break
            case "android":
                this.callAndroidMethod("shareText", { text: text })
                break
            default:
                this.webShareText(text)
                break
        }
    }

    // Biometric Functions
    authenticateWithBiometrics() {
        console.log("🔐 Requesting biometric authentication")

        switch (this.detectedPlatform) {
            case "ios":
                this.callIOSMethod("authenticateWithBiometrics", {
                    reason: "Authenticate to access Wishare"
                })
                break
            case "android":
                this.callAndroidMethod("authenticateWithBiometrics", {
                    title: "Authenticate with Wishare",
                    subtitle: "Use your biometric to authenticate"
                })
                break
            default:
                this.webBiometricFallback()
                break
        }
    }

    isBiometricAvailable() {
        console.log("🔐 Checking biometric availability")

        switch (this.detectedPlatform) {
            case "ios":
                return this.callIOSMethod("isBiometricAvailable")
            case "android":
                return this.callAndroidMethod("isBiometricAvailable")
            default:
                return this.webBiometricCheck()
        }
    }

    // Notification Functions
    requestPushPermissions() {
        console.log("🔔 Requesting push notification permissions")

        switch (this.detectedPlatform) {
            case "ios":
                this.callIOSMethod("requestPushPermissions")
                break
            case "android":
                this.callAndroidMethod("requestPushPermissions")
                break
            default:
                this.webPushPermissions()
                break
        }
    }

    registerDeviceToken(token) {
        console.log("📱 Registering device token:", token.substring(0, 20) + "...")

        // Send to Rails API
        fetch("/api/v1/device_tokens", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": this.csrfToken
            },
            body: JSON.stringify({
                device_token: {
                    token: token,
                    platform: this.detectedPlatform,
                    device_type: this.getDeviceType()
                }
            })
        })
        .then(response => response.json())
        .then(data => {
            console.log("✅ Device token registered:", data)
        })
        .catch(error => {
            console.error("❌ Device token registration failed:", error)
        })
    }

    // Utility Functions
    vibrate(pattern = [100]) {
        if (navigator.vibrate) {
            navigator.vibrate(pattern)
        } else {
            switch (this.detectedPlatform) {
                case "ios":
                    this.callIOSMethod("vibrate", { pattern: pattern })
                    break
                case "android":
                    this.callAndroidMethod("vibrate", { pattern: pattern })
                    break
            }
        }
    }

    showToast(message) {
        switch (this.detectedPlatform) {
            case "ios":
                this.callIOSMethod("showToast", { message: message })
                break
            case "android":
                this.callAndroidMethod("showToast", { message: message })
                break
            default:
                this.showWebToast(message)
                break
        }
    }

    copyToClipboard(text) {
        if (navigator.clipboard) {
            navigator.clipboard.writeText(text).then(() => {
                this.showToast("Copied to clipboard")
            })
        } else {
            switch (this.detectedPlatform) {
                case "ios":
                    this.callIOSMethod("copyToClipboard", { text: text })
                    break
                case "android":
                    this.callAndroidMethod("copyToClipboard", { text: text })
                    break
                default:
                    this.fallbackCopyToClipboard(text)
                    break
            }
        }
    }

    // Platform-specific method callers
    callIOSMethod(method, params = {}) {
        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.wishareNative) {
            window.webkit.messageHandlers.wishareNative.postMessage({
                method: method,
                params: params
            })
            return true
        }
        console.warn("iOS native bridge not available, falling back to web")
        return false
    }

    callAndroidMethod(method, params = {}) {
        if (window.Android && window.Android.wishareNative) {
            window.Android.wishareNative[method](JSON.stringify(params))
            return true
        } else if (window.HotwireNative && window.HotwireNative.wishareNative) {
            window.HotwireNative.wishareNative[method](JSON.stringify(params))
            return true
        }
        console.warn("Android native bridge not available, falling back to web")
        return false
    }

    // Web fallbacks
    openWebCamera(wishlistId, itemId) {
        // Use HTML5 camera API as fallback
        if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
            navigator.mediaDevices.getUserMedia({ video: true })
                .then(stream => {
                    console.log("📷 Web camera opened")
                    // Create camera interface - simplified implementation
                })
                .catch(error => {
                    console.error("❌ Web camera failed:", error)
                })
        } else {
            // Fallback to file input
            this.openWebImagePicker(wishlistId, itemId)
        }
    }

    openWebImagePicker(wishlistId, itemId) {
        const input = document.createElement("input")
        input.type = "file"
        input.accept = "image/*"
        input.onchange = (event) => {
            const file = event.target.files[0]
            if (file) {
                this.handleWebImageFile(file, wishlistId, itemId)
            }
        }
        input.click()
    }

    handleWebImageFile(file, wishlistId, itemId) {
        const formData = new FormData()
        formData.append("image", file)

        const endpoint = `/api/v1/wishlists/${wishlistId}/items/${itemId}/image`

        fetch(endpoint, {
            method: "POST",
            headers: {
                "X-CSRF-Token": this.csrfToken
            },
            body: formData
        })
        .then(response => {
            if (response.ok) {
                this.showToast("Image uploaded successfully")
                location.reload() // Refresh to show new image
            } else {
                throw new Error("Upload failed")
            }
        })
        .catch(error => {
            console.error("❌ Image upload failed:", error)
            this.showToast("Image upload failed")
        })
    }

    webShare(shareData) {
        if (navigator.share) {
            navigator.share({
                title: shareData.title,
                url: shareData.url
            })
        } else {
            // Fallback to clipboard
            this.copyToClipboard(`${shareData.title} - ${shareData.url}`)
        }
    }

    webShareText(text) {
        if (navigator.share) {
            navigator.share({ text: text })
        } else {
            this.copyToClipboard(text)
        }
    }

    webBiometricFallback() {
        // No biometric on web, just resolve as unavailable
        this.dispatch("biometric-result", { detail: { success: false, error: "Not available on web" } })
    }

    webBiometricCheck() {
        // Web doesn't support biometrics
        return false
    }

    webPushPermissions() {
        if ("Notification" in window) {
            Notification.requestPermission().then(permission => {
                this.dispatch("push-permission-result", {
                    detail: { granted: permission === "granted" }
                })
            })
        }
    }

    showWebToast(message) {
        // Simple toast implementation
        const toast = document.createElement("div")
        toast.className = "wishare-toast"
        toast.textContent = message
        toast.style.cssText = `
            position: fixed;
            bottom: 20px;
            left: 50%;
            transform: translateX(-50%);
            background: rgba(0, 0, 0, 0.8);
            color: white;
            padding: 12px 24px;
            border-radius: 24px;
            z-index: 10000;
            font-size: 14px;
        `

        document.body.appendChild(toast)

        setTimeout(() => {
            toast.remove()
        }, 3000)
    }

    fallbackCopyToClipboard(text) {
        const textArea = document.createElement("textarea")
        textArea.value = text
        document.body.appendChild(textArea)
        textArea.focus()
        textArea.select()
        document.execCommand("copy")
        document.body.removeChild(textArea)
        this.showToast("Copied to clipboard")
    }

    // Event Handlers
    handleImageCaptured(detail) {
        console.log("📷 Image captured:", detail)
        this.showToast("Image captured successfully")
        // Refresh page or update UI as needed
        if (detail.reload) {
            location.reload()
        }
    }

    handleShareCompleted(detail) {
        console.log("🔗 Share completed:", detail)
        this.showToast("Shared successfully")
    }

    handleBiometricResult(detail) {
        console.log("🔐 Biometric result:", detail)
        if (detail.success) {
            this.showToast("Authentication successful")
        } else {
            this.showToast(`Authentication failed: ${detail.error}`)
        }
    }

    handlePushPermissionResult(detail) {
        console.log("🔔 Push permission result:", detail)
        if (detail.granted) {
            this.showToast("Push notifications enabled")
        } else {
            this.showToast("Push notifications denied")
        }
    }

    handleNativeError(detail) {
        console.error("❌ Native error:", detail)
        this.showToast(`Error: ${detail.message}`)
    }

    // Utility getters
    get csrfToken() {
        return document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    }

    getDeviceType() {
        const userAgent = navigator.userAgent
        if (/Android/i.test(userAgent)) return "Android"
        if (/iPhone|iPad|iPod/i.test(userAgent)) return "iOS"
        return "Unknown"
    }

    cleanup() {
        // Clean up any resources
        if (window.WishareNativeBridge) {
            delete window.WishareNativeBridge
        }
    }
}