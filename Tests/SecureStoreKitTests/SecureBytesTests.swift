//
//  SecureBytesTests.swift
//  SecureStoreKit
//
//  Created by SwiftMan on 7/15/26.
//  Copyright © 2026 SecureStoreKit. All rights reserved.
//

import Foundation
import Testing

@testable import SecureStoreKit

@Suite("Secure Bytes")
struct SecureBytesTests {
  @Test("SecureBytes owns an immutable copy and redacts descriptions")
  func ownedCopyAndRedactedDescription() {
    var source = Data("actual-secret".utf8)
    let bytes = SecureBytes(copying: source)

    source.resetBytes(in: source.indices)

    #expect(bytes.count == 13)
    #expect(!bytes.isEmpty)
    #expect(bytes.withUnsafeBytes { Array($0) } == Array("actual-secret".utf8))
    #expect(!bytes.description.contains("actual-secret"))
    #expect(!bytes.debugDescription.contains("actual-secret"))
  }

  @Test("SecureBytes supports an empty value")
  func emptyValue() {
    let bytes = SecureBytes(copying: Data())

    #expect(bytes.count == 0)
    #expect(bytes.isEmpty)
    #expect(bytes.withUnsafeBytes { $0.isEmpty })
    #expect(bytes.borrowedNSData().length == 0)
  }

  @Test("SecureBytes zeroes its owned allocation before release")
  func zeroizesBeforeRelease() {
    let observation = ZeroizationObservation()

    func allocateAndRelease() {
      let bytes = SecureBytes(
        copying: Data([0xA5, 0x5A, 0xFF, 0x01]),
        didZeroize: observation.record
      )
      #expect(bytes.withUnsafeBytes { Array($0) } == [0xA5, 0x5A, 0xFF, 0x01])
      withExtendedLifetime(bytes) {}
    }

    allocateAndRelease()

    #expect(observation.snapshot == [0, 0, 0, 0])
  }

  @Test("borrowed NSData shares storage and extends its zeroization lifetime")
  func borrowedNSDataLifetime() {
    let observation = ZeroizationObservation()

    autoreleasepool {
      var data: NSData?

      func makeBorrowedData() {
        let bytes = SecureBytes(
          copying: Data(repeating: 0xA5, count: 64),
          didZeroize: observation.record
        )
        data = bytes.borrowedNSData()

        let secureAddress = bytes.withUnsafeBytes { $0.baseAddress }
        let dataAddress = data?.bytes
        #expect(secureAddress == dataAddress)
      }

      makeBorrowedData()
      #expect(observation.snapshot == nil)
      #expect(data?.isEqual(to: Data(repeating: 0xA5, count: 64)) == true)

      data = nil
    }

    #expect(observation.snapshot == Array(repeating: 0, count: 64))
  }

  @Test("SecureStore default adapters preserve Data-only conformers")
  func dataOnlyConformerCompatibility() async throws {
    let store: any SecureStore = DataOnlySecureStore()
    let value = SecureBytes(copying: Data("secret".utf8))

    try await store.save(value, for: "token")
    let restored = try #require(try await store.readSecureBytes(for: "token"))

    #expect(restored.withUnsafeBytes { Array($0) } == Array("secret".utf8))
    #expect(try await store.readSecureBytes(for: "missing") == nil)
  }

  @Test("SecureStore default adapters preserve Data-only failures")
  func dataOnlyConformerFailures() async throws {
    let store: any SecureStore = FailingDataOnlySecureStore()
    let value = SecureBytes(copying: Data("secret".utf8))

    await #expect(throws: AdapterTestError.expected) {
      try await store.save(value, for: "token")
    }
    await #expect(throws: AdapterTestError.expected) {
      try await store.readSecureBytes(for: "token")
    }
  }
}

private final class ZeroizationObservation: @unchecked Sendable {
  private let lock = NSLock()
  private var bytes: [UInt8]?

  var snapshot: [UInt8]? {
    lock.withLock { bytes }
  }

  func record(_ buffer: UnsafeRawBufferPointer) {
    lock.withLock {
      bytes = Array(buffer)
    }
  }
}

private actor DataOnlySecureStore: SecureStore {
  private var storage: [SecureStoreKey: Data] = [:]

  func save(_ data: Data, for key: SecureStoreKey) async throws {
    storage[key] = data
  }

  func read(for key: SecureStoreKey) async throws -> Data? {
    storage[key]
  }

  func delete(for key: SecureStoreKey) async throws {
    storage.removeValue(forKey: key)
  }

  func keys() async throws -> [SecureStoreKey] {
    Array(storage.keys)
  }
}

private actor FailingDataOnlySecureStore: SecureStore {
  func save(_ data: Data, for key: SecureStoreKey) async throws {
    throw AdapterTestError.expected
  }

  func read(for key: SecureStoreKey) async throws -> Data? {
    throw AdapterTestError.expected
  }

  func delete(for key: SecureStoreKey) async throws {}

  func keys() async throws -> [SecureStoreKey] { [] }
}

private enum AdapterTestError: Error {
  case expected
}
