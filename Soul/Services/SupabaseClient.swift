import Foundation
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: Constants.Supabase.url)!,
    supabaseKey: Constants.Supabase.anonKey
)
