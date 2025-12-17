//
//  SupabaseConfig.swift
//  HuselenClient
//
//  Created by Le Thach lam on 17/12/25.
//

import Foundation
import Supabase

enum SupabaseConfig {
    static let url = URL(string: "https://mihqkurubhvzyaxjygqr.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1paHFrdXJ1Ymh2enlheGp5Z3FyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU5MzgwMDYsImV4cCI6MjA4MTUxNDAwNn0.k_8Bd0ThozTsYIvygNuwNGoCflTRUtJAdXqXAolSXy0"
    
    static let client = SupabaseClient(
        supabaseURL: url,
        supabaseKey: anonKey
    )
}

