# Changelog

KORA のリリースノート / KORA 릴리즈 노트.

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
