//
//  SecItemQueryBuilder.swift
//  SecureStoreKit
//
//  Created by SwiftMan on 7/15/26.
//  Copyright © 2026 SecureStoreKit. All rights reserved.
//

import Foundation
import LocalAuthentication
import Security

/// Builds only Data Protection Keychain queries from validated configuration.
struct SecItemQueryBuilder: Sendable {
  let configuration: SecureStoreConfiguration

  func addQuery(data: Data, key: SecureStoreKey) -> [CFString: Any] {
    var query = identityQuery(key: key)
    query[kSecValueData] = data
    query[kSecAttrAccessible] = configuration.accessibility.securityValue
    return query
  }

  func readQuery(key: SecureStoreKey) -> [CFString: Any] {
    var query = identityQuery(key: key)
    query[kSecMatchLimit] = kSecMatchLimitOne
    query[kSecReturnData] = kCFBooleanTrue
    return query
  }

  func updateQuery(key: SecureStoreKey) -> [CFString: Any] {
    identityQuery(key: key)
  }

  func updateAttributes(data: Data) -> [CFString: Any] {
    [
      kSecValueData: data,
      kSecAttrAccessible: configuration.accessibility.securityValue,
    ]
  }

  func deleteQuery(key: SecureStoreKey) -> [CFString: Any] {
    identityQuery(key: key)
  }

  func keysQuery() -> [CFString: Any] {
    var query = namespaceQuery()
    query[kSecMatchLimit] = kSecMatchLimitAll
    query[kSecReturnAttributes] = kCFBooleanTrue
    let context = LAContext()
    context.interactionNotAllowed = true
    query[kSecUseAuthenticationContext] = context
    return query
  }

  private func identityQuery(key: SecureStoreKey) -> [CFString: Any] {
    var query = namespaceQuery()
    query[kSecAttrAccount] = key.value
    return query
  }

  private func namespaceQuery() -> [CFString: Any] {
    var query: [CFString: Any] = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: configuration.service,
      kSecAttrSynchronizable: configuration.synchronizesWithICloud
        ? kCFBooleanTrue as Any : kCFBooleanFalse as Any,
      kSecUseDataProtectionKeychain: kCFBooleanTrue as Any,
    ]
    if let accessGroup = configuration.accessGroup {
      query[kSecAttrAccessGroup] = accessGroup
    }
    return query
  }
}
