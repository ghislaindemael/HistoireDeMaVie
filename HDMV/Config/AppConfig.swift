import Foundation

struct AppConfig {
    static var supabaseAnonKey: String? {
        // This print statement is for debugging
        print("DEBUG: Trying to read SUPABASE_ANON_KEY. Value is: \(Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] ?? "not found")")
        
        guard let key = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String, !key.isEmpty else {
            return nil
        }
        return key
    }
    
    static var supabaseURL: URL? {
        print("DEBUG: Trying to read SUPABASE_URL. Value is: \(Bundle.main.infoDictionary?["SUPABASE_URL"] ?? "not found")")
        
        guard var urlString = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String, !urlString.isEmpty else {
            return nil
        }
        
        urlString = "https://" + urlString
        
        guard let url = URL(string: urlString) else {
            print("🚨 ERROR: The SUPABASE_URL string '\(urlString)' is not a valid URL.")
            return nil
        }
        return url
    }
}
