# Tempo 로컬 영속화 전략

## 목적

tempo MVP는 네트워크 없이도 사용자의 인터벌 프리셋, 알림 큐 설정, 사운드 설정을 유지해야 한다.
이 문서는 로컬 우선 저장 전략을 정의한다.

## 결론

MVP의 기본 저장소는 `SQLite`로 둔다.
사용자가 추가한 음원 파일과 직접 녹음 파일은 파일 시스템에 저장하고, SQLite에는 파일 식별자와 경로만 저장한다.

권장 패키지:

- `expo-sqlite`: 프리셋, 설정, 사운드 메타데이터 저장
- `expo-file-system`: 사용자 음원 파일과 녹음 파일 저장

현재 앱은 Expo 기반이므로 네이티브 SQLite를 직접 붙이는 대신 Expo 생태계 패키지를 우선 사용한다.

## 저장 대상

| 대상 | 저장소 | 이유 |
| --- | --- | --- |
| 기본 인터벌 프리셋 | 앱 코드 + SQLite seed | 기본값은 코드로 관리하고, 앱 최초 실행 시 DB에 반영한다. |
| 사용자 인터벌 프리셋 | SQLite | 이름, 라운드, 세트, 큐 옵션을 구조화해서 조회해야 한다. |
| 알림 큐 설정 | SQLite | 전역 기본값과 프리셋별 오버라이드를 함께 다뤄야 한다. |
| 사운드 큐 메타데이터 | SQLite | 기본 사운드, 사용자 파일, 녹음 파일을 같은 방식으로 선택해야 한다. |
| 사용자 음원 파일 | File System | 바이너리 파일은 DB에 넣지 않는다. |
| 직접 녹음 파일 | File System | 파일로 저장하고 DB에는 참조만 남긴다. |
| 표시 설정 | SQLite key-value | 다크모드, 큰 숫자 표시 등 앱 설정은 단순 key-value로 충분하다. |

## 저장하지 않을 대상

- 실행 중인 타이머의 매 tick 값
- 타이머의 카운트다운 / 카운트업 설정값
- 최근 실행 기록
- 히스토리 화면용 데이터
- 일시적인 UI 상태
- 화면 미러링 연결 상태

실행 중 앱이 종료된 뒤 복구가 필요해지면 `active_timer_session` 같은 별도 테이블을 추가한다.
MVP에서는 먼저 프리셋과 사용자 설정 영속화에 집중한다.

## MVP 제외 대상

### 최근 실행 기록과 히스토리

최근 실행 기록과 히스토리는 1차 MVP에서 제외한다.

- 사용자가 반복해서 쓰는 값은 실행 기록보다 프리셋으로 저장하는 편이 더 명확하다.
- 히스토리는 목록, 상세, 삭제, 보존 기간 같은 부가 정책을 함께 요구한다.
- 현재 목표는 운동 타이머를 빠르게 설정하고 실행하는 것이다.
- 기록을 저장하면 데이터 모델과 화면 범위가 커지지만, 핵심 사용성에 바로 필요하지 않다.

나중에 운동 로그, 통계, 최근 사용한 설정 다시 실행 기능이 필요해지면 별도 단계에서 추가한다.

## 왜 AsyncStorage만 쓰지 않는가

AsyncStorage는 간단한 설정 저장에는 좋지만, tempo의 핵심 데이터에는 약하다.

- 프리셋 목록, 기본 프리셋, 사용자 프리셋을 필터링하기 어렵다.
- 프리셋별 알림 큐와 사운드 큐가 서로 참조될 때 JSON 덩어리가 커진다.
- 마이그레이션 실수가 발생하면 전체 데이터를 망가뜨리기 쉽다.

따라서 SQLite를 기준으로 잡고, 단순 설정도 같은 저장 계층에서 관리한다.

## 데이터 모델

### `schema_migrations`

DB 스키마 버전을 관리한다.

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| `version` | integer | 적용된 마이그레이션 버전 |
| `applied_at` | text | ISO 8601 적용 시각 |

### `timer_presets`

기본 프리셋과 사용자 프리셋을 저장한다.

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| `id` | text | UUID 또는 고정 seed id |
| `kind` | text | `default` 또는 `custom` |
| `mode` | text | `interval` |
| `name` | text | 사용자에게 보이는 이름 |
| `description` | text nullable | 보조 설명 |
| `config_json` | text | 타이머 설정 JSON |
| `cue_profile_id` | text nullable | 사용할 알림 큐 프로필 |
| `sort_order` | integer | 목록 표시 순서 |
| `created_at` | text | 생성 시각 |
| `updated_at` | text | 수정 시각 |
| `deleted_at` | text nullable | soft delete 시각 |

MVP에서 프리셋은 인터벌 전용이다.
타이머의 카운트다운과 카운트업은 프리셋으로 저장하지 않는다.

예시 `config_json`:

```json
{
  "rounds": 8,
  "prepareSeconds": 10,
  "segments": [
    { "type": "work", "seconds": 20 },
    { "type": "rest", "seconds": 10 }
  ]
}
```

### `cue_profiles`

알림 큐 프로필을 저장한다.

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| `id` | text | UUID |
| `name` | text | 프로필 이름 |
| `is_default` | integer | 기본 프로필 여부 |
| `config_json` | text | 큐 규칙 JSON |
| `created_at` | text | 생성 시각 |
| `updated_at` | text | 수정 시각 |

예시 `config_json`:

