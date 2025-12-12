import Foundation
import Security

// Custom error type for Keychain operations
enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to Keychain. Status: \(status)"
        case .loadFailed(let status):
            return "Failed to load from Keychain. Status: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete from Keychain. Status: \(status)"
        case .invalidData:
            return "The data read from Keychain was in an invalid format."
        }
    }
}

/// A service class for securely storing and retrieving data from the system Keychain.
class KeychainService {
    
    // A unique identifier for the service within the Keychain
    private let service = "com.promptcraft.apikey"
    // The account name associated with the API key
    private let account = "openai"

    /// Saves the OpenAI API key securely to the Keychain.
    /// - Parameter apiKey: The API key string to save.
    /// - Throws: `KeychainError.saveFailed` if the operation fails.
    func saveAPIKey(_ apiKey: String) throws {
        guard let data = apiKey.data(using: .utf8) else {
            // This should not happen with a valid string
            return
        }
        
        // The query to find an existing item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        // Attributes for the new or updated item
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        // First, try to update an existing item
        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        // If the item doesn't exist, add it
        if status == errSecItemNotFound {
            var newItemQuery = query
            newItemQuery[kSecValueData as String] = data
            status = SecItemAdd(newItemQuery as CFDictionary, nil)
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
        
        print("[KeychainService] API Key saved successfully.")
    }

    /// Loads the OpenAI API key from the Keychain.
    /// - Returns: The API key string, or `nil` if it's not found.
    /// - Throws: `KeychainError.loadFailed` or `KeychainError.invalidData`.
    func loadAPIKey() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            guard let data = dataTypeRef as? Data,
                  let apiKey = String(data: data, encoding: .utf8) else {
                throw KeychainError.invalidData
            }
            print("[KeychainService] API Key loaded successfully.")
            return apiKey
        } else if status == errSecItemNotFound {
            print("[KeychainService] No API Key found in Keychain.")
            return nil
        } else {
            throw KeychainError.loadFailed(status)
        }
    }

    /// Deletes the OpenAI API key from the Keychain.
    /// - Throws: `KeychainError.deleteFailed` if the operation fails.
    func deleteAPIKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
        
        print("[KeychainService] API Key deleted (or was not present).")
    }
}
