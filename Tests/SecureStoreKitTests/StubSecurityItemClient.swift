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
    get { lock.withLock { state.addStatus } }
    set { lock.withLock { state.addStatus = newValue } }
  }

  var updateStatus: OSStatus {
    get { lock.withLock { state.updateStatus } }
    set { lock.withLock { state.updateStatus = newValue } }
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
      return state.addStatus
    }
  }

  func update(_ query: [CFString: Any], attributes: [CFString: Any]) -> OSStatus {
    lock.withLock {
      state.updateCallCount += 1
      state.lastUpdateQuery = query
      state.lastUpdateAttributes = attributes
      return state.updateStatus
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
  var addStatus: OSStatus = errSecSuccess
  var updateStatus: OSStatus = errSecSuccess
  var copyResult = SecurityItemCopyResult(status: errSecItemNotFound, value: nil)
  var deleteStatus: OSStatus = errSecSuccess
  var addCallCount = 0
  var updateCallCount = 0
  var lastAddAttributes: [CFString: Any]?
  var lastUpdateQuery: [CFString: Any]?
  var lastUpdateAttributes: [CFString: Any]?
}
