//
//  SecurityOperationQueue.swift
//  SecureStoreKit
//
//  Created by SwiftMan on 7/15/26.
//  Copyright © 2026 SecureStoreKit. All rights reserved.
//

import Dispatch

/// Runs blocking Security.framework work away from Swift's cooperative executor.
final class SecurityOperationQueue: @unchecked Sendable {
  private let queue: DispatchQueue

  init(label: String = "me.gorani.SecureStoreKit.security-operations") {
    queue = DispatchQueue(label: label, qos: .userInitiated)
  }

  func run<T: Sendable>(
    _ operation: @escaping @Sendable () throws -> T
  ) async throws -> T {
    try await withCheckedThrowingContinuation { continuation in
      queue.async {
        continuation.resume(with: Result(catching: operation))
      }
    }
  }
}
