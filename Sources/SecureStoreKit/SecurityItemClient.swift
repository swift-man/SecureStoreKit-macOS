//
//  SecurityItemClient.swift
//  SecureStoreKit
//
//  Created by SwiftMan on 7/15/26.
//  Copyright © 2026 SecureStoreKit. All rights reserved.
//

import Foundation
import Security

/// Isolates Security.framework calls so the public store can be tested without a signed host app.
protocol SecurityItemClient: Sendable {
  func add(_ attributes: [CFString: Any]) -> OSStatus
  func update(_ query: [CFString: Any], attributes: [CFString: Any]) -> OSStatus
  func copyMatching(_ query: [CFString: Any]) -> SecurityItemCopyResult
  func delete(_ query: [CFString: Any]) -> OSStatus
}

struct SecurityItemCopyResult {
  let status: OSStatus
  let value: CFTypeRef?
}

/// Thin adapter over SecItem with no logging or shell interaction.
struct SystemSecurityItemClient: SecurityItemClient {
  func add(_ attributes: [CFString: Any]) -> OSStatus {
    SecItemAdd(attributes as CFDictionary, nil)
  }

  func update(_ query: [CFString: Any], attributes: [CFString: Any]) -> OSStatus {
    SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
  }

  func copyMatching(_ query: [CFString: Any]) -> SecurityItemCopyResult {
    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    return SecurityItemCopyResult(status: status, value: result)
  }

  func delete(_ query: [CFString: Any]) -> OSStatus {
    SecItemDelete(query as CFDictionary)
  }
}
