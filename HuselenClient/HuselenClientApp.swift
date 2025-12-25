//
//  HuselenClientApp.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import SwiftUI

@main
struct HuselenClientApp: App {
    
    init() {
        // Configure Kingfisher image cache on app launch
        ImageCacheManager.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
