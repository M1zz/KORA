# App Store Connect 공통 입력값 (KORA 1.0.5)

언어별 이름, 부제, 설명, 키워드, 새로운 기능은 같은 폴더의 언어별 파일에 있다.

| 파일 | App Store Connect 현지화 |
|---|---|
| [ko.md](ko.md) | 한국어 (Korean) |
| [en-US.md](en-US.md) | 영어 (미국) (English (U.S.)) |
| [ja.md](ja.md) | 일본어 (Japanese) |
| [zh-Hans.md](zh-Hans.md) | 중국어 간체 (Chinese (Simplified)) |
| [zh-Hant.md](zh-Hant.md) | 중국어 번체 (Chinese (Traditional)) |

이 문서는 언어와 상관없이 한 번만 입력하는 값들이다.

## 1. 앱 정보

| 항목 | 값 |
|---|---|
| 기본 카테고리 | 내비게이션 (Navigation) |
| 보조 카테고리 | 여행 (Travel) |
| 가격 | 무료 (인앱 결제 없음) |
| 저작권 | `2026 Leeo` |
| 번들 ID | `com.kora.leeo` |
| 기본 언어 | 한국어 권장 (기존 설정 유지) |

카테고리 이유: 핵심 기능이 실시간 경로 안내와 하차 알림이라 내비게이션이 맞고, 대상이 여행자라 보조는 여행으로 둔다.
내비게이션 카테고리는 경쟁이 비교적 적어 순위 노출에도 유리하다.

## 2. 연령 등급

모든 문항 **없음 / 아니요** → **4+** (한국 등급: 전체이용가).

| 문항 | 답 |
|---|---|
| 폭력, 성적 내용, 욕설, 공포, 약물·음주·흡연, 도박, 의료 정보 등 콘텐츠 문항 전부 | 없음 |
| 무제한 웹 접근 | 아니요 |
| 사용자 생성 콘텐츠, 메시지·채팅 | 아니요 |
| 광고 | 아니요 |
| 도박·경품, 루트 박스 | 아니요 |
| 보호자 통제·연령 확인 기능 | 아니요 |

## 3. 앱 개인정보 보호 (App Privacy, 개인정보 영양 성분표)

Apple 기준에서 “수집”은 데이터가 기기 밖으로 나가 개발자나 제3자(여기서는 Google)가 일정 시간 이상 접근할 수 있는 경우를 말한다.
기기 안에서만 처리하고 버리는 데이터는 수집이 아니다.

**“데이터를 수집합니까?” → 예**

| 데이터 유형 | 세부 유형 | 목적 | 사용자와 연결 | 추적에 사용 | 근거 |
|---|---|---|---|---|---|
| 식별자 (Identifiers) | 기기 ID (Device ID) | 분석 (Analytics) | 아니요 | 아니요 | Firebase 앱 인스턴스 ID |
| 사용 데이터 (Usage Data) | 제품 상호작용 (Product Interaction) | 분석 (Analytics) | 아니요 | 아니요 | first_open, session_start, 화면 조회 이벤트 |
| 위치 (Location) | 대략적 위치 (Coarse Location) | 분석 (Analytics) | 아니요 | 아니요 | Analytics가 IP 주소로 국가·지역을 추정 |

다른 목적(앱 기능, 광고, 개인화 등)은 선택하지 않는다.

**수집하지 않는 것으로 답하는 항목과 이유**

| 항목 | 답 | 이유 |
|---|---|---|
| 정확한 위치 (Precise Location) | 수집 안 함 | 가장 가까운 역 계산과 탑승 중 위치 추정에만 쓰고 기기 밖으로 보내지 않는다. |
| 오디오 데이터 | 수집 안 함 | 안내방송 인식은 `requiresOnDeviceRecognition = true`로 기기에서만 처리하며 녹음·전송하지 않는다. |
| 사진 또는 비디오 | 수집 안 함 | 카메라 프레임은 Vision 텍스트 인식에 쓰고 바로 버린다. |
| 기타 센서(동작) | 수집 안 함 | 가속도계는 출발·정차 감지에만 기기 안에서 쓴다. |
| 연락처 정보, 사용자 콘텐츠, 검색 기록, 구매, 재무, 건강 | 수집 안 함 | 해당 기능 없음. 경로 검색은 기기 안에서 계산한다. |
| 진단 (충돌, 성능) | 수집 안 함 | Crashlytics·Performance Monitoring을 쓰지 않는다. 나중에 추가하면 “충돌 데이터 / 성능 데이터 — 앱 기능, 연결 안 함” 을 추가해야 한다. |

서울 열린데이터광장 실시간 도착 API에는 역 이름만 보낸다. 사용자 데이터가 아니므로 수집 항목에 넣지 않는다.

