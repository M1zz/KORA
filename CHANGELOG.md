# Changelog

KORA のリリースノート / KORA 릴리즈 노트.

## 1.0.3 (2026-06-23)

内部の改善のみのリリースです。利用状況の把握のため Firebase Analytics を追加しました。
내부 개선 릴리즈입니다. 사용 현황 파악을 위해 Firebase Analytics를 추가했습니다.

### 変更点 / 변경점

- Firebase Analytics（Google Analytics）を導入し、利用状況の計測を有効化 / Firebase Analytics(Google Analytics) 도입 및 사용 통계 수집 활성화
- 細かな整理と不具合修正 / 세부 정리 및 안정성 개선

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
