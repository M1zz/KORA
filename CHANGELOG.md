# Changelog

KORA のリリースノート / KORA 릴리즈 노트.

## 1.0.4 (2026-07-14)

全国の地下鉄に対応しました。GTX-A（キンテックス）も乗れます。
전국 지하철을 지원합니다. GTX-A(킨텍스)도 탈 수 있어요.

### App Store「このバージョンの新機能」/ "이번 버전의 새로운 기능"

**日本語**
- GTX-A に対応（キンテックス・ソウル駅・水西・東灘など）— ご要望ありがとうございます！
- 全国の地下鉄を追加：釜山・大邱・光州・大田、仁川 1・2号線、京春線・西海線・慶江線、金浦ゴールドライン・新林線・牛耳新設線など
- 地域カテゴリを新設（ソウル/京畿・仁川・釜山・大邱・光州・大田）。選んだ地域は保存され、次回もそのまま
- 1号線 漣川延伸・5号線 江一・7号線 山谷/石南・6号線 鷹岩ループの各駅など、既存路線の抜けを補完
- 細かな不具合修正

**한국어**
- GTX-A 지원 (킨텍스·서울역·수서·동탄 등) — 피드백 감사합니다!
- 전국 지하철 추가: 부산·대구·광주·대전, 인천 1·2호선, 경춘선·서해선·경강선, 김포골드라인·신림선·우이신설선 등
- 지역 카테고리 신설 (서울/경기·인천·부산·대구·광주·대전). 선택한 지역은 저장되어 다음에도 유지
- 1호선 연천 연장·5호선 강일·7호선 산곡/석남·6호선 응암순환 개별역 등 기존 노선 누락 보완
- 자잘한 버그 수정

**English**
- GTX-A support (KINTEX, Seoul Station, Suseo, Dongtan and more) — thanks for the feedback!
- Nationwide metro coverage: Busan, Daegu, Gwangju, Daejeon, Incheon Lines 1·2, Gyeongchun/Seohae/Gyeonggang lines, Gimpo Gold Line, Sillim, Ui-Sinseol and more
- New region categories (Seoul/Gyeonggi, Incheon, Busan, Daegu, Gwangju, Daejeon) — your choice is remembered
- Filled gaps on existing lines: Line 1 Yeoncheon extension, Gangil (Line 5), Sangok/Seoknam (Line 7), Eungam-loop stations (Line 6)
- Minor bug fixes

**中文（简体）**
- 支持 GTX-A（KINTEX、首尔站、水西、东滩等）
- 新增全国地铁：釜山、大邱、光州、大田、仁川 1·2号线、京春线·西海线·庆江线、金浦金线·新林线·牛耳新设线等
- 新增地区分类（首尔/京畿、仁川、釜山、大邱、光州、大田），所选地区会被保存
- 补全既有线路：1号线涟川延伸、5号线江一、7号线山谷/石南、6号线鹰岩环线各站
- 修复了一些小问题

### 詳細 / 상세 (developer)

**Nationwide metro data**
- GTX-A (14): 운정중앙↔서울역 / 수서↔동탄 두 분리 구간, 실시간 도착
  subwayId 1032 매핑, 환승(서울역·연신내·대곡·수서·구성·성남) 자동 파생.
- 수도권 신규 노선: 경춘선(15)·경강선(16)·서해선(17)·김포골드라인(18)·
  신림선(19)·우이신설선(20)·의정부경전철(21)·용인에버라인(22)·
  인천 1호선(23)·인천 2호선(24).
- 지방 권역: 부산 1~4호선·부산김해경전철·동해선(31~36), 대구 1~3호선·
  대경선(41~44), 광주 1호선(51), 대전 1호선(61).
- 기존 노선 보정: 1호선 연천 연장(연천·전곡·청산)+광명셔틀, 5호선 강일,
  6호선 응암순환 개별역(역촌·불광·독바위·연신내·구산, 선형 꼬리로 근사),
  7호선 산곡·석남, 경의중앙선 본선 홍대입구 누락 수정 + 서울역지선 분리
  (경의선 신촌은 2호선 신촌과 별개 역으로 정정).
