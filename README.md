# 국내 주식 관심종목 앱

이든크루 Lucy Studio Front 신입 개발자 과제 1의 Flutter 구현입니다.

국내 주식을 검색하고 관심 종목으로 저장할 수 있으며, 관심 목록의 실시간 시세와 종목 상세 정보, 기간별 캔들 차트와 일별 시세를 확인할 수 있습니다.

## 주요 기능

- 관심 종목 빈 상태와 실시간 시세 목록
- 현재가순, 등락률순, 가나다순 정렬
- 관심 종목 시세 일괄 조회와 새로고침
- 종목명 또는 6자리 종목 코드 검색
- 검색 입력 디바운스와 이전 요청 결과 무시
- 검색 결과의 관심 등록·해제와 토스트 안내
- 관심 종목을 기기 로컬 저장소에 보관
- 현재가, 등락률, 시가, 고가, 저가, 거래량, 시가총액 표시
- 1개월, 3개월, 6개월, 1년 캔들 차트
- 날짜, 종가, 등락, 거래량으로 구성된 일별 시세
- 기간별 일봉 메모리 캐시
- 로딩, 빈 결과, 전체 실패, 부분 실패와 재시도 상태

## 실행 환경

개발 및 확인에 사용한 환경은 다음과 같습니다.

| 구분 | 환경 |
| --- | --- |
| OS | Windows 11 25H2 |
| Flutter | 3.47.4 stable |
| Dart | 3.13.3 |
| Android Emulator | Android 17, API 37, x86_64 |
| 대상 기기 | `sdk gphone16k x86 64` |

Naver API가 브라우저의 CORS 요청을 허용하지 않으므로 Chrome이 아닌 Android 에뮬레이터 또는 모바일 기기에서 실행해야 합니다.

## 실행 방법

### 1. 의존성 설치

```powershell
flutter pub get
```

### 2. 연결된 기기 확인

```powershell
flutter devices
```

### 3. Android 에뮬레이터에서 실행

```powershell
flutter run -d emulator-5554
```

에뮬레이터 식별자가 다른 경우 `flutter devices`에 표시된 값을 사용합니다.

### 4. 정적 분석과 테스트

```powershell
flutter analyze
flutter test
```

실제 앱과 실제 Naver API를 사용하는 라이브 E2E 테스트는 다음 명령으로 실행합니다.

```powershell
flutter test integration_test/app_flow_test.dart -d emulator-5554
```

라이브 E2E는 검색, 관심 등록, 정렬, 상세 진입, 기간 변경, 차트 조회, 관심 상태 저장을 에뮬레이터에서 자동으로 수행합니다. 실제 네트워크를 사용하므로 Naver 서버 상태나 호출 제한의 영향을 받을 수 있으며 최대 실행 시간은 5분입니다. 테스트가 추가한 삼성전자 관심 상태는 마지막 단계에서 제거합니다.

## 화면 흐름

```text
관심 화면
  ├── 정렬 및 새로고침
  └── 종목 선택 ───────────────┐
                               ▼
검색 화면 ── 검색 결과 선택 ──> 종목 상세 화면
  │                            ├── 관심 등록·해제
  └── 관심 등록·해제           ├── 기간 선택
                               ├── 캔들 차트
                               └── 일별 시세
```

검색, 관심 목록, 상세 화면은 하나의 `FavoriteController`를 공유합니다. 한 화면에서 관심 상태를 변경하면 다른 화면에도 바로 반영됩니다.

