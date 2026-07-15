//
//  InMemorySecureStore.swift
//  SecureStoreKit
//
//  Created by SwiftMan on 7/15/26.
//  Copyright © 2026 SecureStoreKit. All rights reserved.
//

import Foundation
import SecureStoreKit

/// Deterministic SecureStore replacement for previews and unit tests.
public actor InMemorySecureStore: SecureStore {
  private var storage: [SecureStoreKey: SecureBytes]
  private let maximumValueSize: Int

  public init() {
    storage = [:]
    maximumValueSize = SecureStoreConfiguration.defaultMaximumValueSize
  }

  public init(initialValues: [SecureStoreKey: Data], maximumValueSize: Int) throws {
    guard maximumValueSize > 0 else {
      throw SecureStoreError.invalidMaximumValueSize
    }
    guard initialValues.values.allSatisfy({ $0.count <= maximumValueSize }) else {
      throw SecureStoreError.valueTooLarge(maximumBytes: maximumValueSize)
    }
    storage = initialValues.mapValues { SecureBytes(copying: $0) }
    self.maximumValueSize = maximumValueSize
  }

  public func save(_ data: Data, for key: SecureStoreKey) async throws {
    guard data.count <= maximumValueSize else {
      throw SecureStoreError.valueTooLarge(maximumBytes: maximumValueSize)
    }
    storage[key] = SecureBytes(copying: data)
  }

  public func save(_ bytes: SecureBytes, for key: SecureStoreKey) async throws {
    guard bytes.count <= maximumValueSize else {
      throw SecureStoreError.valueTooLarge(maximumBytes: maximumValueSize)
    }
    storage[key] = SecureBytes(copying: bytes)
  }

  public func read(for key: SecureStoreKey) async throws -> Data? {
    storage[key]?.withUnsafeBytes { Data($0) }
  }

  public func readSecureBytes(for key: SecureStoreKey) async throws -> SecureBytes? {
    storage[key].map { SecureBytes(copying: $0) }
  }

  public func delete(for key: SecureStoreKey) async throws {
    storage.removeValue(forKey: key)
  }

  public func keys() async throws -> [SecureStoreKey] {
    storage.keys.sorted { $0.value < $1.value }
  }

  public func removeAll() {
    storage.removeAll(keepingCapacity: false)
  }
}
