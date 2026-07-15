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

  private let queryBuilder: SecItemQueryBuilder
  private let security: any SecurityItemClient

  public init(configuration: SecureStoreConfiguration) {
    self.init(configuration: configuration, security: SystemSecurityItemClient())
  }

  init(configuration: SecureStoreConfiguration, security: any SecurityItemClient) {
    self.configuration = configuration
    queryBuilder = SecItemQueryBuilder(configuration: configuration)
    self.security = security
  }

  public func save(_ data: Data, for key: SecureStoreKey) async throws {
    guard data.count <= configuration.maximumValueSize else {
      throw SecureStoreError.valueTooLarge(maximumBytes: configuration.maximumValueSize)
    }

    let addStatus = security.add(queryBuilder.addQuery(data: data, key: key))
    switch addStatus {
    case errSecSuccess:
      return
    case errSecDuplicateItem:
      let updateStatus = security.update(
        queryBuilder.updateQuery(key: key),
        attributes: queryBuilder.updateAttributes(data: data)
      )
      guard updateStatus == errSecSuccess else {
        throw SecureStoreError.from(status: updateStatus)
      }
    default:
      throw SecureStoreError.from(status: addStatus)
    }
  }

  public func read(for key: SecureStoreKey) async throws -> Data? {
    let result = security.copyMatching(queryBuilder.readQuery(key: key))
    switch result.status {
    case errSecSuccess:
      guard let data = result.value as? Data else {
        throw SecureStoreError.invalidData
      }
      return data
    case errSecItemNotFound:
      return nil
    default:
      throw SecureStoreError.from(status: result.status)
    }
  }

  public func delete(for key: SecureStoreKey) async throws {
    let status = security.delete(queryBuilder.deleteQuery(key: key))
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw SecureStoreError.from(status: status)
    }
  }

  public func keys() async throws -> [SecureStoreKey] {
    let result = security.copyMatching(queryBuilder.keysQuery())
    switch result.status {
    case errSecItemNotFound:
      return []
    case errSecSuccess:
      let attributes: [[CFString: Any]]
      if let values = result.value as? [[CFString: Any]] {
        attributes = values
      } else if let value = result.value as? [CFString: Any] {
        attributes = [value]
      } else {
        throw SecureStoreError.invalidData
      }

      return try attributes.map { item in
        guard let account = item[kSecAttrAccount] as? String else {
          throw SecureStoreError.invalidData
        }
        return try SecureStoreKey(account)
      }.sorted { $0.value < $1.value }
    default:
      throw SecureStoreError.from(status: result.status)
    }
  }
}
