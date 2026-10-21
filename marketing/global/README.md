# 글로벌 마케팅 1단계 키트 (SNS 없이)

한국길찾기(KORA: Korea Subway Navigator)를 외국인 여행자와 VoiceOver 사용자에게 **SNS 운영 없이** 닿게 하는 원고 모음이다.
목표는 첫 사용자와 첫 평점이다 (2026-10-21 기준 평점 0개).
DeployBar 는 인앱 이벤트·피처링 추천을 올리지 못하므로, 여기 글을 사람이 App Store Connect 와 각 사이트에 붙여 넣는다.

## 폴더

| 파일 | 내용 |
|---|---|
| `FEATURING_NOMINATIONS.md` | App Store Connect ▸ Featuring ▸ Nominations 원고 3건 (N1·N2 지금, N3 GAAD 2027 은 다음 기회) |
| `IN_APP_EVENTS.md` | 인앱 이벤트 2건, 23개 언어 이름·짧은 설명·긴 설명 + 글자 수, Apple 규격 |
| `DIRECTORIES.md` | AppleVis 포럼 · Apptisan · Product Hunt · Seoul Start · Korea Locally · Appliv 제출 초안 |
| `events/accessibility-update/<로케일>/card.jpg` | E1 이벤트 카드 그림 1920×1080 (16:9), 23개 언어 |
| `events/accessibility-update/<로케일>/detail.jpg` | E1 상세 그림 1080×1920 (9:16), 23개 언어 |
| `events/make_event_images.py` | 레포 스크린샷으로 이벤트 그림을 만드는 스크립트 (Pillow) |

그림은 글자를 넣지 않았다 (이벤트 이름·설명은 App Store 가 그림 위에 얹는다). 스크린샷은 `docs/screenshots/raw/<로케일>/ride.png` 이고, 다시 만들려면:

```
python3 marketing/global/events/make_event_images.py docs/screenshots/raw marketing/global/events/accessibility-update ride
```

## 사람이 할 일 (순서대로)

| 언제까지 | 할 일 | 어디서 |
|---|---|---|
| 10월 넷째 주 | **피처링 추천 N1 제출** (게시 11-19~12-17). 3주 전 권장이므로 늦어도 10-29 | App Store Connect ▸ Featuring |
| 11-05 | **1.0.9 배포** (`DeployBar --deploy 한국길찾기`). N1·E1 의 전제 | DeployBar |
| 11-05 전 | **인앱 이벤트 E1 만들고 심사 제출** — 23개 언어 문구, `events/accessibility-update/` 그림. 승인되면 N1 의 In-App Events 칸에 붙인다 | App Store Connect ▸ 인앱 이벤트 |
| 1.0.9 배포 뒤 | AppleVis 포럼 글: **직접** VoiceOver 로 다시 써 보고, 본인 말투로 고쳐 본인 계정으로 올린다 (AI 대리 게시 금지 규칙) | applevis.com |
| 1.0.9 배포 뒤 | Apptisan 양식 제출, Seoul Start·Korea Locally 메일 | 각 사이트 |
| 11월 하순 평일 | Product Hunt 한 번 등록 (개인 계정) | producthunt.com |
| 11-27 | **급행 구별 일정 결정.** 12-10 배포가 가능하면 피처링 N2 제출 (게시 12-18~01-16) | App Store Connect |
| 12-04 전 | 급행 판정 화면을 찍고 E2 그림 만들기 → **인앱 이벤트 E2 제출** | 실기기 9호선 승강장 / 시뮬레이터 |
| 12-10 | 급행 구별이 든 다음 버전 배포, 로드맵 `express` → `.shipped` | DeployBar |
| 2027-02-20 ~ 04-29 | GAAD(2027-05-20) 추천 N3 — 그때 실제로 내보낼 접근성 개선이 있을 때만 | App Store Connect |

## 사람이 판단할 것

- **중국 본토 스토어**: 방한객 1위지만 중국 스토어에 나가 있는지(ICP 비안)를 확인해야 N2 지역에 넣을지 정한다.
- **Appliv**: 리뷰 의뢰 페이지가 404 였다. 사이트에서 의뢰 경로를 찾고, 없으면 일반 문의로 낸다.
- **E1 거절 위험**: 심사관이 접근성 개선을 "작은 변경"으로 볼 수 있다. `IN_APP_EVENTS.md` E1 의 "위험" 참고.
- **인앱 구매 오퍼 코드**: AppleVis 사용자에게 KORA Pro 를 써 보게 하려면 App Store Connect 에서 오퍼 코드를 만든다 (선택, 가격·결제는 사람이 정한다).

## 지키는 것

- 앱에 실제로 있는 기능만 쓴다. 근거 커밋·코드 위치를 각 문서에 적었다. 아직 계획인 것(전 화면 VoiceOver, 큰 글씨 배치)은 "된다"고 쓰지 않았다.
- 공개 글에는 실명 대신 **Leeo (리이오)**.
- 이 폴더는 원고만 담는다. App Store Connect·외부 사이트에는 아무것도 내지 않았다.
