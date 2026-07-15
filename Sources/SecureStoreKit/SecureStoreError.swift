//
//  SecureStoreError.swift
//  SecureStoreKit
//
//  Created by SwiftMan on 7/15/26.
//  Copyright © 2026 SecureStoreKit. All rights reserved.
//

import Foundation
import Security

/// Stable errors that prevent Security.framework details from leaking into feature code.
public enum SecureStoreError: LocalizedError, Equatable, Sendable {
  case invalidService
  case invalidAccessGroup
  case invalidMaximumValueSize
  case incompatibleSynchronizationAccessibility
  case invalidKey
  case valueTooLarge(maximumBytes: Int)
  case authenticationFailed
  case cancelled
  case interactionRequired
  case permissionDenied
  case missingEntitlement
  case unavailable
  case invalidData
  case unexpectedStatus(OSStatus)

  public var errorDescription: String? {
    switch self {
    case .invalidService:
      "Secure Store service 식별자가 비어 있거나 올바르지 않습니다."
    case .invalidAccessGroup:
      "Keychain access group 식별자가 비어 있거나 올바르지 않습니다."
    case .invalidMaximumValueSize:
      "최대 저장 크기는 1바이트 이상이어야 합니다."
    case .incompatibleSynchronizationAccessibility:
      "iCloud 동기화 항목에는 ThisDeviceOnly 접근성을 사용할 수 없습니다."
    case .invalidKey:
      "Secure Store key가 비어 있거나 너무 길거나 null 문자를 포함합니다."
    case .valueTooLarge(let maximumBytes):
      "저장하려는 값이 허용된 최대 크기인 \(maximumBytes)바이트를 초과합니다."
    case .authenticationFailed:
      "Keychain 인증에 실패했습니다."
    case .cancelled:
      "Keychain 작업이 취소되었습니다."
    case .interactionRequired:
      "Keychain 작업을 완료하려면 사용자 상호작용이 필요합니다."
    case .permissionDenied:
      "Keychain 항목에 접근할 권한이 없습니다."
    case .missingEntitlement:
      "호스트 앱에 필요한 Keychain entitlement가 없습니다."
    case .unavailable:
      "현재 Keychain을 사용할 수 없습니다."
    case .invalidData:
      "Keychain이 예상하지 못한 데이터 형식을 반환했습니다."
    case .unexpectedStatus(let status):
      "Keychain 작업에 실패했습니다. OSStatus: \(status)"
    }
  }

  static func from(status: OSStatus) -> SecureStoreError {
    switch status {
    case errSecAuthFailed:
      .authenticationFailed
    case errSecUserCanceled:
      .cancelled
    case errSecInteractionNotAllowed, errSecInteractionRequired:
      .interactionRequired
    case errSecMissingEntitlement:
      .missingEntitlement
    case errSecNoAccessForItem, errSecWrPerm, errSecReadOnly:
      .permissionDenied
    case errSecNotAvailable, errSecNoDefaultKeychain, errSecNoSuchKeychain:
      .unavailable
    case errSecDecode:
      .invalidData
    default:
      .unexpectedStatus(status)
    }
  }
}