**추적 (Tracking) → 아니요.** IDFA를 쓰지 않고, ATT 권한을 요청하지 않으며, 광고 네트워크나 데이터 브로커와 공유하지 않는다.
`GoogleService-Info.plist` 의 `IS_ADS_ENABLED` 가 false 이고, Firebase 광고 식별자 수집도 하지 않는다.

**코드 쪽 정리 (1.0.5에서 반영함)**

- `KORA/PrivacyInfo.xcprivacy`: 예전의 정확한 위치(앱 기능) 선언을 빼고 위 표와 같은 세 항목(Device ID, Product Interaction, Coarse Location, 분석 목적, 연결 안 함, 추적 안 함)으로 바꿨다. Firebase SDK도 자체 매니페스트를 포함한다.
- 사진 보관함 권한 문구(`NSPhotoLibraryUsageDescription`)와 카카오·네이버 키를 `Info.plist`에서 뺐다.
- 공유 익스텐션(KORAShare)과 저장 장소 위젯을 빌드에서 뺐다.

## 4. 수출 규정 준수 (Export Compliance)

- 앱은 Apple이 제공하는 표준 HTTPS(URLSession)만 쓰고, 자체 암호화 알고리즘이 없다 → 면제 대상.
- App Store Connect 질문: “앱에서 암호화를 사용합니까?” → 표준 암호화만 사용 / “위에 언급된 알고리즘 중 어느 것도 해당하지 않음”.
- `Info.plist` 에 `ITSAppUsesNonExemptEncryption` = `NO` 를 넣어 두었다 (1.0.5). 업로드할 때마다 묻지 않는다.
- 프랑스 배포용 문서 불필요.

## 5. 콘텐츠 권한 (Content Rights)

“앱에 제3자 콘텐츠가 포함되어 있거나, 이를 표시하거나 접근합니까?” → **예**, 그리고 “필요한 권리를 보유하고 있음”.

- 실시간 도착 정보: 서울 열린데이터광장(서울특별시, data.seoul.go.kr) 공개 API. 서울 열린데이터광장의 데이터는 대부분 공공누리 제1유형(출처표시, 상업적 이용 가능)으로 제공된다. 해당 데이터셋 페이지에서 유형을 한 번 확인하고, 앱이나 웹사이트에 “실시간 도착 정보: 서울특별시 서울 열린데이터광장” 출처 표시를 넣어 두는 것을 권장한다. (현재 앱 화면에 출처 표시가 있는지는 확인하지 못했다.)
- 역 이름, 노선, 좌표 등 역 데이터: 공공 정보 기반. 원출처가 공공데이터포털 등 공공누리 데이터라면 같은 방식으로 출처를 표시한다.

## 6. 앱 심사 정보 (App Review Information)

- 로그인 필요: 아니요 (데모 계정 없음)
- 연락처: Leeo, mizzking75@gmail.com (전화번호는 App Store Connect 계정 값 사용)

**심사 메모 (영어, 그대로 붙여 넣기)**

```
KORA is a single-screen subway guide for travelers in Korea. No account or login is required, and there are no in-app purchases or ads.

How to test route guidance:
1. Tap the current-station card at the top and choose a station, for example Seoul Station. If you allow location while outside Korea, the nearest station will be far away, so please pick stations manually.
2. Tap the destination card and choose another station, for example Gangnam. You can switch cities with the region chips at the top of the station picker.
3. The route appears with transfers, number of stops, estimated time and the boarding direction shown as the train's destination sign.

Route search is calculated on device and works offline. Real-time arrival data comes from the Seoul Open Data Plaza API (data.seoul.go.kr) and requires a network connection; when it is unavailable, the app automatically falls back to a timetable-based estimate, so ride tracking outside Korea will only show estimates.

Optional features, all processed on device:
- Camera: "Check direction with camera" reads platform signs and train destination displays with Apple Vision text recognition. Frames are not stored or transmitted.
- Microphone and Speech Recognition: recognize in-train announcements with on-device recognition only (requiresOnDeviceRecognition = true). Audio is not recorded, stored or transmitted.
- Motion: the accelerometer detects departures and stops.
Declining any of these permissions does not block the main features.

While riding, a Live Activity shows progress on the Lock Screen and Dynamic Island. It ends when the app is closed.

Long-press a station card to change the app language (Korean, Japanese, English, Simplified Chinese, Traditional Chinese).

Analytics: Google Analytics for Firebase collects anonymous usage data only. No IDFA, no App Tracking Transparency prompt, no tracking.
```

## 7. 스크린샷 체크리스트

앱 타깃이 iPhone 전용(`TARGETED_DEVICE_FAMILY = 1`)이므로 iPad 스크린샷은 필요 없다.

