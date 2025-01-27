import Foundation

enum ConfigurationError: Error {
    case missingConfigurationFile
    case missingKey(String)
}

struct Configuration {
    static let shared = Configuration()
    private let dictionary: [String: Any]
    
    private init() {
        if let path = Bundle.main.path(forResource: "Configuration", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
            self.dictionary = dict
        } else {
            // Fallback to example configuration for development
            if let path = Bundle.main.path(forResource: "Configuration.example", ofType: "plist"),
               let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
                self.dictionary = dict
            } else {
                self.dictionary = [:]
            }
        }
    }
    
    func string(forKey key: String) throws -> String {
        guard let value = dictionary[key] as? String else {
            throw ConfigurationError.missingKey(key)
        }
        return value
    }
}
