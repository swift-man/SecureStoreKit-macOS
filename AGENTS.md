# AGENTS.md

이 저장소는 macOS 14 이상을 지원하는 Swift Package다.

## 설계 원칙

- 공개 도메인 계약은 Security.framework 구현과 분리한다.
- 운영 구현은 항상 `kSecUseDataProtectionKeychain = true`를 사용한다.
- Secret 값은 로그, 오류, 디버그 출력에 포함하지 않는다.
- iCloud 동기화는 호출자가 명시적으로 요청한 경우에만 허용한다.
- 호스트 앱 entitlement를 패키지가 우회하거나 추측하지 않는다.
- 레거시 마이그레이션 정책과 앱별 계정 이름은 사용하는 앱이 소유한다.
- 새 기능은 정상, 경계값, 실패 흐름 테스트와 함께 추가한다.
- 코드는 2칸 들여쓰기를 사용한다.

## 검증

```bash
swift test
swift build
```

실제 Keychain 통합 테스트는 Keychain Sharing entitlement가 포함된 서명된 macOS 호스트 앱에서 수행한다.