- 전 역 좌표(WGS84)·카타카나·영문 표기 추가 (SubwayStationDataExpansion).

**Region model**
- MetroRegion(수도권/부산/대구/광주/대전) 도입: 권역이 다른 노선 간 환승·
  경로 탐색 차단 (동명이역 오연결 방지).
- 동명이역 구분 표기: 시청(부산)·시청(대전)·용문(대전)·교대(부산)·
  대곡(대구)·양평(서울)·신촌(경의중앙)·부전(동해선) 등. 실시간 API 조회 시
  괄호 표기를 벗겨 원 역명으로 질의.
- MetroCategory (서울/경기·인천·부산·대구·광주·대전): 역 선택 화면 상단
  카테고리 칩, @AppStorage("KORA.metroCategory")로 영구 저장. 검색은 전국,
  둘러보기는 선택 권역만.

**App**
- Version 1.0.4 (build 5).

## 1.0.3 (2026-06-23)

今回は内部の改善のみで、画面の見た目に変化はありません。
이번에는 내부 개선만 적용했고, 화면상 보이는 변화는 없습니다.

### App Store「このバージョンの新機能」/ "이번 버전의 새로운 기능"

**日本語**
- アプリの安定性を改善しました
- 細かな不具合を修正しました

**한국어**
- 앱 안정성을 개선했습니다
- 자잘한 버그를 수정했습니다

**English**
- Improved app stability
- Minor bug fixes

**中文（简体）**
- 提升了应用稳定性
- 修复了一些小问题

### 詳細 / 상세 (developer)

**Analytics**
- Firebase Analytics（Google Analytics）を SPM で導入し、起動時に
  FirebaseApp.configure() を呼ぶように。/ Firebase Analytics(Google
  Analytics)를 SPM으로 도입하고 앱 시작 시 FirebaseApp.configure() 호출.
- データが届かなかった根本原因を修正：OTHER_LDFLAGS = -ObjC を追加し、静的
  ライブラリ GoogleAppMeasurement の Obj-C 登録がリンク時に剥がれないように。
  これが無いと Core は configure されても Analytics エンジンが起動せず、計測
  DB も作られずイベントも記録されなかった。/ 데이터 미수집 근본 원인 수정:
  OTHER_LDFLAGS = -ObjC 추가로 정적 라이브러리 GoogleAppMeasurement의 Obj-C
  등록이 링크 단계에서 제거되지 않도록 함. 이게 없으면 Core는 configure돼도
  Analytics 엔진이 가동되지 않아 측정 DB·이벤트가 전혀 생기지 않았음.
- GoogleService-Info.plist の IS_ANALYTICS_ENABLED が再ダウンロードのたびに
  false で降ってくるため、収集が左右されないよう Info.plist に
  FIREBASE_ANALYTICS_COLLECTION_ENABLED = YES を追加。/ 재다운로드 시마다
  GoogleService-Info.plist의 IS_ANALYTICS_ENABLED가 false로 내려와, 수집이
  그 값에 좌우되지 않도록 Info.plist에 FIREBASE_ANALYTICS_COLLECTION_ENABLED =
  YES 추가.
- シミュレータで検証：Analytics 起動・collection enabled・first_open /
  session_start のイベント記録・計測 DB 生成を確認。/ 시뮬레이터에서 검증:
  Analytics 가동·collection enabled·first_open / session_start 이벤트 기록·
  측정 DB 생성 확인.

## 1.0.2 (2026-06-22)

乗る前・乗っている間の画面を、もっと一目でわかるように整えました。
타기 전·타는 중 화면을 한눈에 더 잘 보이도록 다듬었습니다.

### App Store「このバージョンの新機能」/ "이번 버전의 새로운 기능"

