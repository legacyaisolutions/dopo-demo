import Foundation

enum DopoConfig {
    static let supabaseURL = "https://adyqktvkxwohzxzjqpjt.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkeXFrdHZreHdvaHp4empxcGp0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5MDY1OTcsImV4cCI6MjA4NjQ4MjU5N30.H5V7HHpIl5o5steAc760Lm1SqjmAYnWiBNrTlrmQHiI"

    // Edge function endpoints
    static let libraryURL = "\(supabaseURL)/functions/v1/library"
    static let ingestURL = "\(supabaseURL)/functions/v1/ingest"
    static let smartSearchURL = "\(supabaseURL)/functions/v1/smart-search"
    static let configURL = "\(supabaseURL)/functions/v1/config"
    static let authURL = "\(supabaseURL)/auth/v1"

    // App metadata — used for feature flags and version enforcement
    static let platform = "ios"
    static let appVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }()
}
