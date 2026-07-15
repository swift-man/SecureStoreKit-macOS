//
//  SecureBytes.swift
//  SecureStoreKit
//
//  Created by SwiftMan on 7/15/26.
//  Copyright © 2026 SecureStoreKit. All rights reserved.
//

import Darwin
import Foundation

/// An immutable, reference-counted Secret buffer that zeroes its owned memory before release.
public final class SecureBytes: @unchecked Sendable, ContiguousBytes,
  CustomStringConvertible, CustomDebugStringConvertible
{
  private let storage: SecureBytesStorage

  /// Copies bytes into a dedicated allocation owned by this value.
  public init<Bytes: ContiguousBytes>(copying bytes: Bytes) {
    storage = bytes.withUnsafeBytes {
      SecureBytesStorage(copying: $0, didZeroize: nil)
    }
  }

  init<Bytes: ContiguousBytes>(
    copying bytes: Bytes,
    didZeroize: @escaping @Sendable (UnsafeRawBufferPointer) -> Void
  ) {
    storage = bytes.withUnsafeBytes {
      SecureBytesStorage(copying: $0, didZeroize: didZeroize)
    }
  }

  public var count: Int { storage.count }
  public var isEmpty: Bool { count == 0 }

  public var description: String {
    "SecureBytes(count: \(count), contents: <redacted>)"
  }

  public var debugDescription: String { description }

  /// Provides temporary read-only access. The pointer must not escape the closure.
  public func withUnsafeBytes<Result>(
    _ body: (UnsafeRawBufferPointer) throws -> Result
  ) rethrows -> Result {
    try storage.withUnsafeBytes(body)
  }

  /// Creates an immutable no-copy NSData view that keeps the allocation alive for its lifetime.
  func borrowedNSData() -> NSData {
    storage.borrowedNSData()
  }
}

private final class SecureBytesStorage: @unchecked Sendable {
  let count: Int

  private let pointer: UnsafeMutableRawPointer
  private let didZeroize: (@Sendable (UnsafeRawBufferPointer) -> Void)?

  init(
    copying source: UnsafeRawBufferPointer,
    didZeroize: (@Sendable (UnsafeRawBufferPointer) -> Void)?
  ) {
    count = source.count
    pointer = UnsafeMutableRawPointer.allocate(
      byteCount: max(source.count, 1),
      alignment: MemoryLayout<UInt8>.alignment
    )
    self.didZeroize = didZeroize

    if let sourceAddress = source.baseAddress, !source.isEmpty {
      pointer.copyMemory(from: sourceAddress, byteCount: source.count)
    }
  }

  deinit {
    let buffer = UnsafeMutableRawBufferPointer(start: pointer, count: count)
    securelyZero(buffer)
    didZeroize?(UnsafeRawBufferPointer(buffer))
    pointer.deallocate()
  }

  func withUnsafeBytes<Result>(
    _ body: (UnsafeRawBufferPointer) throws -> Result
  ) rethrows -> Result {
    try body(UnsafeRawBufferPointer(start: pointer, count: count))
  }

  func borrowedNSData() -> NSData {
    let storage = self
    return NSData(
      bytesNoCopy: pointer,
      length: count,
      deallocator: { _, _ in
        withExtendedLifetime(storage) {}
      }
    )
  }
}

func securelyZero(_ buffer: UnsafeMutableRawBufferPointer) {
  guard let baseAddress = buffer.baseAddress, !buffer.isEmpty else { return }
  _ = memset_s(baseAddress, buffer.count, 0, buffer.count)
}