- 필수: **iPhone 6.9형** (1320 × 2868 또는 1290 × 2796, 세로). 이 크기만 올리면 작은 화면용은 자동으로 축소된다.
- 언어별로 최대 10장, 최소 1장. 권장 5~6장.
- 이전 버전 스크린샷(장소 저장, 지도, 탭 화면)은 모든 언어에서 **반드시 교체**. 없어진 기능이 보이면 심사 반려 사유(가이드라인 2.3)가 된다.

| # | 화면 | 캡션 방향 (각 언어로) |
|---|---|---|
| 1 | 출발역·도착역을 고른 경로 화면 (“○○행” 방향 표시가 보이게) | 타는 방향을 열차 표시 그대로 |
| 2 | 카메라 방향 확인 결과 (“이 방향이 맞아요”) | 카메라로 방향 확인 |
| 3 | 탑승 중 진행도 (열차 아이콘, 도착역 핀, “곧 내릴 준비하세요”) | 내릴 역을 놓치지 않게 |
| 4 | 잠금 화면 라이브 액티비티 / Dynamic Island | 잠금 화면에서 바로 확인 |
| 5 | 역 선택 화면 (지역 칩: 수도권, 부산, 대구, 광주, 대전) | 전국 약 930개 역 |
| 6 | 역 이름 다국어 표시 또는 언어 선택 화면 | 5개 언어 지원 |

| 언어 | 6.9형 iPhone 스크린샷 | 앱 화면 언어 |
|---|---|---|
| 한국어 | [ ] 1 [ ] 2 [ ] 3 [ ] 4 [ ] 5 [ ] 6 | 한국어 |
| English (U.S.) | [ ] 1 [ ] 2 [ ] 3 [ ] 4 [ ] 5 [ ] 6 | English |
| 日本語 | [ ] 1 [ ] 2 [ ] 3 [ ] 4 [ ] 5 [ ] 6 | 日本語 |
| 简体中文 | [ ] 1 [ ] 2 [ ] 3 [ ] 4 [ ] 5 [ ] 6 | 简体中文 |
| 繁體中文 | [ ] 1 [ ] 2 [ ] 3 [ ] 4 [ ] 5 [ ] 6 | 繁體中文 |

앱 미리보기 영상은 선택 사항.

## 8. 언어별 URL

App Store Connect에서 “개인정보 처리방침 URL”은 앱 정보(언어별), “지원 URL”과 “마케팅 URL”은 버전 페이지(언어별)에 넣는다.

| 언어 | 마케팅 URL | 지원 URL | 개인정보 처리방침 URL |
|---|---|---|---|
| 한국어 | https://m1zz.github.io/KORA/ko/ | https://m1zz.github.io/KORA/ko/support.html | https://m1zz.github.io/KORA/ko/privacy.html |
| English (U.S.) | https://m1zz.github.io/KORA/en/ | https://m1zz.github.io/KORA/en/support.html | https://m1zz.github.io/KORA/en/privacy.html |
| 日本語 | https://m1zz.github.io/KORA/ja/ | https://m1zz.github.io/KORA/ja/support.html | https://m1zz.github.io/KORA/ja/privacy.html |
| 简体中文 | https://m1zz.github.io/KORA/zh-Hans/ | https://m1zz.github.io/KORA/zh-Hans/support.html | https://m1zz.github.io/KORA/zh-Hans/privacy.html |
| 繁體中文 | https://m1zz.github.io/KORA/zh-Hant/ | https://m1zz.github.io/KORA/zh-Hant/support.html | https://m1zz.github.io/KORA/zh-Hant/privacy.html |

예전 주소(https://m1zz.github.io/KORA/, /support.html, /privacy.html)도 계속 동작한다. 브라우저 언어를 보고 위 언어별 페이지로 넘겨 준다.

## 9. 제출 전 확인

- [ ] 5개 언어 현지화 추가 (중국어 번체는 이번에 새로 추가)
- [ ] 언어별 이름·부제·설명·키워드·프로모션 텍스트·새로운 기능 입력
- [ ] 이름이 이미 쓰이고 있으면 각 파일의 대체안 사용
- [ ] 언어별 URL 3개 입력
- [ ] 스크린샷 전체 교체
- [ ] 앱 개인정보 보호 답변 갱신 (3항) (`PrivacyInfo.xcprivacy`는 정리 완료)
- [x] 사용하지 않는 `NSPhotoLibraryUsageDescription` 삭제
- [x] `ITSAppUsesNonExemptEncryption = NO` 추가
- [ ] GitHub Pages 배포 확인 (main 브랜치 `/docs`, 푸시 후 1~2분)