```json
{
  "countdownCueSeconds": [3, 2, 1],
  "useVibrationWhenMuted": true,
  "events": {
    "prepareStart": { "soundId": "default_prepare", "vibration": true },
    "workStart": { "soundId": "default_work", "vibration": true },
    "restStart": { "soundId": "default_rest", "vibration": true },
    "finish": { "soundId": "default_finish", "vibration": true }
  }
}
```

### `sound_assets`

기본 사운드, 사용자 음원, 직접 녹음 음성 큐를 관리한다.

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| `id` | text | UUID 또는 기본 사운드 id |
| `kind` | text | `builtin`, `imported`, `recorded` |
| `name` | text | 사용자에게 보이는 이름 |
| `uri` | text nullable | 파일 시스템 경로 또는 앱 asset 경로 |
| `duration_ms` | integer nullable | 길이 |
| `created_at` | text | 생성 시각 |
| `deleted_at` | text nullable | soft delete 시각 |

사용자 파일을 삭제할 때는 DB row를 soft delete하고, 실제 파일 삭제 실패 가능성을 별도 처리한다.

### `app_settings`

작은 앱 설정을 key-value로 저장한다.

| 컬럼 | 타입 | 설명 |
| --- | --- | --- |
| `key` | text | 설정 키 |
| `value_json` | text | JSON 값 |
| `updated_at` | text | 수정 시각 |

예시 키:

- `theme_mode`: `system`, `light`, `dark`
- `display.big_timer_digits`: `true`

## 기본 프리셋 seed 전략

기본 프리셋은 앱 코드에 선언한다.

- `tabata`
- `fgb_5r`
- `fgb_3r`
- `emom`

앱 시작 시 DB가 비어 있으면 기본 프리셋을 삽입한다.
이미 존재하는 기본 프리셋은 사용자가 삭제할 수 없고, 앱 업데이트로 기본값이 바뀌면 `seed_version` 기준으로 필요한 항목만 갱신한다.

사용자가 기본 프리셋을 수정하고 싶으면 원본을 바꾸지 않고 `custom` 프리셋으로 복제한다.

## 파일 저장 전략

사용자 음원과 녹음 파일은 앱 전용 document directory 아래에 저장한다.

권장 디렉터리:

```text
tempo/
  sounds/
    imported/
    recorded/
```

파일명은 사용자 입력 이름을 직접 쓰지 않는다.
`sound_asset_id` 기반으로 생성한다.

예시:

```text
sounds/recorded/sound_7f3a9c.m4a
sounds/imported/sound_a91bd2.mp3
```

DB에는 파일 경로와 메타데이터만 저장한다.
파일이 사라진 경우 앱은 해당 사운드를 사용할 수 없음 상태로 표시하고, 기본 사운드로 대체한다.

## 마이그레이션 원칙

- 모든 스키마 변경은 숫자 버전 마이그레이션으로 관리한다.
- 앱 시작 시 현재 DB 버전을 확인하고 누락된 마이그레이션을 순서대로 적용한다.
- 마이그레이션은 재실행되어도 안전해야 한다.
- 사용자 데이터 삭제가 필요한 변경은 MVP에서는 피한다.

초기 버전:

1. `schema_migrations`
2. `timer_presets`
3. `cue_profiles`
4. `sound_assets`
5. `app_settings`

## 데이터 접근 계층

화면 컴포넌트에서 SQLite를 직접 호출하지 않는다.
저장소 접근은 repository 계층으로 숨긴다.

권장 구조:

```text
src/
  data/
    database.ts
    migrations.ts
    repositories/
      preset-repository.ts
      cue-profile-repository.ts
      sound-asset-repository.ts
      settings-repository.ts
```

화면은 repository를 통해 다음처럼 사용한다.

```ts
const presets = await presetRepository.findIntervalPresets();
await presetRepository.createCustomPreset(input);
```

이 구조를 두면 나중에 클라우드 동기화나 백업 기능을 추가할 때 화면 코드를 크게 바꾸지 않아도 된다.

## 백업과 동기화 대비

MVP는 로컬 전용이다.
다만 나중에 계정 기반 동기화를 붙일 수 있도록 다음 규칙을 지킨다.

- 모든 사용자 생성 데이터는 UUID를 가진다.
- `created_at`, `updated_at`, `deleted_at`을 둔다.
- 삭제는 가능한 soft delete로 처리한다.

이렇게 해두면 나중에 서버 동기화, 파일 백업, 기기 이전 기능을 붙이기 쉽다.

## 구현 순서

1. `expo-sqlite`와 `expo-file-system`을 추가한다.
2. DB 초기화와 마이그레이션 실행 코드를 만든다.
3. 기본 프리셋 seed를 넣는다.
4. 프리셋 repository를 만든다.
5. 인터벌 화면에서 사용자 프리셋 목록을 읽는다.
6. 새 프리셋 저장과 편집을 repository로 연결한다.
7. 사운드 큐 메타데이터와 파일 저장을 연결한다.

## MVP 성공 기준

- 앱을 종료했다가 다시 열어도 사용자 프리셋이 유지된다.
- 기본 프리셋은 항상 존재하고 삭제할 수 없다.
- 사용자 프리셋은 생성, 수정, 삭제, 실행할 수 있다.
- 사운드 큐 설정은 앱 재시작 후에도 유지된다.
- 사용자 녹음 파일은 앱 재시작 후에도 다시 선택할 수 있다.
