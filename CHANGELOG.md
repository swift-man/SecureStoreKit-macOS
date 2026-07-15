# Changelog

## 0.1.2.0 - 2026-07-15

### Added

- Keychain에서 읽은 Secret의 애플리케이션 메모리 수명을 줄일 수 있도록 해제 직전 소유 버퍼를 덮어쓰는 `SecureBytes`를 추가했습니다.
- 기존 `Data` 기반 구현을 깨지 않고 사용할 수 있는 `save(_:for:)` 및 `readSecureBytes(for:)` 호환 API를 추가했습니다.

### Changed

- Data Protection Keychain 저장 경로가 `SecureBytes`의 불변 비복사 `NSData` 뷰를 사용해 애플리케이션 내부의 불필요한 평문 복사를 줄입니다.
- `InMemorySecureStore`도 값을 독립된 `SecureBytes` 스냅샷으로 보관해 운영 구현과 같은 소유권 계약을 따릅니다.

## 0.1.1.0 - 2026-07-15

### Fixed

- 여러 프로세스가 같은 Keychain 항목을 동시에 저장하거나 삭제할 때 일시적인 add/update 경합을 최대 3회까지 복구하도록 개선했습니다.
- 반복되는 경합은 제한된 횟수 후 오류로 반환하고 인증, 권한, entitlement 실패는 재시도하지 않도록 보장했습니다.

## 0.1.0.0 - 2026-07-15

### Added

- macOS 14 이상에서 Data Protection Keychain을 사용하는 actor 기반 Secure Store를 추가했습니다.
- 접근 그룹, 접근성, iCloud 동기화 정책을 명시적으로 구성하고 잘못된 조합을 거부하는 설정 경계를 추가했습니다.
- 앱 코드와 테스트 대역이 같은 계약을 사용하도록 `SecureStore` 프로토콜과 `SecureStoreTesting` 제품을 추가했습니다.
- Keychain 쿼리, 오류 변환, CRUD 동작과 보안 기본값을 검증하는 단위 테스트를 추가했습니다.
- Keychain Sharing entitlement, 레거시 항목 마이그레이션, 보안 정책을 설명하는 문서를 추가했습니다.
- Security.framework의 동기 호출을 전용 직렬 큐에서 실행해 Swift cooperative executor 차단을 방지했습니다.
- Keychain에 지나치게 큰 값을 저장하지 않도록 기본 저장 한도를 64 KiB로 조정했습니다.

## 0.0.0.0 - 2026-07-15

### Added

- SecureStoreKit-macOS 저장소의 버전 및 변경 이력 관리 기준을 추가했습니다.