## 폴더 구조

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── app_controller.dart
├── data/
│   ├── dtos/
│   ├── models/
│   ├── favorite_storage.dart
│   └── naver_stock_service.dart
├── features/
│   ├── favorites/
│   │   └── favorite_controller.dart
│   ├── search/
│   │   ├── search_controller.dart
│   │   └── search_screen.dart
│   ├── watchlist/
│   │   ├── watchlist_controller.dart
│   │   └── watchlist_screen.dart
│   └── stock_detail/
│       ├── price_chart_section.dart
│       ├── stock_detail_controller.dart
│       └── stock_detail_screen.dart
├── shared/
│   ├── formatters/
│   └── widgets/
└── theme/
```

기능별로 화면과 상태 관리 코드를 가까이 배치했습니다. `data`는 외부 API와 로컬 저장소를 담당하고, `features`의 화면은 URL이나 Naver 응답 필드명을 직접 알지 않도록 분리했습니다.

상세한 데이터 계약과 선택 이유는 [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)에 정리했습니다.

## 상태 관리

과제 규모에 맞게 Flutter SDK의 `ChangeNotifier`와 `AnimatedBuilder`를 사용했습니다.

- `AppController`: 하단 탭 선택 상태
- `FavoriteController`: 모든 화면이 공유하는 관심 종목 코드와 저장 상태
- `StockSearchController`: 검색어, 디바운스, 결과와 오류 상태
- `WatchlistController`: 관심 종목 메타데이터, 시세, 정렬과 부분 실패 상태
- `StockDetailController`: 상세 시세, 선택 기간, 일봉 데이터와 기간별 캐시

별도의 상태 관리 패키지를 추가하지 않아 데이터 흐름을 Flutter 기본 구조만으로 따라갈 수 있게 구성했습니다.

## 데이터 저장

별도 데이터베이스는 사용하지 않습니다.

관심 종목의 6자리 코드만 `shared_preferences`의 `SharedPreferencesAsync`로 저장합니다. 종목명과 가격은 오래된 값이 남지 않도록 저장하지 않고 앱 실행 시 Naver API에서 다시 조회합니다.

```text
["005930", "000660", "035720"]
```

일봉 데이터는 `종목 코드 + 기간`을 키로 메모리에 저장합니다. 같은 화면에서 이전에 선택한 기간으로 돌아가면 추가 요청 없이 캐시를 사용하며 앱 종료 시 캐시는 제거됩니다.

## Naver 데이터 연동

응답은 화면에서 바로 사용하지 않고 DTO를 통해 앱 모델로 변환합니다.

| 데이터 | 용도 |
| --- | --- |
| 검색 자동완성 | 국내 주식 검색 |
| 종목 메타데이터 | 종목명과 시장명 |
| 실시간 시세 | 현재가, 등락, 시가, 고가, 저가, 거래량 |
| 일별 시세 | 캔들 차트와 일별 시세 표 |

실시간 시세 응답은 EUC-KR 문자셋을 사용하므로 UTF-8 강제 디코딩 대신 JSON 구조가 보존되는 방식으로 읽습니다. 화면에 표시할 종목명은 UTF-8 검색·메타데이터 API의 값을 사용합니다.

과제 문서에 안내된 기존 일별 시세 HTML endpoint는 현재 데이터 행을 제공하지 않거나 403을 반환할 수 있습니다. HTML 파싱 흐름은 유지하되 사용할 수 없는 응답이면 Naver 모바일 일별 시세 JSON endpoint로 전환합니다. 대체 요청도 페이지당 10거래일 단위로 처리해 기간별 페이지 수와 캐시 정책을 유지합니다.

## 오류 및 경계 상태 처리

- 모든 네트워크 요청에 12초 제한 시간 적용
- 검색 중 새 입력이 들어오면 오래된 요청 결과 무시
- 동일한 상세 또는 기간 요청의 중복 호출 방지
- 일부 관심 종목의 시세가 실패해도 정상 데이터 유지
- 시세 새로고침 실패 시 마지막 정상 가격 유지
- 일봉 후속 페이지가 실패하면 앞에서 받은 데이터 유지
- 빈 일봉 페이지 이후 추가 요청 중단
- 사용자 화면에는 정리된 오류 문구를 표시하고 디버그 로그에는 실제 예외와 스택 출력
- 긴 종목명은 한 줄 말줄임 처리
- 작은 화면에서는 현재가와 등락 영역을 자동 축소

## 테스트 전략

단위 테스트와 실제 API 기반 E2E 테스트의 역할을 분리했습니다.

- 단위 테스트: DTO 변환, 계산, 검색 요청 순서, 정렬, 관심 저장, 일봉 캐시와 실패 복구처럼 외부 상태와 분리해야 하는 로직 검증
- 라이브 E2E 테스트: 실제 앱, Naver API, Android 에뮬레이터와 `SharedPreferences`를 사용한 전체 사용자 흐름 검증

E2E에서는 계속 변경되는 주가 숫자를 고정값으로 비교하지 않고, 실제 응답 이후 검색 결과와 가격·차트·일별 시세 영역이 표시되는지를 확인합니다.

## 사용한 패키지

| 패키지 | 사용 이유 |
| --- | --- |
| `http` | Naver HTTP 요청과 테스트 가능한 클라이언트 주입 |
| `html` | 기존 Naver 일별 시세 HTML의 DOM 파싱 |
| `shared_preferences` | 관심 종목 코드의 가벼운 로컬 저장 |
| `integration_test` | 실제 Android 앱의 사용자 흐름 자동화 |

UI와 캔들 차트는 별도의 UI·차트 패키지 없이 Flutter 위젯과 `CustomPainter`로 구현했습니다.

## Figma 시안과 다른 부분

- Figma의 iOS 상태 표시줄과 홈 인디케이터는 앱 내부에서 그리지 않고 실행 기기의 시스템 UI를 사용합니다.
- 아이콘은 시안과 의미가 대응되는 Material Icons를 사용했습니다.
- 캔들 차트 필수 범위인 상승·하락·보합 캔들을 구현했으며 선택 요구사항인 축 라벨, 거래량 바, 영역 채우기, 크로스헤어와 툴팁은 제외했습니다.
- 토스트 노출 시간은 시안에 정의가 없어 2초로 설정했습니다.
- 일별 시세 HTML endpoint 중단에 대응하기 위해 JSON 대체 경로를 추가했습니다.

## 구현 완료 범위

과제 1의 필수 범위를 구현했습니다.

- 관심종목 화면과 상태별 UI
- 검색 화면과 상태별 UI
- 종목 상세 화면
- 관심 상태 동기화와 로컬 저장
- 실제 Naver 검색·메타데이터·실시간 시세 연동
- 전체 기간 탭과 일별 시세 페이지 조회
- 캔들 차트와 일별 시세 표
- 로딩, 오류, 부분 실패와 재시도 처리
- 단위 테스트와 실제 API 기반 E2E 테스트

## 미구현 및 선택 제외 항목

필수 요구사항 기준으로 남은 항목은 없습니다. 다음 선택 기능은 일정과 과제 범위를 고려해 제외했습니다.

- 최근 검색어
- 토스트 등장·퇴장 애니메이션
- 차트 축 라벨과 거래량 바
- 차트 영역 채우기
- 차트 크로스헤어와 툴팁
- 차트 전환 애니메이션
- 일별 시세 무한 스크롤

## 구현 중 어려웠던 점

### 문자 인코딩

실시간 시세 API가 HTTP 200을 반환해도 EUC-KR 응답을 UTF-8로 강제 해석하면 JSON 파싱 전에 실패했습니다. Flutter DevTools Network에서 상태 코드가 정상임을 확인한 뒤 응답 헤더와 원본 바이트를 비교해 디코딩 문제로 범위를 좁혔습니다.

### 일별 시세 endpoint 변경

과제 문서의 HTML endpoint가 현재는 빈 안내 페이지 또는 403을 반환합니다. HTML 파서와 계약을 유지하면서 실제 앱도 동작하도록 현재 제공되는 JSON 응답으로 전환하는 대체 경로를 구성했습니다.

### 테스트와 실제 환경의 차이

초기 E2E는 고정 응답을 사용해 화면 흐름은 안정적으로 검증했지만 실제 서버의 인코딩과 endpoint 변경을 발견하지 못했습니다. 최종 E2E는 가짜 API를 제거하고 실제 앱과 실제 Naver API를 사용하도록 변경했습니다. 고정 데이터가 필요한 로직 검증만 단위 테스트에 남겼습니다.

## 관련 문서

| 문서 | 내용 |
| --- | --- |
| [`docs/ASSIGNMENT.md`](docs/ASSIGNMENT.md) | 화면별 요구사항과 평가 기준 |
| [`docs/NAVER_API.md`](docs/NAVER_API.md) | 제공된 Naver 데이터 연동 가이드 |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | 폴더 구조, 데이터 계약과 캐시 기준 |
| [`docs/IMPLEMENTATION_PLAN.md`](docs/IMPLEMENTATION_PLAN.md) | 브랜치별 구현 순서 |
| [`lib/theme/README.md`](lib/theme/README.md) | Figma 디자인 토큰과 Dart 필드 대응표 |

## 라이선스 및 공개 범위

이 저장소에는 별도로 전달받은 Figma 시안, 캡처 이미지, Lucy Studio 설치 파일과 과제 2 결과물을 포함하지 않습니다.

저장소의 사용 범위는 루트의 [`LICENSE`](LICENSE)를 따릅니다.
