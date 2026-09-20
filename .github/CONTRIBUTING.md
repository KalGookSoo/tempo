# tempo 프로젝트 기여 가이드

이 문서는 tempo 프로젝트에 기여하는 방법에 대한 가이드라인을 제공합니다.

## 목차

- [개발 환경 설정](#개발-환경-설정)
- [코딩 표준](#코딩-표준)
- [커밋 메시지 가이드라인](#커밋-메시지-가이드라인)
- [이슈 제출](#이슈-제출)
- [풀 리퀘스트 제출](#풀-리퀘스트-제출)
- [릴리스 프로세스](#릴리스-프로세스)
- [응답 언어](#응답-언어)

## 개발 환경 설정

`tempo/tempo.xcodeproj`를 Xcode로 열고 `tempo` 스킴으로 빌드/실행합니다. 별도 패키지 매니저나 빌드 도구 설치는 필요 없습니다 — SwiftUI + SwiftData 표준 스택만 사용합니다. 자세한 내용은 [README.md](../README.md)를 참고하세요.

## 코딩 표준

- Swift 코드는 [`docs/swift-coding-conventions.md`](../docs/swift-coding-conventions.md)를 따릅니다 — Apple 공식 Swift API Design Guidelines을 기준으로 합니다.
- 포맷팅은 `.swiftformat`(`--swiftversion 5.0 --indent 4`) 설정을 그대로 따릅니다.
- 화면 디자인은 [`docs/native-style-guide.md`](../docs/native-style-guide.md)를 따릅니다 — 커스텀 디자인 시스템을 만들지 않고 iOS 기본 앱과 같은 절제된 네이티브 스타일을 유지합니다.

## 커밋 메시지 가이드라인

[Conventional Commits](https://www.conventionalcommits.org/) 형식을 느슨하게 따릅니다.

### 커밋 메시지 구조

```
<타입>: <설명>

[선택적 본문]
```

### 주요 커밋 타입

- **feat**: 새로운 기능 추가
- **fix**: 버그 수정
- **docs**: 문서 변경
- **refactor**: 코드 리팩토링
- **chore**: 빌드 설정, 스캐폴딩, 그 외 보조 작업

설명은 한글로, 무엇을 왜 바꿨는지 알 수 있게 씁니다.

## 이슈 제출

버그를 보고하거나 새로운 기능을 제안하려면 GitHub 이슈를 사용하세요. 이슈를 제출할 때는 다음 템플릿 중 하나를 선택하세요:

- **버그 리포트**: 버그를 보고할 때 사용합니다.
- **기능 요청**: 새로운 기능을 제안할 때 사용합니다.
- **일반 이슈**: 기타 모든 유형의 이슈에 사용합니다.

각 템플릿은 필요한 정보를 제공하는 데 도움이 되는 구조를 제공합니다.

## 풀 리퀘스트 제출

코드 변경을 제출하려면 풀 리퀘스트(PR)를 사용하세요. PR을 제출할 때는 다음 가이드라인을 따르세요:

1. 커밋 메시지는 [Conventional Commits](#커밋-메시지-가이드라인) 가이드라인을 따르세요.
2. PR 설명은 [PR 템플릿](PULL_REQUEST_TEMPLATE.md)을 따르세요.
3. 코드가 빌드되고 기존 테스트를 통과하는지 확인하세요. CI(`.github/workflows/ci.yml`)는 빌드와 포맷만 자동으로 확인합니다 — GitHub 호스팅 러너의 시뮬레이터 런타임 구성 문제로 유닛/UI 테스트는 CI에 자동화돼 있지 않으므로, PR을 올리기 전에 로컬에서 직접 실행해 통과를 확인하세요:

   ```
   xcodebuild test -project tempo/tempo.xcodeproj -scheme tempo \
     -destination 'platform=iOS Simulator,name=iPhone 17'
   ```

   (기기 이름은 로컬에 설치된 시뮬레이터 중 하나로 바꿔서 실행하세요.)

4. 새 UI 문자열(`Text("...")`, `String(localized:)` 등)을 추가했다면, Xcode(IDE)로 최소 한 번 빌드해 `Shared/Localizable.xcstrings`에 그 키가 실제로 병합됐는지 확인한 뒤 커밋하세요. `xcodebuild` 커맨드라인 빌드(CI 포함)는 대상 타겟과 무관하게 String Catalog에 새 키를 자동으로 병합하지 않습니다 — 이는 Xcode IDE 빌드 시스템에서만 일어나는 동작입니다(이슈 #105에서 메인 앱/애플워치 두 타겟 모두로 직접 확인). CI는 이 누락을 잡아주지 않으므로, 병합을 놓치면 그 문자열은 영영 번역 없이 남을 수 있습니다.

## 릴리스 프로세스

tempo는 [시맨틱 버전 관리](http://semver.org)(`MAJOR.MINOR.PATCH`)를 따릅니다. 릴리스 노트는 [릴리스 템플릿](RELEASE_TEMPLATE.md)을 따라 작성됩니다.

### 버전 번호와 Xcode 빌드 설정의 매핑

- **`MARKETING_VERSION`**(`project.pbxproj`) = 시맨틱 버전(`X.Y.Z`). 사람이 보는 릴리스 버전이자 App Store에 노출되는 버전이다.
- **`CURRENT_PROJECT_VERSION`**(`project.pbxproj`) = 빌드 번호. App Store Connect에 업로드할 때마다 반드시 이전 값보다 커야 하므로, 같은 `MARKETING_VERSION` 안에서도 업로드할 때마다 1씩 올린다.
- 메인 앱(`tempo`), 위젯 익스텐션(`TempoWidget`), 애플워치 앱(`TempoWatch Watch App`) 세 타겟은 항상 같은 `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION`을 갖는다 — 앱 안에 함께 담겨 배포되는 익스텐션은 버전이 메인 앱과 다르면 App Store Connect가 업로드를 거부한다. 버전을 올릴 때 세 타겟 모두 함께 바꾼다.

### 버전을 올리는 기준

[커밋 타입](#주요-커밋-타입)을 그대로 기준으로 삼는다.

- **PATCH**(`X.Y.Z+1`): `fix` 커밋만 있는 릴리스.
- **MINOR**(`X.Y+1.0`): `feat` 커밋이 하나라도 포함된 릴리스.
- **MAJOR**(`X+1.0.0`): 기존 사용자 데이터나 동작 방식을 깨뜨리는 변경이 있는 릴리스(예: 마이그레이션 없이 저장 데이터 구조가 바뀌는 경우). 지금까지는 해당된 적이 없다.
- `docs`/`refactor`/`chore`만 있는 변경은 그 자체로 버전을 올리지 않고, 다음 `fix`/`feat` 릴리스에 함께 포함시킨다.

### git 태그 규칙

릴리스 시점에 `MARKETING_VERSION`과 정확히 일치하는 태그를 `v` 접두사로 로컬에 남긴다(기록용).

```
git tag v1.0.0
```

과거에는 이 태그를 push하면 GitHub Actions(`release.yml`)가 자동으로 아카이브·업로드했지만, 그 CD 파이프라인은 제거했다 — 지금은 Xcode Organizer로 직접 아카이브해서 App Store Connect에 업로드한다(아래 "릴리스 절차" 참고). 태그를 GitHub에도 남기고 싶으면 `git push origin v1.0.0`을 별도로 실행한다.

### 릴리스 절차

1. `project.pbxproj`에서 `tempo`, `TempoWidget`, `TempoWatch Watch App` 세 타겟 모두 `MARKETING_VERSION`을 올린다(빌드 업로드 때마다 `CURRENT_PROJECT_VERSION`도 세 타겟 다 함께 1씩 올린다).
2. `chore: 버전을 X.Y.Z로 올림` 커밋을 만든다.
3. 위 규칙대로 태그를 로컬에 만든다.
4. Xcode에서 스킴 `tempo`, 대상 `Any iOS Device`로 `Product → Archive` 한 뒤, Organizer의 Distribute App → App Store Connect → Upload로 업로드한다.
5. [릴리스 템플릿](RELEASE_TEMPLATE.md)에 따라 GitHub 릴리스 노트를 작성한다.
6. GitHub 릴리스 노트 중 사용자가 체감할 수 있는 부분만 추려서 [App Store 릴리스 노트 템플릿](../docs/app-store-release-notes-template.md) 형식으로 다시 써서, App Store Connect의 "새로운 기능" 필드에 채운다.

## 응답 언어

- 앱 안의 모든 사용자 인터페이스 텍스트와 메시지는 한글로 제공되어야 합니다.
- 오류 메시지, 알림, 사용자 안내 등 모든 텍스트는 한글로 작성되어야 합니다.

## 질문이 있으신가요?

질문이나 도움이 필요하시면 GitHub 이슈를 통해 문의하세요.
