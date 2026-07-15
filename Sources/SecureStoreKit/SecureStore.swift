//
//  SecureStore.swift
//  SecureStoreKit
//
//  Created by SwiftMan on 7/15/26.
//  Copyright © 2026 SecureStoreKit. All rights reserved.
//

import Foundation

/// A validated, non-secret identifier for one value in a secure store.
public struct SecureStoreKey: Hashable, Sendable, CustomStringConvertible {
  public static let maximumUTF8Length = 512

  public let value: String

  public init(_ value: String) throws {
    guard !value.isEmpty,
      value.utf8.count <= Self.maximumUTF8Length,
      !value.unicodeScalars.contains(where: { $0.value == 0 })
    else {
      throw SecureStoreError.invalidKey
    }
    self.value = value
  }

  public var description: String { value }
}

/// The app-owned contract for storing small secret values.
public protocol SecureStore: Sendable {
  func save(_ data: Data, for key: SecureStoreKey) async throws
  func read(for key: SecureStoreKey) async throws -> Data?
  func delete(for key: SecureStoreKey) async throws
  func keys() async throws -> [SecureStoreKey]
}

extension SecureStore {
  public func save(_ data: Data, for key: String) async throws {
    try await save(data, for: SecureStoreKey(key))
  }

  public func read(for key: String) async throws -> Data? {
    try await read(for: SecureStoreKey(key))
  }

  public func delete(for key: String) async throws {
    try await delete(for: SecureStoreKey(key))
  }
}
