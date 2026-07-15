# SecureStoreKit

`SecureStoreKit`은 macOS 앱이 작은 Secret 데이터를 Data Protection Keychain에 저장하기 위한 Swift Package입니다.

## 지원 범위

- macOS 14 이상
- Swift 6 및 Swift Concurrency
- Generic Password 항목
- 로컬 Data Protection Keychain 기본 사용
- 앱별 service 및 access group
- 외부 런타임 의존성 없음
- Preview와 단위 테스트를 위한 `SecureStoreTesting`

인증서, SecKey 객체, 레거시 ACL 편집, 임의 Keychain 파일 관리는 지원하지 않습니다.

## KeychainAccess와의 차이

macOS에서 `SecItem`은 별도 설정이 없으면 레거시 file-based Keychain을 사용할 수 있습니다. 이 저장소는 모든 작업에 `kSecUseDataProtectionKeychain = true`를 명시하여 코드서명 entitlement와 access group 기반의 현대적인 접근 제어를 사용합니다.

`kSecAttrSynchronizable`은 기본적으로 `false`이므로 iCloud Keychain 동기화를 자동으로 활성화하지 않습니다.
동기화를 활성화한 구성에서는 Apple Keychain 계약에 따라 이름이 `ThisDeviceOnly`로 끝나는 접근성 정책을 사용할 수 없습니다.

## 호스트 앱 설정

Swift Package는 호스트 앱의 entitlement를 직접 추가할 수 없습니다. Xcode의 앱 target에서 **Keychain Sharing** capability를 활성화하고 사용할 access group을 등록해야 합니다.

```xml
<key>keychain-access-groups</key>
<array>
  <string>$(AppIdentifierPrefix)com.example.MyApp</string>
</array>
```

명시적인 access group을 사용한다면 `SecureStoreConfiguration`에 동일한 최종 값을 전달합니다.

## 사용법

```swift
import SecureStoreKit

let configuration = try SecureStoreConfiguration(
  service: "com.example.MyApp",
  accessGroup: "TEAMID.com.example.MyApp",
  accessibility: .whenUnlocked
)
let store = DataProtectionSecureStore(configuration: configuration)

try await store.save(Data("token".utf8), for: "github.token")
let token = try await store.read(for: "github.token")
try await store.delete(for: "github.token")
```

Secret 실제 값은 오류, 로그, `description`에 포함하지 않습니다.

기본 저장 한도는 64 KiB입니다. 더 큰 암호화 데이터는 파일로 저장하고, 해당 파일을
보호하는 작은 암호화 키만 Keychain에 저장하는 방식을 권장합니다. 필요한 경우
`maximumValueSize`를 명시적으로 조정할 수 있습니다.

## 기존 Keychain 마이그레이션

레거시 Keychain 읽기와 계정 매핑은 사용하는 앱의 책임입니다. 패키지는 KeychainAccess에 의존하지 않습니다.

권장 순서:

1. Data Protection Keychain에서 값을 조회합니다.
2. 값이 없을 때만 레거시 저장소를 읽습니다.
3. 새 저장소에 저장하고 다시 읽어 일치 여부를 검증합니다.
4. 검증이 끝난 뒤 레거시 항목을 삭제합니다.
5. 실패하면 원본을 유지하고 다음 실행에서 재시도합니다.

## 테스트

```bash
swift test
```

일반 `swift test` 프로세스에는 앱의 provisioning profile과 Keychain entitlement가 없을 수 있으므로 실제 Data Protection Keychain 통합 검증은 서명된 macOS 호스트 앱에서 별도로 실행해야 합니다. 패키지 단위 테스트는 Security.framework 경계를 대체하여 Secret을 실제 Keychain에 저장하지 않습니다.

## 관련 문서

- [보안 정책](SECURITY.md)
- [저장소 작업 규칙](AGENTS.md)
