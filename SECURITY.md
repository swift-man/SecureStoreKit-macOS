# Security Policy

## 기본 원칙

- 모든 운영 쿼리는 Data Protection Keychain을 사용합니다.
- iCloud 동기화는 명시적으로 활성화하지 않는 한 사용하지 않습니다.
- Secret 값은 로그, 오류 메시지, 디버그 설명에 포함하지 않습니다.
- 삭제는 멱등적으로 처리하며 존재하지 않는 항목은 성공으로 간주합니다.
- 잘못된 service, access group, key, 크기 제한은 Security.framework 호출 전에 거부합니다.
- entitlement와 access group의 최종 권한은 호스트 앱의 코드서명이 결정합니다.

## 제한 사항

Swift의 `Data`는 복사와 최적화가 가능하므로 패키지가 모든 메모리 복사본을 확실히 zeroize한다고 보장하지 않습니다. 호출자는 Secret 수명을 짧게 유지하고 불필요한 문자열 변환과 장기 캐시를 피해야 합니다.

보안 취약점에는 실제 Secret, 인증서, 사용자 식별 정보를 포함하지 말고 재현 가능한 최소 정보만 공유하세요.
