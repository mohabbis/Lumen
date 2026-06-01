//
//  KeychainService.swift
//  Muhome
//
//  Created by Muhammad Rafiq on 19/05/2026.
//  Copyright © 2026 Muhome. All rights reserved.
//

import Foundation
import Security

// MARK: - Keychain Service

final class KeychainService {
    static let shared = KeychainService()
    private init() {}

    enum KeychainError: LocalizedError {
        case encodingFailed
        case saveFailed(OSStatus)
        case readFailed(OSStatus)
        case notFound
        case deleteFailed(OSStatus)

        var errorDescription: String? {
            switch self {
            case .encodingFailed: return "Failed to encode data for Keychain."
            case .saveFailed(let s): return "Keychain save failed: \(s)"
            case .readFailed(let s): return "Keychain read failed: \(s)"
            case .notFound: return "Item not found in Keychain."
            case .deleteFailed(let s): return "Keychain delete failed: \(s)"
            }
        }
    }

    // MARK: - String helpers

    func store(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else { throw KeychainError.encodingFailed }
        try store(data, forKey: key)
    }

    func retrieve(stringForKey key: String) throws -> String {
        let data = try retrieve(forKey: key)
        guard let string = String(data: data, encoding: .utf8) else { throw KeychainError.encodingFailed }
        return string
    }

    // MARK: - Data primitives

    func store(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.saveFailed(status) }
    }

    func retrieve(forKey key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { throw KeychainError.notFound }
        guard status == errSecSuccess, let data = result as? Data else { throw KeychainError.readFailed(status) }
        return data
    }

    func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    func exists(forKey key: String) -> Bool {
        (try? retrieve(forKey: key)) != nil
    }
}

// MARK: - Well-known Keys

extension KeychainService {
    enum Keys {
        static let goveeApiKey       = "muhome.govee.apiKey"
        static let kasaUsername      = "muhome.kasa.username"
        static let kasaPassword      = "muhome.kasa.password"
        static let homebridgeBaseURL = "muhome.homebridge.baseURL"
        static let homebridgeToken   = "muhome.homebridge.token"
        static let hueApiKey             = "muhome.hue.apiKey"
        static let hueBaseURL            = "muhome.hue.baseURL"
        static let homebridgeUsername    = "muhome.homebridge.username"
        static let homebridgePassword    = "muhome.homebridge.password"
    }
}
