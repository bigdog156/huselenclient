//
//  CachedAsyncImage.swift
//  HuselenClient
//
//  Created by Le Thach lam on 25/12/25.
//

import SwiftUI
import Kingfisher

/// A reusable cached image component using Kingfisher
/// Supports ~150 images with optimized memory and disk caching
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        KFImage(url)
            .placeholder {
                placeholder()
            }
            .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 400, height: 400)))
            .cacheMemoryOnly(false)
            .fade(duration: 0.25)
            .onSuccess { result in
                // Optional: Log successful image loads for debugging
                #if DEBUG
                print("✅ Image loaded: \(result.source.url?.lastPathComponent ?? "unknown")")
                #endif
            }
            .onFailure { error in
                // Optional: Log failures for debugging
                #if DEBUG
                print("❌ Image load failed: \(error.localizedDescription)")
                #endif
            }
            .resizable()
    }
}

/// Convenience initializer for simple cases
extension CachedAsyncImage where Content == AnyView, Placeholder == AnyView {
    init(
        url: URL?,
        placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = { AnyView($0) }
        self.placeholder = placeholder
    }
}

/// Specialized version for avatar images
struct CachedAvatarImage: View {
    let url: URL?
    let size: CGFloat
    let placeholder: AnyView
    
    init(url: URL?, size: CGFloat = 56, placeholder: AnyView) {
        self.url = url
        self.size = size
        self.placeholder = placeholder
    }
    
    var body: some View {
        KFImage(url)
            .placeholder {
                placeholder
            }
            .setProcessor(DownsamplingImageProcessor(size: CGSize(width: size * 2, height: size * 2)))
            .scaleFactor(UIScreen.main.scale)
            .cacheMemoryOnly(false)
            .fade(duration: 0.25)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(Circle())
    }
}

/// Configure Kingfisher cache settings
/// Call this once in your app initialization
enum ImageCacheManager {
    static func configure() {
        let cache = ImageCache.default
        
        // Memory cache: ~50 images (considering average 2MB per image = 100MB)
        cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024 // 100 MB
        cache.memoryStorage.config.countLimit = 50
        
        // Disk cache: ~150 images (considering average 2MB per image = 300MB)
        cache.diskStorage.config.sizeLimit = 300 * 1024 * 1024 // 300 MB
        
        // Expire disk cache after 7 days
        cache.diskStorage.config.expiration = .days(7)
        
        // Clean expired disk cache automatically
        cache.cleanExpiredDiskCache()
        
        #if DEBUG
        print("🖼️ Kingfisher cache configured:")
        print("   Memory: 100MB / 50 images")
        print("   Disk: 300MB / ~150 images")
        print("   Expiration: 7 days")
        #endif
    }
    
    /// Clear all cached images (useful for logout or debugging)
    static func clearCache() {
        ImageCache.default.clearMemoryCache()
        ImageCache.default.clearDiskCache {
            #if DEBUG
            print("🗑️ Image cache cleared")
            #endif
        }
    }
    
    /// Clear only memory cache (useful for low memory situations)
    static func clearMemoryCache() {
        ImageCache.default.clearMemoryCache()
        #if DEBUG
        print("🗑️ Memory cache cleared")
        #endif
    }
}
