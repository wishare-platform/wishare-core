import { Controller } from "@hotwired/stimulus"

/**
 * Enhanced Social Media Sharing Controller
 * Handles creator content sharing to TikTok, Instagram, and other platforms
 */
export default class extends Controller {
    static values = {
        platform: String,
        contentType: String,
        title: String,
        description: String,
        imageUrl: String,
        videoUrl: String,
        wishlistId: String,
        itemId: String,
        creatorMode: Boolean
    }

    static targets = ["shareButton", "platformSelector", "previewContainer", "analytics"]

    connect() {
        this.setupSocialSharing()
        this.detectNativePlatforms()
        console.log("🔗 Social share controller connected for creator mode:", this.creatorModeValue)
    }

    // Main sharing method with creator optimizations
    async shareContent(event) {
        event.preventDefault()

        const platform = this.platformValue || event.currentTarget.dataset.platform
        const contentData = this.prepareContentData(platform)

        // Track creator sharing analytics
        this.trackCreatorShare(platform, contentData)

        try {
            switch (platform) {
                case 'tiktok':
                    await this.shareToTikTok(contentData)
                    break
                case 'instagram':
                    await this.shareToInstagram(contentData)
                    break
                case 'twitter':
                    await this.shareToTwitter(contentData)
                    break
                case 'facebook':
                    await this.shareToFacebook(contentData)
                    break
                case 'youtube':
                    await this.shareToYouTube(contentData)
                    break
                case 'pinterest':
                    await this.shareToPinterest(contentData)
                    break
                default:
                    await this.shareGeneric(contentData)
            }

            this.showSuccessMessage(platform)

        } catch (error) {
            console.error(`❌ Failed to share to ${platform}:`, error)
            this.showErrorMessage(platform, error.message)
        }
    }

    // TikTok sharing with creator-optimized content
    async shareToTikTok(contentData) {
        if (this.isNativeApp()) {
            // Use native TikTok integration
            const shareData = {
                type: 'tiktok_share',
                title: contentData.title,
                description: contentData.description,
                video_url: contentData.videoUrl,
                image_url: contentData.imageUrl,
                hashtags: this.generateCreatorHashtags(),
                creator_mode: true
            }

            return window.WishareNativeBridge.shareToTikTok(shareData)
        } else {
            // Web TikTok share URL
            const tiktokUrl = this.buildTikTokShareUrl(contentData)
            window.open(tiktokUrl, '_blank', 'width=600,height=400')
        }
    }

    // Instagram sharing with story/feed options
    async shareToInstagram(contentData) {
        if (this.isNativeApp()) {
            const shareData = {
                type: 'instagram_share',
                title: contentData.title,
                description: contentData.description,
                image_url: contentData.imageUrl,
                video_url: contentData.videoUrl,
                hashtags: this.generateCreatorHashtags(),
                story_mode: contentData.storyMode || false,
                creator_mode: true
            }

            return window.WishareNativeBridge.shareToInstagram(shareData)
        } else {
            // Web Instagram share
            const instagramUrl = this.buildInstagramShareUrl(contentData)
            window.open(instagramUrl, '_blank', 'width=600,height=400')
        }
    }

    // YouTube Shorts sharing for video content
    async shareToYouTube(contentData) {
        if (!contentData.videoUrl && !contentData.imageUrl) {
            throw new Error('YouTube sharing requires video or image content')
        }

        if (this.isNativeApp()) {
            const shareData = {
                type: 'youtube_share',
                title: contentData.title,
                description: this.buildYouTubeDescription(contentData),
                video_url: contentData.videoUrl,
                thumbnail_url: contentData.imageUrl,
                tags: this.generateYouTubeTags(),
                category: 'People & Blogs',
                creator_mode: true
            }

            return window.WishareNativeBridge.shareToYouTube(shareData)
        } else {
            // Open YouTube Studio for manual upload
            const youtubeUrl = 'https://studio.youtube.com/channel/UC/videos/upload'
            window.open(youtubeUrl, '_blank')
            this.copyContentToClipboard(contentData)
        }
    }

    // Twitter sharing with creator-optimized threading
    async shareToTwitter(contentData) {
        const tweetText = this.buildTwitterThread(contentData)

        if (this.isNativeApp()) {
            return window.WishareNativeBridge.shareText(tweetText)
        } else {
            const twitterUrl = `https://twitter.com/intent/tweet?text=${encodeURIComponent(tweetText)}`
            window.open(twitterUrl, '_blank', 'width=600,height=400')
        }
    }

