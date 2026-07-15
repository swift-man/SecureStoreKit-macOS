//
//  SecurityOperationQueueTests.swift
//  SecureStoreKit
//
//  Created by SwiftMan on 7/15/26.
//  Copyright © 2026 SecureStoreKit. All rights reserved.
//

import Dispatch
import Foundation
import Testing

@testable import SecureStoreKit

@Suite("Security operation queue")
struct SecurityOperationQueueTests {
  @Test("operations execute serially and preserve failures")
  func serialExecutionAndFailurePropagation() async throws {
    let queue = SecurityOperationQueue(label: "test.security-operation-queue")
    let events = LockedEvents()
    let releaseFirst = DispatchSemaphore(value: 0)
    let (firstStarted, firstStartedContinuation) = AsyncStream.makeStream(
      of: Void.self,
      bufferingPolicy: .bufferingNewest(1)
    )

    let firstTask = Task {
      try await queue.run {
        events.append("first-start")
        firstStartedContinuation.yield()
        releaseFirst.wait()
        events.append("first-end")
      }
    }

    var startedIterator = firstStarted.makeAsyncIterator()
    _ = await startedIterator.next()

    let secondTask = Task {
      try await queue.run {
        events.append("second")
      }
    }

    releaseFirst.signal()
    try await firstTask.value
    try await secondTask.value

    #expect(events.snapshot == ["first-start", "first-end", "second"])
    await #expect(throws: QueueTestError.expected) {
      try await queue.run {
        throw QueueTestError.expected
      }
    }
  }
}

private enum QueueTestError: Error {
  case expected
}

private final class LockedEvents: @unchecked Sendable {
  private let lock = NSLock()
  private var events: [String] = []

  var snapshot: [String] {
    lock.withLock { events }
  }

  func append(_ event: String) {
    lock.withLock {
      events.append(event)
    }
  }
}