**日本語**
- 乗車前・乗車中の見出しに「○号線 ○○行」を表示。ホームの行先表示とそのまま見比べられます
- 次の駅を「次の駅 ❯❯❯ 漢南」のように表示し、矢印が駅名へ流れるアニメーションに
- 乗車後は「乗車中」バッジを表示
- 目的地までの図を距離に合わせて変化：あと2駅以内は全駅を表示、遠いときは「現在地 ⋯ 目的地」に省略し、近づくほど駅が増えていきます
- 現在駅カードに位置ピンボタンを追加（タップで位置を修正）
- 位置が定まると、オレンジの枠が一気に消えず、カウントダウンのように少しずつ消えます
- 細かな整理と不具合修正

**한국어**
- 탑승 전·탑승 중 머리말에 "○호선 ○○행"을 표시 — 승강장 행선 표시와 바로 대조할 수 있어요
- 다음 역을 "다음역 ❯❯❯ 한남"처럼 표시하고, 화살표가 역 이름 쪽으로 흐르는 애니메이션 적용
- 탑승 후에는 "탑승 중" 배지 표시
- 목적지까지의 그림이 거리에 맞춰 변화: 2정거장 이내는 모든 역 표시, 멀면 "현재 ⋯ 목적지"로 축약하고 가까워질수록 역이 늘어남
- 현재역 카드에 위치 핀 버튼 추가 (탭하면 위치 보정)
- 위치가 확실해지면 주황 테두리가 한 번에 사라지지 않고 카운트다운처럼 서서히 줄어들며 사라짐
- 자잘한 정리 및 버그 수정

**English**
- Shows the "Line N · bound-for" sign on the before/while-boarding header, so you can match it to the platform's destination indicator
- Next stop now reads "Next ❯❯❯ Hannam" with the arrows flowing toward the station name
- Adds an "On board" badge once you've boarded
- The route diagram adapts to distance: within 2 stops every station is drawn; farther out it collapses to "you ⋯ destination" and fills back in as you get closer
- Location-pin button on the current-station card (tap to fix your position)
- When your position firms up, the orange "uncertain" border drains away like a countdown instead of blinking out
- Cleanups and bug fixes

**中文（简体）**
- 在乘车前／乘车中标题显示「N号线 开往○○」，可直接与站台终点显示屏对照
- 下一站显示为「下一站 ❯❯❯ 汉南」，箭头朝站名方向流动
- 上车后显示「乘车中」标记
- 到目的地的示意图随距离变化：剩余 2 站以内显示全部车站，较远时收起为「当前 ⋯ 目的地」，越接近显示的车站越多
- 当前车站卡片新增定位按钮（点按修正位置）
- 位置确定后，橙色边框不再一闪而过，而是像倒计时一样逐渐消失
- 细节优化与问题修复

### 詳細 / 상세 (developer)

**Pre-boarding**
- Status row now carries a compact "X호선 ○○행" sign (lineDirectionLabel),
  shown on both the 탑승 전 and 탑승 중 badges.
- Replaced the moving-train approach visual with a single "다음역 ❯❯❯ 한남"
  row; the chevrons sweep toward the name (FlowingChevrons) instead of a tram
  icon. Removed the now-dead approach-track code (trainApproachVisual,
  ApproachTrainTrack, previousStations, approachAccessibility, Verify* track).

**In-transit**
- Added an "On board" status badge mirroring the pre-boarding badge.
- Progress diagram is now distance-adaptive: within 2 stops every station from
  the current position to the destination is drawn; beyond that it collapses to
  "current ⋯ destination" and the dots reappear as the train closes in.
- Location-pin button on the current-station card opens position correction.

**Uncertainty UX**
- When confidence recovers, the orange position-uncertain treatment no longer
  blinks out: the border trims away (1→0) over ~1.6 s like a countdown, with the
  background fill and prompt fading in step, so the rider can anticipate it
  clearing. A generation token cancels the drain if the position goes uncertain
  again mid-fade.

**App**
- Version 1.0.2 (build 3).

