# Changelog

## 0.1.0.0 - 2026-07-15

### Added

- macOS 14 이상에서 Data Protection Keychain을 사용하는 actor 기반 Secure Store를 추가했습니다.
- 접근 그룹, 접근성, iCloud 동기화 정책을 명시적으로 구성하고 잘못된 조합을 거부하는 설정 경계를 추가했습니다.
- 앱 코드와 테스트 대역이 같은 계약을 사용하도록 `SecureStore` 프로토콜과 `SecureStoreTesting` 제품을 추가했습니다.
- Keychain 쿼리, 오류 변환, CRUD 동작과 보안 기본값을 검증하는 단위 테스트를 추가했습니다.
- Keychain Sharing entitlement, 레거시 항목 마이그레이션, 보안 정책을 설명하는 문서를 추가했습니다.

## 0.0.0.0 - 2026-07-15

### Added

- SecureStoreKit-macOS 저장소의 버전 및 변경 이력 관리 기준을 추가했습니다.
