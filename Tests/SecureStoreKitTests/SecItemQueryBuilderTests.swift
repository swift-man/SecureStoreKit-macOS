//
//  SecItemQueryBuilderTests.swift
//  SecureStoreKit
//
//  Created by SwiftMan on 7/15/26.
//  Copyright © 2026 SecureStoreKit. All rights reserved.
//

import Foundation
import LocalAuthentication
import Security
import Testing

@testable import SecureStoreKit

@Suite("Data Protection Keychain query builder")
struct SecItemQueryBuilderTests {
  @Test("all queries target one Data Protection Keychain namespace")
  func namespaceQueries() throws {
    let configuration = try SecureStoreConfiguration(
      service: "com.example.app",
      accessGroup: "TEAMID.com.example.app"
    )
    let builder = SecItemQueryBuilder(configuration: configuration)
    let key = try SecureStoreKey("token")
    let queries = [
      builder.addQuery(data: Data("value".utf8) as NSData, key: key),
      builder.readQuery(key: key),
      builder.updateQuery(key: key),
      builder.deleteQuery(key: key),
      builder.keysQuery(),
    ]

    for query in queries {
      #expect(query[kSecClass] as? String == kSecClassGenericPassword as String)
      #expect(query[kSecAttrService] as? String == "com.example.app")
      #expect(query[kSecAttrAccessGroup] as? String == "TEAMID.com.example.app")
      #expect(query[kSecAttrSynchronizable] as? Bool == false)
      #expect(query[kSecUseDataProtectionKeychain] as? Bool == true)
    }
  }

  @Test("operation queries contain only their required attributes")
  func operationAttributes() throws {
    let configuration = try SecureStoreConfiguration(
      service: "com.example.app",
      accessibility: .afterFirstUnlock
    )
    let builder = SecItemQueryBuilder(configuration: configuration)
    let key = try SecureStoreKey("token")
    let data = Data("secret".utf8)

    let add = builder.addQuery(data: data as NSData, key: key)
    let read = builder.readQuery(key: key)
    let update = builder.updateQuery(key: key)
    let attributes = builder.updateAttributes(data: data as NSData)
    let keys = builder.keysQuery()

    #expect(add[kSecValueData] as? Data == data)
    #expect(add[kSecAttrAccessible] as? String == kSecAttrAccessibleAfterFirstUnlock as String)
    #expect(read[kSecReturnData] as? Bool == true)
    #expect(read[kSecMatchLimit] as? String == kSecMatchLimitOne as String)
    #expect(update[kSecValueData] == nil)
    #expect(attributes[kSecValueData] as? Data == data)
    #expect(
      attributes[kSecAttrAccessible] as? String
        == kSecAttrAccessibleAfterFirstUnlock as String
    )
    #expect(keys[kSecReturnAttributes] as? Bool == true)
    #expect(keys[kSecMatchLimit] as? String == kSecMatchLimitAll as String)
    #expect((keys[kSecUseAuthenticationContext] as? LAContext)?.interactionNotAllowed == true)
  }

  @Test("synchronized queries opt in without inventing an access group")
  func synchronizedQuery() throws {
    let configuration = try SecureStoreConfiguration(
      service: "com.example.app",
      synchronizesWithICloud: true
    )
    let builder = SecItemQueryBuilder(configuration: configuration)
    let query = builder.readQuery(key: try SecureStoreKey("token"))

    #expect(query[kSecAttrSynchronizable] as? Bool == true)
    #expect(query[kSecAttrAccessGroup] == nil)
  }
}
