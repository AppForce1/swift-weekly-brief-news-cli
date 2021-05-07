//
//  KeyChainStore.swift
//  Swift Weekly Brief
//
//  Created by Jeroen Leenarts on 22/03/2021.
//

import Foundation
import LocalAuthentication

enum KeyChainError: Error {
    case conversionError
    case securityError(status: OSStatus)
    case unexpectedError
}

private enum KeychainKey: String {
    case sendyApi
    case secret
    case productionListId
    case testListId
}


extension SwiftKeyChainStore {
    func sendyApi() throws -> String? {
        try string(forKey: KeychainKey.sendyApi.rawValue)
    }

    func setSendyApi(_ newValue: String) throws {
        try setString(newValue, forKey: KeychainKey.sendyApi.rawValue)
    }

    func productionListId() throws -> String? {
        try string(forKey: KeychainKey.productionListId.rawValue)
    }

    func setProductionListId(_ newValue: String) throws {
        try setString(newValue, forKey: KeychainKey.productionListId.rawValue)
    }
    
    func secret() throws -> String? {
        try string(forKey: KeychainKey.secret.rawValue)
    }
    
    func setSecret(_ newValue: String) throws {
        try setString(newValue, forKey: KeychainKey.secret.rawValue)
    }
    
    func testListId() throws -> String? {
        try string(forKey: KeychainKey.testListId.rawValue)
    }

    func setTestListId(_ newValue: String) throws {
        try setString(newValue, forKey: KeychainKey.testListId.rawValue)
    }
}

class SwiftKeyChainStore {

    private(set) var service: String?
    private(set) var accessGroup: String?

    var authenticationPrompt: String = "Please provide your ID to send newsletters."

    var allItems: [AnyObject] {

        var query = baseQuery()

        query[kSecMatchLimit as String] = kSecMatchLimitAll
        query[kSecReturnAttributes as String] = true
        query[kSecReturnData as String] = true

        var resultRef: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &resultRef)

        guard status == errSecSuccess else {
            return []
        }

        guard let items = resultRef as? [AnyObject] else {
            return []
        }

        return items
    }

    init(service: String?, accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }

    private func existsStatus(forKey key: String) -> OSStatus {
        var query = baseQuery()
        query[kSecAttrAccount as String] = key
        let context = LAContext()
        context.interactionNotAllowed = true
        query[kSecUseAuthenticationContext as String] = context

        var dataRef: CFTypeRef?
        return SecItemCopyMatching(query as CFDictionary, &dataRef)
    }

    func setString(_ string: String?, forKey key: String, requireUserpresence: Bool = false) throws {
        guard let string = string else {
            try removeItem(forKey: key)
            return
        }

        guard let data = string.data(using: .utf8) else {
            throw KeyChainError.conversionError
        }

        try setData(data, forKey: key, requireUserpresence: requireUserpresence)
    }

    func string(forKey key: String) throws -> String? {
        guard let data = try data(forKey: key) else { return nil }

        guard let string = String(data: data, encoding: .utf8) else {
            throw KeyChainError.conversionError
        }
        return string
    }

    func setData(_ data: Data?, forKey key: String, requireUserpresence: Bool = false) throws {
        guard let data = data else {
            try removeItem(forKey: key)
            return
        }

        let status = existsStatus(forKey: key)
        if status == errSecSuccess || status == errSecInteractionNotAllowed {
            // Removing instead of updating prevents user presence checks from showing.
            try removeItem(forKey: key)
        }
        if status == errSecItemNotFound || status == errSecSuccess || status == errSecInteractionNotAllowed {
            var attributes = baseQuery()
            attributes[kSecAttrAccount as String] = key
            attributes[kSecValueData as String] = data

            if requireUserpresence {
                if let accessControl = SecAccessControlCreateWithFlags(
                  nil,
                  kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                  .biometryCurrentSet,
                    nil) {
                    attributes[kSecAttrAccessControl as String] = accessControl
                }
            } else {
                attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            }

            let status = SecItemAdd(attributes as CFDictionary, nil)
            guard status == errSecSuccess else {
                throw KeyChainError.securityError(status: status)
            }
        } else {
            throw KeyChainError.securityError(status: status)
        }
    }

    func data(forKey key: String) throws -> Data? {
        var query = baseQuery()

        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = true

        query[kSecAttrAccount as String] = key
        query[kSecUseAuthenticationContext as String] = LAContext()

        var dataRef: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &dataRef)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeyChainError.securityError(status: status)
        }
        guard let data = dataRef as? Data else {
            throw KeyChainError.unexpectedError
        }
        return data
    }

    func removeItem(forKey key: String) throws {
        var query = baseQuery()
        query[kSecAttrAccount as String] = key

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeyChainError.securityError(status: status)
        }
    }

    func removeAllItems() throws {
        let query = baseQuery()
//        #if !TARGET_OS_IPHONE
//            query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitAll;
//        #endif
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeyChainError.securityError(status: status)
        }
    }

    private func baseQuery() -> [String: Any] {
        var query: [String: Any] = [:]

        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrSynchronizable as String] = kSecAttrSynchronizableAny
        query[kSecAttrService as String] = service
        #if !targetEnvironment(simulator)
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        #endif

        query[kSecUseOperationPrompt as String] = authenticationPrompt

        return query
    }
}