## 1.0.1 (2026-06-21)

地下鉄ナビを大幅に強化しました。乗っている電車と画面が「ぴったり合う」ことに集中したアップデートです。
지하철 내비게이션을 대폭 강화했습니다. 지금 탄 지하철과 화면이 "딱 맞는" 것에 집중한 업데이트입니다.

### App Store「このバージョンの新機能」/ "이번 버전의 새로운 기능"

**日本語**
- 車内放送を聞き取って現在の駅を自動で判定（オンデバイス音声認識・地下でも動作）
- カメラを電車の行先表示にかざすと、乗ってよい方向かを緑／赤で判定
- リアルタイム到着・加速度・GPS を組み合わせ、出発と停車のタイミングを正確に表示
- 出発駅の選択時に近くの駅を表示
- 4号線 真接（チンジョプ）延伸に対応
- 降車をうながす案内をより安全に（確認できた時だけ強い通知）
- 不具合修正と画面の整理

**한국어**
- 안내방송을 인식해 현재 역을 자동 판별 (온디바이스 음성인식, 지하에서도 동작)
- 카메라를 열차 행선지에 비추면 타도 되는 방향인지 초록/빨강으로 판정
- 실시간 도착·가속도·GPS를 결합해 출발·정차 타이밍을 정확히 표시
- 출발지 선택 시 가까운 역 표시
- 4호선 진접 연장 반영
- 하차 안내를 더 안전하게 (확인된 경우에만 강한 알림)
- 버그 수정 및 화면 정리

**English**
- Hears station announcements to auto-detect your current stop (on-device speech, works underground)
- Point the camera at a train's destination sign — green/red tells you if it's your direction
- Fuses realtime arrivals, motion and GPS for accurate departure/stop timing
- Shows nearby stations when picking your departure
- Line 4 Jinjeop extension added
- Safer "get off" prompts (strong alert only when position is confirmed)
- Bug fixes and a cleaner UI

**中文（简体）**
- 识别车内广播自动判断当前车站（设备端语音识别，地下也可用）
- 用相机对准列车终点站显示屏，绿色/红色提示是否为你的方向
- 结合实时到站、加速度与 GPS，准确显示发车与停车时机
- 选择出发站时显示附近车站
- 新增 4 号线榛接延伸段
- 更安全的下车提示（仅在确认位置时强提醒）
- 修复问题并优化界面

### 詳細 / 상세 (developer)

**Subway position sync**
- On-device Korean speech recognition of PA announcements ("이번 역은 ○○",
  door side) as the highest-authority position source, with a confirmation badge.
- Wired the Seoul Open API realtime arrival feed in as an authoritative
  departure/stop source (line→subwayId mapping incl. AREX/Shinbundang/
  Suin-Bundang/Gyeongui-Jungang).
- Event-driven index fusion (realtime > GPS > motion > time): a sensed stop
  surfaces immediately instead of on a 30 s timer.
- Safety: monotonic index, destination clamp, motion overcount cap, GPS
  staleness handling, confidence tiers; early-alight guard (confirmation-gated
  get-off cues + name-anchored verification).

**Direction (camera)**
- Inline live OCR scanner: point at the train's destination display; GREEN when
  a valid destination (the stop or beyond) is read, RED for short-turn/opposite
  termini (e.g. a 사당-bound train when heading to 경마공원). Shows the recognized
  destination large.

**UX**
- Nearby stations in the departure picker; next-station hero with arrows;
  dropped the misleading single "○○행" label; discoverable in-transit position
  correction; ride block now scrolls.

**Data / fixes**
- Line 4 진접선 extension (진접·오남·별내별가람).
- Faster location lookups (cached fix + timeout); fixed a duplicate-coordinate
  crash; deterministic journey selection (no confirm-screen bounce); fixed the
  confirm→active screen transition.

**App**
- Version 1.0.1 (build 2). Added microphone, speech-recognition and camera
  usage descriptions.

## 1.0.0

Initial release.
