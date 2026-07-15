//
//  SecureStoreConfigurationTests.swift
//  SecureStoreKit
//
//  Created by SwiftMan on 7/15/26.
//  Copyright © 2026 SecureStoreKit. All rights reserved.
//

import Security
import Testing

@testable import SecureStoreKit

@Suite("Secure Store configuration")
struct SecureStoreConfigurationTests {
  @Test("configuration accepts supported defaults and synchronization")
  func validConfiguration() throws {
    let defaults = try SecureStoreConfiguration(service: "com.example.app")
    let synchronized = try SecureStoreConfiguration(
      service: "com.example.app",
      accessGroup: "TEAMID.com.example.app",
      accessibility: .afterFirstUnlock,
      synchronizesWithICloud: true,
      maximumValueSize: 32
    )

    #expect(defaults.accessGroup == nil)
    #expect(defaults.accessibility == .whenUnlocked)
    #expect(defaults.synchronizesWithICloud == false)
    #expect(SecureStoreConfiguration.defaultMaximumValueSize == 65_536)
    #expect(defaults.maximumValueSize == SecureStoreConfiguration.defaultMaximumValueSize)
    #expect(synchronized.accessGroup == "TEAMID.com.example.app")
    #expect(synchronized.synchronizesWithICloud)
    #expect(synchronized.maximumValueSize == 32)
  }

  @Test("configuration rejects invalid identifiers, sizes, and synchronization policies")
  func invalidConfiguration() {
    #expect(throws: SecureStoreError.invalidService) {
      _ = try SecureStoreConfiguration(service: "")
    }
    #expect(throws: SecureStoreError.invalidService) {
      _ = try SecureStoreConfiguration(service: "invalid\0service")
    }
    #expect(throws: SecureStoreError.invalidAccessGroup) {
      _ = try SecureStoreConfiguration(service: "com.example.app", accessGroup: "")
    }
    #expect(throws: SecureStoreError.invalidAccessGroup) {
      _ = try SecureStoreConfiguration(
        service: "com.example.app",
        accessGroup: "invalid\0group"
      )
    }
    #expect(throws: SecureStoreError.invalidMaximumValueSize) {
      _ = try SecureStoreConfiguration(service: "com.example.app", maximumValueSize: 0)
    }

    for accessibility in [
      SecureStoreAccessibility.whenUnlockedThisDeviceOnly,
      .afterFirstUnlockThisDeviceOnly,
    ] {
      #expect(throws: SecureStoreError.incompatibleSynchronizationAccessibility) {
        _ = try SecureStoreConfiguration(
          service: "com.example.app",
          accessibility: accessibility,
          synchronizesWithICloud: true
        )
      }
    }
  }

  @Test("keys validate UTF-8 length and null characters")
  func keyValidation() throws {
    let maximumLengthKey = String(
      repeating: "é",
      count: SecureStoreKey.maximumUTF8Length / 2
    )

    let key = try SecureStoreKey(maximumLengthKey)

    #expect(key.value == maximumLengthKey)
    #expect(key.description == maximumLengthKey)
    #expect(throws: SecureStoreError.invalidKey) { _ = try SecureStoreKey("") }
    #expect(throws: SecureStoreError.invalidKey) {
      _ = try SecureStoreKey(maximumLengthKey + "é")
    }
    #expect(throws: SecureStoreError.invalidKey) {
      _ = try SecureStoreKey("invalid\0key")
    }
  }

  @Test("Security statuses map to stable package errors")
  func errorMapping() {
    let mappings: [(OSStatus, SecureStoreError)] = [
      (errSecAuthFailed, .authenticationFailed),
      (errSecUserCanceled, .cancelled),
      (errSecInteractionNotAllowed, .interactionRequired),
      (errSecInteractionRequired, .interactionRequired),
      (errSecMissingEntitlement, .missingEntitlement),
      (errSecNoAccessForItem, .permissionDenied),
      (errSecWrPerm, .permissionDenied),
      (errSecReadOnly, .permissionDenied),
      (errSecNotAvailable, .unavailable),
      (errSecNoDefaultKeychain, .unavailable),
      (errSecNoSuchKeychain, .unavailable),
      (errSecDecode, .invalidData),
    ]

    for (status, expectedError) in mappings {
      #expect(SecureStoreError.from(status: status) == expectedError)
    }
    #expect(SecureStoreError.from(status: -99_999) == .unexpectedStatus(-99_999))
  }

  @Test("all public errors provide non-secret user descriptions")
  func errorDescriptions() {
    let errors: [SecureStoreError] = [
      .invalidService,
      .invalidAccessGroup,
      .invalidMaximumValueSize,
      .incompatibleSynchronizationAccessibility,
      .invalidKey,
      .valueTooLarge(maximumBytes: 8),
      .authenticationFailed,
      .cancelled,
      .interactionRequired,
      .permissionDenied,
      .missingEntitlement,
      .unavailable,
      .invalidData,
      .unexpectedStatus(-99_999),
    ]

    for error in errors {
      let description = error.errorDescription
      #expect(description?.isEmpty == false)
      #expect(description?.contains("actual-secret") == false)
    }
  }
}
