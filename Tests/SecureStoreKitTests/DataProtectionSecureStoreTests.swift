//
//  DataProtectionSecureStoreTests.swift
//  SecureStoreKit
//
//  Created by SwiftMan on 7/15/26.
//  Copyright © 2026 SecureStoreKit. All rights reserved.
//

import Foundation
import Security
import Testing

@testable import SecureStoreKit

@Suite("Data Protection Secure Store")
struct DataProtectionSecureStoreTests {
  @Test("save adds a new item")
  func saveNewItem() async throws {
    let client = StubSecurityItemClient()
    let store = try makeStore(client: client)
    let data = Data("secret".utf8)

    try await store.save(data, for: "token")

    #expect(client.addCallCount == 1)
    #expect(client.updateCallCount == 0)
    #expect(client.lastAddAttributes?[kSecValueData] as? Data == data)
  }

  @Test("save rejects oversized values before contacting Security.framework")
  func saveOversizedValue() async throws {
    let client = StubSecurityItemClient()
    let store = try makeStore(client: client, maximumValueSize: 4)

    await #expect(throws: SecureStoreError.valueTooLarge(maximumBytes: 4)) {
      try await store.save(Data(repeating: 0, count: 5), for: "token")
    }
    #expect(client.addCallCount == 0)
  }

  @Test("save updates an existing item")
  func duplicateSaveUsesUpdate() async throws {
    let client = StubSecurityItemClient()
    client.addStatus = errSecDuplicateItem
    let store = try makeStore(client: client)
    let data = Data("secret".utf8)

    try await store.save(data, for: "token")

    #expect(client.updateCallCount == 1)
    #expect(client.lastUpdateQuery?[kSecValueData] == nil)
    #expect(client.lastUpdateAttributes?[kSecValueData] as? Data == data)
  }

  @Test("save maps add and update failures")
  func saveFailures() async throws {
    let addClient = StubSecurityItemClient()
    addClient.addStatus = errSecMissingEntitlement
    let addStore = try makeStore(client: addClient)

    await #expect(throws: SecureStoreError.missingEntitlement) {
      try await addStore.save(Data("secret".utf8), for: "token")
    }

    let updateClient = StubSecurityItemClient()
    updateClient.addStatus = errSecDuplicateItem
    updateClient.updateStatus = errSecAuthFailed
    let updateStore = try makeStore(client: updateClient)

    await #expect(throws: SecureStoreError.authenticationFailed) {
      try await updateStore.save(Data("secret".utf8), for: "token")
    }
  }

  @Test("read returns data and preserves missing-item semantics")
  func readResults() async throws {
    let client = StubSecurityItemClient()
    let store = try makeStore(client: client)
    let data = Data("secret".utf8)

    client.copyResult = SecurityItemCopyResult(status: errSecSuccess, value: data as CFData)
    #expect(try await store.read(for: "token") == data)

    client.copyResult = SecurityItemCopyResult(status: errSecItemNotFound, value: nil)
    #expect(try await store.read(for: "missing") == nil)
  }

  @Test("read rejects malformed results and maps failures")
  func readFailures() async throws {
    let client = StubSecurityItemClient()
    let store = try makeStore(client: client)

    client.copyResult = SecurityItemCopyResult(
      status: errSecSuccess,
      value: "not data" as CFString
    )
    await #expect(throws: SecureStoreError.invalidData) {
      try await store.read(for: "token")
    }

    client.copyResult = SecurityItemCopyResult(status: errSecInteractionNotAllowed, value: nil)
    await #expect(throws: SecureStoreError.interactionRequired) {
      try await store.read(for: "token")
    }
  }

  @Test("delete is idempotent and maps failures")
  func deleteResults() async throws {
    let client = StubSecurityItemClient()
    let store = try makeStore(client: client)

    client.deleteStatus = errSecSuccess
    try await store.delete(for: "token")

    client.deleteStatus = errSecItemNotFound
    try await store.delete(for: "missing")

    client.deleteStatus = errSecWrPerm
    await #expect(throws: SecureStoreError.permissionDenied) {
      try await store.delete(for: "token")
    }
  }

  @Test("keys returns empty, array, and single-item results")
  func keyResults() async throws {
    let client = StubSecurityItemClient()
    let store = try makeStore(client: client)

    client.copyResult = SecurityItemCopyResult(status: errSecItemNotFound, value: nil)
    #expect(try await store.keys().isEmpty)

    let attributes: [[String: Any]] = [
      [kSecAttrAccount as String: "z-key"],
      [kSecAttrAccount as String: "a-key"],
    ]
    client.copyResult = SecurityItemCopyResult(
      status: errSecSuccess,
      value: attributes as CFArray
    )
    #expect(try await store.keys().map(\.value) == ["a-key", "z-key"])

    let singleAttribute: [String: Any] = [kSecAttrAccount as String: "single-key"]
    client.copyResult = SecurityItemCopyResult(
      status: errSecSuccess,
      value: singleAttribute as CFDictionary
    )
    #expect(try await store.keys().map(\.value) == ["single-key"])
  }

  @Test("keys validates result shapes, accounts, and status")
  func keyFailures() async throws {
    let client = StubSecurityItemClient()
    let store = try makeStore(client: client)

    client.copyResult = SecurityItemCopyResult(
      status: errSecSuccess,
      value: Data() as CFData
    )
    await #expect(throws: SecureStoreError.invalidData) {
      try await store.keys()
    }

    let missingAccount: [String: Any] = [kSecAttrLabel as String: "label"]
    client.copyResult = SecurityItemCopyResult(
      status: errSecSuccess,
      value: missingAccount as CFDictionary
    )
    await #expect(throws: SecureStoreError.invalidData) {
      try await store.keys()
    }

    let invalidAccount: [String: Any] = [kSecAttrAccount as String: "invalid\0key"]
    client.copyResult = SecurityItemCopyResult(
      status: errSecSuccess,
      value: invalidAccount as CFDictionary
    )
    await #expect(throws: SecureStoreError.invalidKey) {
      try await store.keys()
    }

    client.copyResult = SecurityItemCopyResult(status: errSecNotAvailable, value: nil)
    await #expect(throws: SecureStoreError.unavailable) {
      try await store.keys()
    }
  }

  private func makeStore(
    client: StubSecurityItemClient,
    maximumValueSize: Int = SecureStoreConfiguration.defaultMaximumValueSize
  ) throws -> DataProtectionSecureStore {
    let configuration = try SecureStoreConfiguration(
      service: "com.example.app",
      maximumValueSize: maximumValueSize
    )
    return DataProtectionSecureStore(configuration: configuration, security: client)
  }
}
