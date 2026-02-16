import Foundation

enum DopoConfig {
    static let supabaseURL = "https://adyqktvkxwohzxzjqpjt.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkeXFrdHZreHdvaHp4empxcGp0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5MDY1OTcsImV4cCI6MjA4NjQ4MjU5N30.H5V7HHpIl5o5steAc760Lm1SqjmAYnWiBNrTlrmQHiI"

    static let libraryURL = "\(supabaseURL)/functions/v1/library"
    static let ingestURL = "\(supabaseURL)/functions/v1/ingest"
    static let authURL = "\(supabaseURL)/auth/v1"
}
