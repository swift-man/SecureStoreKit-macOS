//
//  InMemorySecureStoreTests.swift
//  SecureStoreKit
//
//  Created by SwiftMan on 7/15/26.
//  Copyright © 2026 SecureStoreKit. All rights reserved.
//

import Foundation
import SecureStoreTesting
import Testing

@testable import SecureStoreKit

@Suite("In-memory Secure Store")
struct InMemorySecureStoreTests {
  @Test("in-memory store follows the observable SecureStore contract")
  func storeContract() async throws {
    let defaultStore = InMemorySecureStore()
    let store = try InMemorySecureStore(initialValues: [:], maximumValueSize: 8)
    let value = Data("secret".utf8)

    #expect(try await defaultStore.keys().isEmpty)
    try await store.save(value, for: "token")
    #expect(try await store.read(for: "token") == value)
    #expect(try await store.keys().map(\.value) == ["token"])

    try await store.delete(for: "token")
    #expect(try await store.read(for: "token") == nil)

    try await store.save(value, for: "another-token")
    await store.removeAll()
    #expect(try await store.keys().isEmpty)
  }

  @Test("in-memory store enforces initialization and save size limits")
  func sizeLimits() async throws {
    let key = try SecureStoreKey("token")

    #expect(throws: SecureStoreError.invalidMaximumValueSize) {
      _ = try InMemorySecureStore(initialValues: [:], maximumValueSize: 0)
    }
    #expect(throws: SecureStoreError.valueTooLarge(maximumBytes: 2)) {
      _ = try InMemorySecureStore(
        initialValues: [key: Data(repeating: 0, count: 3)],
        maximumValueSize: 2
      )
    }

    let store = try InMemorySecureStore(initialValues: [:], maximumValueSize: 2)
    try await store.save(Data(repeating: 0, count: 2), for: key)
    await #expect(throws: SecureStoreError.valueTooLarge(maximumBytes: 2)) {
      try await store.save(Data(repeating: 0, count: 3), for: key)
    }
  }

  @Test("in-memory store snapshots SecureBytes values")
  func secureBytesContract() async throws {
    let store: any SecureStore = try InMemorySecureStore(initialValues: [:], maximumValueSize: 8)
    let value = SecureBytes(copying: Data("secret".utf8))

    try await store.save(value, for: "token")
    let restored = try #require(try await store.readSecureBytes(for: "token"))

    #expect(restored !== value)
    #expect(restored.withUnsafeBytes { Array($0) } == Array("secret".utf8))

    let oversized = SecureBytes(copying: Data(repeating: 0, count: 9))
    await #expect(throws: SecureStoreError.valueTooLarge(maximumBytes: 8)) {
      try await store.save(oversized, for: "oversized")
    }
  }
}
