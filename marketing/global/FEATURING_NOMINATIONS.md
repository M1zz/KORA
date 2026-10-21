# 피처링 추천 (Featuring Nominations)

App Store Connect ▸ 앱 ▸ **Featuring** ▸ **Nominations** ▸ (+) 에 그대로 붙여 넣는 원고다.
DeployBar 는 이 칸을 올리지 못하므로 사람이 웹에서 넣는다.

작성일 2026-10-21. 지금 스토어에 있는 버전은 **1.0.8** (빌드 11), 1.0.9 는 레포에 커밋·릴리즈 노트까지 끝났고 아직 배포 전이다.
앱 ID 6775176578 · 번들 com.kora.leeo · 스토어 이름 `KORA: Korea Subway Navigator` (한국어 `KORA: 한국 지하철 길찾기`).

## 폼의 칸과 규칙 (Apple 문서로 확인한 것)

출처: [Getting featured](https://developer.apple.com/app-store/getting-featured/), [Nominate your app for featuring](https://developer.apple.com/help/app-store-connect/manage-featuring-nominations/nominate-your-app-for-featuring) (2026-10-21 확인)

| 칸 | 내용 | 한도 |
|---|---|---|
| Name | 추천을 알아볼 이름 (내부용) | 문서에 글자 수 한도 없음 |
| Type | New Content / App Enhancements / App Launch 중 하나. 제출 뒤에는 못 바꾼다 | |
| Description | 무엇이 바뀌는지, 목적, 기능의 의도 | 문서에 한도 없음 (아래 원고는 1,500자 안팎) |
| Publish Date | Day(하루) 또는 Range(기간). **내 기기 시간대**로 해석된다 | |
| Related Apps | 같은 계정의 앱 최대 10개 | |
| Platforms | iPhone (iPad 는 앱이 지원하지 않으면 빼기) | |
| Relevant Countries or Regions | 판매 국가로 자동 선택, 고칠 수 있다 | |
| Localizations | 앱 현지화로 자동 선택 (23개 그대로 둔다) | |
| In-App Events | **승인되었거나 게시된** 인앱 이벤트만 붙일 수 있다 | |
| Supplemental Materials | 참고 URL 최대 5개 (TestFlight 공개 링크 가능) | 5개 |
| Helpful Details | 접근성 · 포용성 · 우선순위 · 팀 이야기 | |

시기: Apple 은 **최소 2주 전**(Getting featured), App Store Connect 도움말은 **3주 전**을 권하고, 넓게 검토받으려면 **최대 3개월 전**에 내라고 한다.
에디터가 보는 것: 사용자 경험, UI, 혁신, 독창성, **접근성**, **현지화**, 제품 페이지(스크린샷·평점). 평점 0개는 약점이므로 이벤트·디렉터리로 첫 평점을 먼저 모은다.

## 한눈에

| # | 유형 | 이름 | 게시 예정 | 지금 낼 수 있나 |
|---|---|---|---|---|
| N1 | App Enhancements | KORA 1.0.9: Ride with VoiceOver | 2026-11-19 ~ 2026-12-17 | 예. 1.0.9 를 **11월 5일까지** 배포해야 한다 |
| N2 | App Enhancements | KORA: Line 9 Express Check for Winter Travel | 2026-12-18 ~ 2027-01-16 | 예. 단 급행 구별을 **12월 10일까지** 내보낼 수 있을 때만 |
| N3 | App Enhancements | KORA for Global Accessibility Awareness Day 2027 | 2027-05-20 (GAAD) | **다음 기회.** 3개월 밖이라 2027-02-20 ~ 04-29 사이에 낸다 |

---

## N1. 1.0.9 접근성 업데이트

- **Type**: App Enhancements
- **Name**: `KORA 1.0.9: Ride with VoiceOver`
- **Publish Date**: Range `2026-11-19` ~ `2026-12-17` (인앱 이벤트 E1 과 같은 기간)
- **선행 조건**: 1.0.9 가 2026-11-05 까지 스토어에 나가 있어야 한다 (`DeployBar --deploy 한국길찾기`).
- **Platforms**: iPhone
- **Relevant Countries or Regions**: 전체 유지. 특히 미국·영국·캐나다·호주(영어 VoiceOver 사용자, AppleVis 독자층), 일본·대만·홍콩(방한객 상위 + 앱 현지화 품질이 높은 언어).
- **In-App Events**: E1 `The Accessibility Update` 가 승인되면 붙인다.
- **Supplemental Materials**:
  1. https://m1zz.github.io/KORA/en/
  2. https://m1zz.github.io/KORA/en/support.html
  3. (있으면) 1.0.9 TestFlight 공개 링크
  4. (있으면) VoiceOver 로 탑승→하차를 끝까지 해 보는 화면 녹화 영상 링크

**Description** (붙여 넣기)

```
KORA is a subway guide built for people visiting Korea, and version 1.0.9 makes the whole ride work without looking at the screen.

The core of KORA is three slide gestures: slide to board, slide to transfer and slide to get off. In 1.0.9 each of them is also an accessibility action, so VoiceOver users can board, transfer and get off with a single action, and Voice Control users can say the same command by name. When a stop approaches, KORA shows "Prepare to get off" and then "Get off now" with haptics, so the cue is felt as well as seen (vibration alerts are free for the first three journeys, then part of a one-time KORA Pro purchase; route guidance itself is always free).

The update also respects system display settings across the app: Increase Contrast switches to a high-contrast accent palette with stronger borders and secondary text, small accent text keeps at least 4.5:1 contrast, Reduce Motion replaces sliding pages and flowing arrows with calm cross-fades, Reduce Transparency makes bars opaque, and Differentiate Without Color marks unvisited stations with an outline instead of colour alone. Large text no longer truncates the first screen.

For first-time riders there is a short three-page guide, shown before any permission request, and a What's New page after updates. Feedback and replies now live inside the app.

KORA covers about 930 stations in the Seoul area, Busan, Daegu, Gwangju and Daejeon, works offline for route search, and is fully localized in 23 languages, with station names shown in Korean next to katakana, Chinese characters or the romanized spelling on Korean station signs. Location, camera and announcement recognition stay on the device. No account, no ads.

KORA is made by one independent developer in Korea. The UI test suite runs Xcode's accessibility audit on the main screen and the onboarding on every change.
```

**Helpful Details** (붙여 넣기)

```
Honest scope: boarding, transferring and getting off are fully operable with VoiceOver and Voice Control in 1.0.9. A complete VoiceOver pass over every screen (reading order, every label) is the next item on our public in-app roadmap. The camera direction check shows its verdict as large on-screen text and colour; it is not announced automatically yet. In-app events and a TestFlight build are available on request.
```

**근거 (코드·커밋)**

- `6cc2d08` feat: 사용법 안내·새로 생긴 것·앱 안 의견·접근성·운영 장치 (1.0.9)
- `SubwayNavigatorView.swift` 의 `.accessibilityAction` — 밀어서 타기(540행)·갈아타기(602행)·내리기(664행)
- `accessibilityReduceMotion`, `accessibilityDifferentiateWithoutColor`, `colorSchemeContrast` 대응, `KORAAccentText` 색 에셋
- `KORAUITests.swift` 의 `performAccessibilityAudit` 두 건 (첫 화면 · 사용법)
- `KORARoadmap.swift`: `a11y.contrast`, `a11y.motion` 이 1.0.9 로 내보냄, `a11y.voiceover`(전 화면 VoiceOver)는 아직 계획 — 그래서 위 Helpful Details 에 정직하게 적었다.
- `RELEASE_NOTES.md` 1.0.9: "VoiceOver로도 타고 내릴 수 있어요"

**한국어 요약**: 1.0.9 에서 밀어서 타기·갈아타기·내리기가 VoiceOver·음성 제어 동작이 되고, 대비 증가·동작 줄이기·투명도 줄이기·색 없이 구별에 맞춰 화면이 바뀐다. 첫 사용 안내·앱 안 의견도 들어갔다. 모든 화면의 VoiceOver 정리는 아직 로드맵이라는 점은 숨기지 않았다.

---

## N2. 9호선 급행 구별 (겨울 여행 시즌)

- **Type**: App Enhancements
- **Name**: `KORA: Line 9 Express Check for Winter Travel`
- **Publish Date**: Range `2026-12-18` ~ `2027-01-16` (인앱 이벤트 E2 와 같은 기간)
- **선행 조건**: 급행 구별(로드맵 `express`, 지금 `.building`)이 들어간 다음 버전(1.0.10 예상)이 **2026-12-10 까지** 배포돼야 한다. 못 맞추면 이 추천은 내지 않거나 날짜를 미룬다 (Draft 상태면 날짜를 고칠 수 있다).
- **Relevant Countries or Regions** (근거: 한국관광공사 2025년 국적별 입국 — 1~5월 누계 중국 205만·일본 133만·대만 70만·미국 56만, 11월 한 달 중국 37.8만·일본 36.3만·대만 15.8만·미국 13.3만·필리핀 6만):
  - **일본**: 연말연시(12/27~1/4 무렵) 방한 성수기. 하네다·간사이 ↔ 김포 노선이 9호선 급행 정차역 **김포공항**으로 들어온다.
  - **대만·홍콩**: 송산 ↔ 김포 노선, 겨울 방한 수요. 앱이 번체를 완전히 지원.
  - **미국·캐나다·영국·호주·싱가포르·필리핀**: 크리스마스·연말 휴가.
  - **태국·베트남·인도네시아**: 상위 동남아 방한국, 앱이 각 언어 지원.
  - **중국 본토**: 방한 1위지만 중국 스토어 판매 여부(ICP 비안)를 먼저 확인한다. 판매 중이 아니면 빼고, 판매 중이면 춘절(2027-02-06 전후)은 다음 추천으로 따로 낸다.
- **In-App Events**: E2 `Line 9 Express Check` 승인 뒤 붙인다.

**Description** (붙여 넣기)

```
Seoul Subway Line 9 runs express and local trains on the same tracks. Express trains stop at only 16 of its 38 stations, and the platform board marks them with the Korean word 급행 (express) only. For a visitor who boards an express by mistake, the train simply runs past their stop.

Line 9 is also the line many visitors meet first: it starts at Gimpo International Airport, where flights from Tokyo Haneda, Osaka Kansai and Taipei Songshan land, and runs through Yeouido, the Express Bus Terminal and Gangnam to Olympic Park.

KORA's camera direction check already tells riders, on the platform, whether the train in front of them goes the right way. This update teaches it to read the top line of the Line 9 platform board, the next train, and to recognise express trains. If the next express will not stop at the rider's destination, KORA says so in their language and suggests taking the local train instead. Text recognition runs entirely on the device, and the camera check is free for everyone.

We are timing this for the winter travel season, from the year-end holidays in Japan, Taiwan and the US through mid-January, when first-time riders arrive at Gimpo with luggage and little Korean.

KORA covers about 930 stations across Seoul, Busan, Daegu, Gwangju and Daejeon in 23 languages, finds routes offline, follows the ride on the Lock Screen and alerts riders before their stop. Made by one independent developer in Korea.
```

**Helpful Details** (붙여 넣기)

```
Scope: express detection starts with Line 9 only, which is the only Seoul line where the app has express stop data. The judgement engine is shared with our Japanese sister app, so the same approach will extend to other lines with express services.
```

**근거 (코드·커밋)**

- `2e236ce` feat(카메라): 급행이 내 역을 지나치면 알려 준다 (9호선부터) — 전광판 맨 윗줄(다음 열차)로 판정
- `68e0c56` 판정 엔진을 TrainBoardKit 패키지로 (일본길찾기와 공유)
- `SubwayLineData.swift` 의 `line9Express`: 김포공항~중앙보훈병원, 정차역 16곳, 안내판 표기 "급행"
- navloc `scanSkipsStop`: "{0}에 서지 않는 열차예요. 일반열차를 타세요" (23개 언어)
- APPSTORE.md: 카메라 방향 확인은 언제나 무료, 글자 인식은 기기 안에서

**한국어 요약**: 9호선은 급행과 일반이 같은 선로를 달리고 급행은 38개 역 중 16곳에만 선다. 김포공항으로 들어오는 일본·대만 여행자가 처음 만나는 노선이라, 카메라로 전광판을 비추면 급행이 내 역을 지나치는지 알려 주는 기능을 겨울 성수기에 맞춰 추천한다. 아직 개발 중이므로 배포 일정이 확정된 뒤에 낸다.

---

## N3. 다음 기회: 세계 접근성 인식의 날 2027 (GAAD)

- **GAAD 2027**: 5월 셋째 목요일 = **2027-05-20 (목)**
- **오늘(2026-10-21) 기준 3개월 밖**이므로 지금 내지 않는다. 제출 창: **2027-02-20 ~ 2027-04-29** (3개월 전 ~ 3주 전).
- **Type**: App Enhancements (그때 내보낼 접근성 개선이 있어야 한다. 로드맵의 `a11y.voiceover` 전 화면 VoiceOver, `a11y.largetext` 큰 글씨 배치가 그 후보다. 둘 다 아직 `.planned`.)
- **Name**: `KORA for Global Accessibility Awareness Day 2027`
- **Publish Date**: Range `2027-05-13` ~ `2027-05-27`
- **할 일**: 2월까지 `a11y.voiceover` 를 만들기 시작하고, 실제 시각장애 사용자(AppleVis 포럼 등)의 확인을 받은 뒤 그 이야기를 Description 에 넣는다.

**Description 초안** (그때 사실에 맞게 고친다)

```
For Global Accessibility Awareness Day, KORA brings full VoiceOver support to every screen of its Korea subway guide. [Describe exactly what shipped: reading order, labels, announcements, larger text layouts.] Riders who are blind or have low vision can now plan a route, board, transfer and get off in any of Korea's five metro cities without sighted help. [Add a quote or feedback from a VoiceOver user, with permission.]
```

**한국어 요약**: GAAD 는 2027년 5월 20일이고 지금은 너무 이르다. 2월 20일 이후, 전 화면 VoiceOver 같은 실제 개선이 준비되면 그 내용으로 낸다.
