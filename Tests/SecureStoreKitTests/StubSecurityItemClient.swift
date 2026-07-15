//
//  StubSecurityItemClient.swift
//  SecureStoreKit
//
//  Created by SwiftMan on 7/15/26.
//  Copyright © 2026 SecureStoreKit. All rights reserved.
//

import Foundation
import Security

@testable import SecureStoreKit

final class StubSecurityItemClient: SecurityItemClient, @unchecked Sendable {
  private let lock = NSLock()
  private var state = State()

  var addStatus: OSStatus {
    get { lock.withLock { state.addStatuses[0] } }
    set { lock.withLock { state.addStatuses = [newValue] } }
  }

  var updateStatus: OSStatus {
    get { lock.withLock { state.updateStatuses[0] } }
    set { lock.withLock { state.updateStatuses = [newValue] } }
  }

  var addStatuses: [OSStatus] {
    get { lock.withLock { state.addStatuses } }
    set {
      precondition(!newValue.isEmpty)
      lock.withLock { state.addStatuses = newValue }
    }
  }

  var updateStatuses: [OSStatus] {
    get { lock.withLock { state.updateStatuses } }
    set {
      precondition(!newValue.isEmpty)
      lock.withLock { state.updateStatuses = newValue }
    }
  }

  var copyResult: SecurityItemCopyResult {
    get { lock.withLock { state.copyResult } }
    set { lock.withLock { state.copyResult = newValue } }
  }

  var deleteStatus: OSStatus {
    get { lock.withLock { state.deleteStatus } }
    set { lock.withLock { state.deleteStatus = newValue } }
  }

  var addCallCount: Int { lock.withLock { state.addCallCount } }
  var updateCallCount: Int { lock.withLock { state.updateCallCount } }
  var lastAddAttributes: [CFString: Any]? { lock.withLock { state.lastAddAttributes } }
  var lastUpdateQuery: [CFString: Any]? { lock.withLock { state.lastUpdateQuery } }
  var lastUpdateAttributes: [CFString: Any]? {
    lock.withLock { state.lastUpdateAttributes }
  }

  func add(_ attributes: [CFString: Any]) -> OSStatus {
    lock.withLock {
      state.addCallCount += 1
      state.lastAddAttributes = attributes
      return state.addStatuses.nextStatus()
    }
  }

  func update(_ query: [CFString: Any], attributes: [CFString: Any]) -> OSStatus {
    lock.withLock {
      state.updateCallCount += 1
      state.lastUpdateQuery = query
      state.lastUpdateAttributes = attributes
      return state.updateStatuses.nextStatus()
    }
  }

  func copyMatching(_ query: [CFString: Any]) -> SecurityItemCopyResult {
    lock.withLock { state.copyResult }
  }

  func delete(_ query: [CFString: Any]) -> OSStatus {
    lock.withLock { state.deleteStatus }
  }
}

private struct State {
  var addStatuses: [OSStatus] = [errSecSuccess]
  var updateStatuses: [OSStatus] = [errSecSuccess]
  var copyResult = SecurityItemCopyResult(status: errSecItemNotFound, value: nil)
  var deleteStatus: OSStatus = errSecSuccess
  var addCallCount = 0
  var updateCallCount = 0
  var lastAddAttributes: [CFString: Any]?
  var lastUpdateQuery: [CFString: Any]?
  var lastUpdateAttributes: [CFString: Any]?
}

extension Array where Element == OSStatus {
  fileprivate mutating func nextStatus() -> OSStatus {
    if count > 1 {
      return removeFirst()
    }
    return self[0]
  }
}