    // Facebook sharing with creator pages support
    async shareToFacebook(contentData) {
        const shareUrl = contentData.shareUrl || window.location.href

        if (this.isNativeApp()) {
            const shareData = {
                type: 'facebook_share',
                url: shareUrl,
                title: contentData.title,
                description: contentData.description,
                image_url: contentData.imageUrl,
                creator_mode: true
            }

            return window.WishareNativeBridge.shareToFacebook(shareData)
        } else {
            const facebookUrl = `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(shareUrl)}`
            window.open(facebookUrl, '_blank', 'width=600,height=400')
        }
    }

    // Pinterest sharing optimized for wishlist items
    async shareToPinterest(contentData) {
        if (!contentData.imageUrl) {
            throw new Error('Pinterest sharing requires an image')
        }

        const pinterestData = {
            url: contentData.shareUrl || window.location.href,
            media: contentData.imageUrl,
            description: this.buildPinterestDescription(contentData)
        }

        if (this.isNativeApp()) {
            return window.WishareNativeBridge.shareToPinterest(pinterestData)
        } else {
            const pinterestUrl = `https://pinterest.com/pin/create/button/?` +
                `url=${encodeURIComponent(pinterestData.url)}&` +
                `media=${encodeURIComponent(pinterestData.media)}&` +
                `description=${encodeURIComponent(pinterestData.description)}`

            window.open(pinterestUrl, '_blank', 'width=600,height=400')
        }
    }

    // Generic sharing fallback
    async shareGeneric(contentData) {
        if (navigator.share && this.isNativeApp()) {
            try {
                await navigator.share({
                    title: contentData.title,
                    text: contentData.description,
                    url: contentData.shareUrl || window.location.href
                })
            } catch (error) {
                if (error.name !== 'AbortError') {
                    throw error
                }
            }
        } else {
            // Copy to clipboard as fallback
            this.copyContentToClipboard(contentData)
            this.showToast('Content copied to clipboard!')
        }
    }

    // Content preparation with creator optimizations
    prepareContentData(platform) {
        const baseData = {
            title: this.titleValue || document.title,
            description: this.descriptionValue || '',
            imageUrl: this.imageUrlValue || '',
            videoUrl: this.videoUrlValue || '',
            shareUrl: window.location.href,
            wishlistId: this.wishlistIdValue,
            itemId: this.itemIdValue,
            creatorMode: this.creatorModeValue
        }

        // Platform-specific optimizations
        switch (platform) {
            case 'tiktok':
                return {
                    ...baseData,
                    title: this.optimizeForTikTok(baseData.title),
                    description: this.buildTikTokDescription(baseData),
                    storyMode: false
                }
            case 'instagram':
                return {
                    ...baseData,
                    title: this.optimizeForInstagram(baseData.title),
                    description: this.buildInstagramDescription(baseData),
                    storyMode: this.contentTypeValue === 'story'
                }
            case 'youtube':
                return {
                    ...baseData,
                    title: this.optimizeForYouTube(baseData.title),
                    description: this.buildYouTubeDescription(baseData)
                }
            default:
                return baseData
        }
    }

    // Creator hashtag generation
    generateCreatorHashtags() {
        const baseHashtags = ['#wishlist', '#gifting', '#wishare']
        const creatorHashtags = ['#creator', '#giftguide', '#recommendations']

        if (this.creatorModeValue) {
            return [...baseHashtags, ...creatorHashtags].join(' ')
        }

        return baseHashtags.join(' ')
    }

    generateYouTubeTags() {
        return [
            'wishlist',
            'gift guide',
            'recommendations',
            'shopping',
            'creator content',
            'wishare'
        ]
    }

    // Platform-specific content builders
    buildTikTokDescription(contentData) {
        return `${contentData.description}\n\n` +
               `Check out my wishlist on Wishare! 🎁\n` +
               `${this.generateCreatorHashtags()}\n` +
               `${contentData.shareUrl}`
    }

    buildInstagramDescription(contentData) {
        return `${contentData.description}\n\n` +
               `✨ Find this and more on my Wishare wishlist\n` +
               `${this.generateCreatorHashtags()}\n` +
               `Link in bio or: ${contentData.shareUrl}`
    }

