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

### 민감한 메모리 수명 줄이기

기존 `Data` API는 그대로 사용할 수 있습니다. 앱이 Keychain에서 읽은 뒤 유지하는 평문
버퍼의 수명을 더 엄격하게 관리하려면 `SecureBytes` API를 사용합니다.

```swift
let secret = SecureBytes(copying: Data("token".utf8))
try await store.save(secret, for: "github.token")

if let restored = try await store.readSecureBytes(for: "github.token") {
  restored.withUnsafeBytes { bytes in
    // 포인터를 이 클로저 밖으로 내보내지 않고 필요한 작업을 수행합니다.
  }
}
```

`SecureBytes`는 전용 메모리를 소유하고 마지막 참조가 해제되기 직전에 `memset_s`로
해당 버퍼를 덮어씁니다. `description`과 `debugDescription`에는 내용이 표시되지 않습니다.
기존 `Data` 전용 `SecureStore` 구현체도 기본 호환 어댑터를 통해 새 API를 사용할 수 있습니다.

이 보장은 `SecureBytes`가 소유한 버퍼에만 적용됩니다. 생성에 사용한 원본 `String`이나
`Data`, Security.framework 및 호출자가 별도로 만든 복사본의 메모리까지 지우지는 못합니다.
원본 값의 수명도 호출자가 가능한 짧게 관리해야 합니다.

같은 access group을 사용하는 여러 프로세스가 동시에 같은 key를 저장하거나 삭제해도
일시적인 추가·갱신 경합은 최대 3회까지 다시 시도합니다. 권한, 인증, entitlement 오류는
재시도하지 않고 즉시 호출자에게 전달합니다.

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
- [변경 이력](CHANGELOG.md)
- [현재 버전](VERSION.txt)
