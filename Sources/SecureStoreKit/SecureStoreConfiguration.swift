//
//  SecureStoreConfiguration.swift
//  SecureStoreKit
//
//  Created by SwiftMan on 7/15/26.
//  Copyright © 2026 SecureStoreKit. All rights reserved.
//

import Foundation
import Security

/// Accessibility policies supported by the Data Protection Keychain adapter.
public enum SecureStoreAccessibility: String, CaseIterable, Sendable {
  case whenUnlocked
  case whenUnlockedThisDeviceOnly
  case afterFirstUnlock
  case afterFirstUnlockThisDeviceOnly

  var securityValue: CFString {
    switch self {
    case .whenUnlocked:
      kSecAttrAccessibleWhenUnlocked
    case .whenUnlockedThisDeviceOnly:
      kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    case .afterFirstUnlock:
      kSecAttrAccessibleAfterFirstUnlock
    case .afterFirstUnlockThisDeviceOnly:
      kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    }
  }

  var isDeviceOnly: Bool {
    switch self {
    case .whenUnlockedThisDeviceOnly, .afterFirstUnlockThisDeviceOnly:
      true
    case .whenUnlocked, .afterFirstUnlock:
      false
    }
  }
}

/// Immutable namespace and storage policy supplied by the host app.
public struct SecureStoreConfiguration: Equatable, Sendable {
  public static let defaultMaximumValueSize = 65_536

  public let service: String
  public let accessGroup: String?
  public let accessibility: SecureStoreAccessibility
  public let synchronizesWithICloud: Bool
  public let maximumValueSize: Int

  public init(
    service: String,
    accessGroup: String? = nil,
    accessibility: SecureStoreAccessibility = .whenUnlocked,
    synchronizesWithICloud: Bool = false,
    maximumValueSize: Int = Self.defaultMaximumValueSize
  ) throws {
    guard Self.isValidIdentifier(service) else {
      throw SecureStoreError.invalidService
    }
    if let accessGroup, !Self.isValidIdentifier(accessGroup) {
      throw SecureStoreError.invalidAccessGroup
    }
    guard maximumValueSize > 0 else {
      throw SecureStoreError.invalidMaximumValueSize
    }
    guard !synchronizesWithICloud || !accessibility.isDeviceOnly else {
      throw SecureStoreError.incompatibleSynchronizationAccessibility
    }

    self.service = service
    self.accessGroup = accessGroup
    self.accessibility = accessibility
    self.synchronizesWithICloud = synchronizesWithICloud
    self.maximumValueSize = maximumValueSize
  }

  private static func isValidIdentifier(_ value: String) -> Bool {
    !value.isEmpty && !value.unicodeScalars.contains(where: { $0.value == 0 })
  }
}