    buildYouTubeDescription(contentData) {
        return `${contentData.description}\n\n` +
               `🎁 Full wishlist: ${contentData.shareUrl}\n\n` +
               `About Wishare:\n` +
               `Wishare is the ultimate gifting platform where you can create, share, and discover wishlists for any occasion.\n\n` +
               `${this.generateCreatorHashtags()}`
    }

    buildTwitterThread(contentData) {
        const thread = [
            `🧵 Just found the perfect gift idea! ${contentData.title}`,
            contentData.description,
            `Check out the full wishlist: ${contentData.shareUrl}`,
            this.generateCreatorHashtags()
        ]

        return thread.join('\n\n')
    }

    buildPinterestDescription(contentData) {
        return `${contentData.title} - ${contentData.description} | Find this and more gift ideas on Wishare`
    }

    // Platform URL builders
    buildTikTokShareUrl(contentData) {
        // TikTok doesn't have a direct web share URL, so we redirect to their app
        return `https://www.tiktok.com/`
    }

    buildInstagramShareUrl(contentData) {
        // Instagram web sharing is limited, redirect to the app
        return `https://www.instagram.com/`
    }

    // Content optimization for different platforms
    optimizeForTikTok(title) {
        // TikTok prefers shorter, engaging titles
        return title.length > 50 ? title.substring(0, 47) + '...' : title
    }

    optimizeForInstagram(title) {
        // Instagram allows longer captions
        return title.length > 100 ? title.substring(0, 97) + '...' : title
    }

    optimizeForYouTube(title) {
        // YouTube titles should be under 60 characters for best display
        return title.length > 60 ? title.substring(0, 57) + '...' : title
    }

    // Utility methods
    isNativeApp() {
        return window.WishareNativeBridge && window.WishareNativeBridge.platform !== 'web'
    }

    copyContentToClipboard(contentData) {
        const shareText = `${contentData.title}\n\n${contentData.description}\n\n${contentData.shareUrl}`

        if (navigator.clipboard) {
            navigator.clipboard.writeText(shareText)
        } else {
            window.WishareNativeBridge?.copyToClipboard(shareText)
        }
    }

    showToast(message) {
        if (window.WishareNativeBridge) {
            window.WishareNativeBridge.showToast(message)
        } else {
            // Web toast fallback
            const toast = document.createElement('div')
            toast.className = 'toast-notification'
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
    }

    showSuccessMessage(platform) {
        this.showToast(`Successfully shared to ${platform}!`)
    }

    showErrorMessage(platform, error) {
        this.showToast(`Failed to share to ${platform}: ${error}`)
    }

    // Analytics tracking for creator features
    trackCreatorShare(platform, contentData) {
        const analyticsData = {
            event_name: 'creator_content_shared',
            platform: platform,
            content_type: contentData.contentType || 'wishlist',
            wishlist_id: contentData.wishlistId,
            item_id: contentData.itemId,
            creator_mode: contentData.creatorMode,
            has_video: !!contentData.videoUrl,
            has_image: !!contentData.imageUrl
        }

        // Send to mobile analytics
        if (window.WishareNativeBridge) {
            window.WishareNativeBridge.trackEvent('creator_share', analyticsData)
        }

        // Send to Rails analytics
        fetch('/api/v1/analytics/track', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
            },
            body: JSON.stringify({
                event: analyticsData
            })
        }).catch(error => {
            console.warn('Analytics tracking failed:', error)
        })
    }

    // Platform detection
    detectNativePlatforms() {
        const platforms = ['tiktok', 'instagram', 'youtube', 'twitter', 'facebook', 'pinterest']

        platforms.forEach(platform => {
            const isAvailable = this.isPlatformAppInstalled(platform)
            this.element.dataset[`${platform}Available`] = isAvailable
        })
    }

    isPlatformAppInstalled(platform) {
        // This would be implemented with native bridge calls
        // For now, assume all platforms are available
        return true
    }

    setupSocialSharing() {
        // Add click handlers to share buttons
        this.element.addEventListener('click', (event) => {
            if (event.target.matches('[data-action*="shareContent"]') ||
                event.target.closest('[data-action*="shareContent"]')) {
                this.shareContent(event)
            }
        })
    }
}