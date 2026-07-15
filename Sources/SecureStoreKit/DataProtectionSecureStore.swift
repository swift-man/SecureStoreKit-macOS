//
//  DataProtectionSecureStore.swift
//  SecureStoreKit
//
//  Created by SwiftMan on 7/15/26.
//  Copyright © 2026 SecureStoreKit. All rights reserved.
//

import Foundation
import Security

/// Serializes Data Protection Keychain operations for one app-provided namespace.
public actor DataProtectionSecureStore: SecureStore {
  public let configuration: SecureStoreConfiguration

  private static let maximumUpsertAttempts = 3

  private let queryBuilder: SecItemQueryBuilder
  private let security: any SecurityItemClient
  private let operationQueue: SecurityOperationQueue

  public init(configuration: SecureStoreConfiguration) {
    self.init(configuration: configuration, security: SystemSecurityItemClient())
  }

  init(
    configuration: SecureStoreConfiguration,
    security: any SecurityItemClient,
    operationQueue: SecurityOperationQueue = SecurityOperationQueue()
  ) {
    self.configuration = configuration
    queryBuilder = SecItemQueryBuilder(configuration: configuration)
    self.security = security
    self.operationQueue = operationQueue
  }

  public func save(_ data: Data, for key: SecureStoreKey) async throws {
    guard data.count <= configuration.maximumValueSize else {
      throw SecureStoreError.valueTooLarge(maximumBytes: configuration.maximumValueSize)
    }

    let security = security
    let queryBuilder = queryBuilder
    try await operationQueue.run {
      try Self.upsert(data as NSData, for: key, queryBuilder: queryBuilder, security: security)
    }
  }

  public func save(_ bytes: SecureBytes, for key: SecureStoreKey) async throws {
    guard bytes.count <= configuration.maximumValueSize else {
      throw SecureStoreError.valueTooLarge(maximumBytes: configuration.maximumValueSize)
    }

    let security = security
    let queryBuilder = queryBuilder
    try await operationQueue.run {
      try Self.upsert(
        bytes.borrowedNSData(),
        for: key,
        queryBuilder: queryBuilder,
        security: security
      )
    }
  }

  public func read(for key: SecureStoreKey) async throws -> Data? {
    try await readValue(for: key) { $0 }
  }

  public func readSecureBytes(for key: SecureStoreKey) async throws -> SecureBytes? {
    try await readValue(for: key) { SecureBytes(copying: $0) }
  }

  public func delete(for key: SecureStoreKey) async throws {
    let security = security
    let queryBuilder = queryBuilder
    try await operationQueue.run {
      let status = security.delete(queryBuilder.deleteQuery(key: key))
      guard status == errSecSuccess || status == errSecItemNotFound else {
        throw SecureStoreError.from(status: status)
      }
    }
  }

  public func keys() async throws -> [SecureStoreKey] {
    let security = security
    let queryBuilder = queryBuilder
    return try await operationQueue.run {
      let result = security.copyMatching(queryBuilder.keysQuery())
      switch result.status {
      case errSecItemNotFound:
        return []
      case errSecSuccess:
        let attributes: [[String: Any]]
        if let values = result.value as? [[String: Any]] {
          attributes = values
        } else if let value = result.value as? [String: Any] {
          attributes = [value]
        } else {
          throw SecureStoreError.invalidData
        }

        return try attributes.map { item in
          guard let account = item[kSecAttrAccount as String] as? String else {
            throw SecureStoreError.invalidData
          }
          return try SecureStoreKey(account)
        }.sorted { $0.value < $1.value }
      default:
        throw SecureStoreError.from(status: result.status)
      }
    }
  }

  private func readValue<Value: Sendable>(
    for key: SecureStoreKey,
    transform: @escaping @Sendable (Data) throws -> Value
  ) async throws -> Value? {
    let security = security
    let queryBuilder = queryBuilder
    return try await operationQueue.run {
      let result = security.copyMatching(queryBuilder.readQuery(key: key))
      switch result.status {
      case errSecSuccess:
        guard let data = result.value as? Data else {
          throw SecureStoreError.invalidData
        }
        return try transform(data)
      case errSecItemNotFound:
        return nil
      default:
        throw SecureStoreError.from(status: result.status)
      }
    }
  }

  private static func upsert(
    _ data: NSData,
    for key: SecureStoreKey,
    queryBuilder: SecItemQueryBuilder,
    security: any SecurityItemClient
  ) throws {
    var attempt = 1
    while true {
      let addStatus = security.add(queryBuilder.addQuery(data: data, key: key))
      switch addStatus {
      case errSecSuccess:
        return
      case errSecDuplicateItem:
        let updateStatus = security.update(
          queryBuilder.updateQuery(key: key),
          attributes: queryBuilder.updateAttributes(data: data)
        )
        switch updateStatus {
        case errSecSuccess:
          return
        case errSecItemNotFound where attempt < maximumUpsertAttempts:
          attempt += 1
          continue
        default:
          throw SecureStoreError.from(status: updateStatus)
        }
      default:
        throw SecureStoreError.from(status: addStatus)
      }
    }
  }
}
