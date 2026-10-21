# 인앱 이벤트 (In-App Events)

App Store Connect ▸ 앱 ▸ **인앱 이벤트** ▸ (+) 에 넣는 원고다. DeployBar 는 인앱 이벤트를 올리지 못한다.
이벤트는 **앱 안에서 실제로 일어나는, 기간이 있는 일**이어야 한다. 그래서 여기 둘 다 "업데이트로 실제 기능이 들어오는 순간"이다. 없는 콘텐츠·할인·경품은 만들지 않았다.

작성일 2026-10-21. 대상 기간: 앞으로 3개월(2027-01-21 까지).

## Apple 규격 (공식 문서로 확인)

출처: [In-App Events](https://developer.apple.com/app-store/in-app-events/) (2026-10-21 확인)

| 항목 | 규격 |
|---|---|
| 이벤트 이름 | 최대 **30자**, 영어는 Title Case. 행동 유도 문구·일반어 금지, 실제 이벤트 이름 |
| 짧은 설명 | 최대 **50자**, 문장형 대소문자. 이벤트 카드에 보인다 |
| 긴 설명 | 최대 **120자**, 문장형. 이벤트 상세 화면에 보인다 |
| 이벤트 카드 그림 | .jpg/.jpeg/.png, **16:9**, 최소 1920×1080, 최대 3840×2160 |
| 이벤트 카드 영상 | .mov/.m4v/.mp4, 16:9, 1920×1080~3840×2160, 30·60fps |
| 상세 화면 그림 | .jpg/.jpeg/.png, **9:16**, 최소 1080×1920, 최대 2160×3840 |
| 상세 화면 영상 | .mov/.m4v/.mp4, 9:16, 1080×1920~2160×3840, 30·60fps. 영상은 끊김 없이 반복되게 |
| 테두리·그라데이션 | 넣지 않는다 (Apple 이 자동으로 얹는다) |
| 기간 | 한 이벤트 최대 **31일** |
| 미리 노출 | 시작 **14일 전**부터 |
| 개수 | 승인 대기 포함 최대 15개, 게시 최대 10개 |
| 우선순위 | 보통 / 높음. 높음이 앞에 보인다, 같은 등급은 시작 시각 순 |
| 목적 | 모든 사용자 / 신규 사용자 유치 / 활성 사용자에게 알림 / 이탈 사용자 복귀 (노출 개인화용, 공개 안 됨) |
| 딥링크 | 유니버설 링크 권장, 단축 URL 금지 |
| 거절·비권장 | 매일 하는 반복 활동, 새 내용 없는 가격 할인, 앱 자체 홍보, 가격 표기(거절), 전부 대문자·연속 문장부호·"#1" 같은 검증 불가 주장 |

**배지 정의** (Major Update): "의미 있는 새 기능·콘텐츠·경험. 작은 UI 변경이나 버그 수정은 해당 없음."

**글자 수 세는 법**: 아래 표의 글자 수는 파이썬 `len(unicodedata.normalize('NFC', 글))` 로 센 값이다 (공백·문장부호 포함, 한중일 글자 1자 = 1). 모든 칸이 한도 안이다.

**딥링크**: 지금 앱에는 URL 스킴·유니버설 링크가 없다 (`onOpenURL`, `CFBundleURLTypes` 없음). 그래서 두 이벤트 모두 딥링크 칸을 **비워 둔다** — 열기를 누르면 앱 첫 화면이 열린다. 첫 화면에서 바로 경로를 고르고 타기까지 가므로 이벤트 내용과 어긋나지 않는다. 나중에 `kora://scan` 같은 링크를 만들면 E2 에 넣는다 (그건 `.sprintcommander/tasks.json` 거리).

## 한눈에

| # | 이벤트 | 배지 | 기간 (한국 시각) | 우선순위 | 목적 | 선행 조건 |
|---|---|---|---|---|---|---|
| E1 | The Accessibility Update | Major Update | 2026-11-19 00:00 ~ 2026-12-17 23:59 (29일) | 높음 | 신규 사용자 유치 | 1.0.9 를 11-05 까지 배포, 이벤트를 11-05 전에 제출 |
| E2 | Line 9 Express Check | Major Update | 2026-12-18 00:00 ~ 2027-01-16 23:59 (30일) | 높음 | 모든 사용자 | 급행 구별이 든 다음 버전을 12-10 까지 배포 |

두 이벤트는 기간이 겹치지 않는다. 승인되면 피처링 추천 N1·N2 의 "In-App Events" 칸에 붙인다 (`FEATURING_NOMINATIONS.md`).

### 넣지 않은 것 (그리고 그 까닭)

- **연말·설 시즌 "여행 안내" 이벤트 (Special Event)**: 앱 안에서 그 기간에만 달라지는 것이 없다. 있는 기능을 다시 알리는 것은 Apple 이 비권장하는 "앱 일반 홍보"라 거절될 가능성이 크다. 대신 E2 를 일본·대만·미국의 연말 휴가 기간에 맞췄다.
- **Pro 할인·무료 기간**: 앱에 기간 한정 무료를 켜는 장치가 없고(`KORAPro` 는 3회 무료 + 평생권 고정), 새 내용 없는 가격 이벤트는 비권장이다.
- **설·춘절 2027 (2월 6일 전후)**: 3개월 밖이다. 그때 실제로 내보낼 기능이 있으면 2027-01-23 무렵(시작 14일 전 노출)에 맞춰 새로 만든다.

---

## E1. The Accessibility Update (1.0.9)

| 항목 | 값 |
|---|---|
| 참조 이름 (내부) | `2026-11 Accessibility Update 1.0.9` |
| 배지 | Major Update |
| 이벤트 시작 | 2026-11-19 00:00 (Asia/Seoul) |
| 이벤트 종료 | 2026-12-17 23:59 (Asia/Seoul) |
| 미리 노출 시작 | 2026-11-05 (시작 14일 전, 최대치) |
| 우선순위 | 높음 |
| 목적 | 신규 사용자 유치 (Attract new users) |
| 국가·지역 | 앱 판매 국가 전체 |
| 딥링크 | 비움 (앱 첫 화면) |
| 카드 그림 | `events/accessibility-update/<로케일>/card.jpg` (1920×1080) |
| 상세 그림 | `events/accessibility-update/<로케일>/detail.jpg` (1080×1920) |

**왜 Major Update 인가**: 1.0.9 는 핵심 동작(타기·갈아타기·내리기)을 VoiceOver·음성 제어로 열고, 대비 증가·동작 줄이기·투명도 줄이기·색 없이 구별 네 가지 시스템 설정을 앱 전체에 반영하고, 첫 사용 안내·앱 안 의견을 새로 넣은 업데이트다 (`6cc2d08`). 단순 UI 손질이 아니다.
**위험**: 심사관이 "접근성 개선은 작은 변경"으로 볼 수 있다. 거절되면 이름을 바꾸지 말고 긴 설명에 첫 사용 안내를 더 드러내 다시 낸다.

**근거**: `SubwayNavigatorView.swift` `.accessibilityAction` (탑승·환승·하차), `accessibilityReduceMotion` · `accessibilityDifferentiateWithoutColor` · `colorSchemeContrast`, `KORAOnboardingView.swift`, `RELEASE_NOTES.md` 1.0.9.
**쓰지 않은 말**: "화면 전체를 VoiceOver 로" — 로드맵 `a11y.voiceover` 가 아직 계획이다. 그래서 문구는 "타고·갈아타고·내리기"에만 VoiceOver 를 붙였다.

### 언어별 문구 (23개)

#### ja

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | アクセシビリティ対応アップデート | 16 / 30 |
| 짧은 설명 | VoiceOverで乗車・乗り換え・降車まで | 22 / 50 |
| 긴 설명 | 乗車・乗り換え・降車のスライド操作がVoiceOverと音声コントロールに対応。「コントラストを上げる」「視差効果を減らす」の設定にも対応し、使い方ガイドも追加しました。 | 85 / 120 |

#### ko

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | 접근성 업데이트 | 8 / 30 |
| 짧은 설명 | VoiceOver로 타고, 갈아타고, 내려요 | 24 / 50 |
| 긴 설명 | 밀어서 타기·갈아타기·내리기를 VoiceOver와 음성 제어로도 할 수 있어요. 대비 증가·동작 줄이기 설정에 맞춰 보이고, 처음 쓰는 분을 위한 안내도 생겼어요. | 91 / 120 |

#### en-US

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | The Accessibility Update | 24 / 30 |
| 짧은 설명 | Board, transfer and get off with VoiceOver | 42 / 50 |
| 긴 설명 | Slide to board, transfer and get off now works with VoiceOver and Voice Control. Plus higher contrast and calmer motion. | 120 / 120 |

#### zh-Hans

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | 无障碍更新 | 5 / 30 |
| 짧은 설명 | 用旁白完成上车、换乘和下车 | 13 / 50 |
| 긴 설명 | 滑动上车、换乘、下车现可通过旁白和语音控制完成。还支持增强对比度和减弱动态效果，并新增首次使用指南。 | 50 / 120 |

#### zh-Hant

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | 無障礙更新 | 5 / 30 |
| 짧은 설명 | 用 VoiceOver 完成上車、轉乘和下車 | 22 / 50 |
| 긴 설명 | 滑動上車、轉乘、下車現在可用 VoiceOver 和語音控制完成，也支援增加對比與減少動態效果，並新增首次使用說明。 | 58 / 120 |

#### de

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Das Barrierefreiheits-Update | 28 / 30 |
| 짧은 설명 | Mit VoiceOver ein-, um- und aussteigen | 38 / 50 |
| 긴 설명 | Ein-, Um- und Aussteigen klappen jetzt mit VoiceOver und Sprachsteuerung. Dazu mehr Kontrast und weniger Bewegung. | 114 / 120 |

#### es

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Actualización de accesibilidad | 30 / 30 |
| 짧은 설명 | Sube, transborda y baja con VoiceOver | 37 / 50 |
| 긴 설명 | Ya puedes subir, transbordar y bajar con VoiceOver y Control por voz. Además, más contraste y menos movimiento. | 111 / 120 |

#### fr

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Mise à jour accessibilité | 25 / 30 |
| 짧은 설명 | Montez, changez, descendez avec VoiceOver | 41 / 50 |
| 긴 설명 | Montez, changez et descendez avec VoiceOver et Contrôle vocal. Et aussi plus de contraste et moins d’animations. | 112 / 120 |

#### it

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Aggiornamento accessibilità | 27 / 30 |
| 짧은 설명 | Sali, cambia e scendi con VoiceOver | 35 / 50 |
| 긴 설명 | Ora puoi salire, cambiare linea e scendere con VoiceOver e Controllo vocale. In più contrasto elevato e meno movimento. | 119 / 120 |

#### pt-BR

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Atualização de acessibilidade | 29 / 30 |
| 짧은 설명 | Embarque, baldeie e desça com o VoiceOver | 41 / 50 |
| 긴 설명 | Agora dá para embarcar, fazer baldeação e descer com VoiceOver e Controle por Voz. E mais contraste, menos movimento. | 117 / 120 |

#### ru

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Обновление доступности | 22 / 30 |
| 짧은 설명 | Посадка, пересадка и выход с VoiceOver | 38 / 50 |
| 긴 설명 | Сесть, пересесть и выйти теперь можно с VoiceOver и Управлением голосом. А ещё повышенный контраст и меньше движения. | 117 / 120 |

#### cs

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Aktualizace přístupnosti | 24 / 30 |
| 짧은 설명 | Nástup, přestup i výstup s VoiceOverem | 38 / 50 |
| 긴 설명 | Nástup, přestup i výstup teď zvládnete s VoiceOverem a Ovládáním hlasem. Navíc vyšší kontrast a méně pohybu. | 108 / 120 |

#### da

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Tilgængelighedsopdatering | 25 / 30 |
| 짧은 설명 | Stig på, skift og stig af med VoiceOver | 39 / 50 |
| 긴 설명 | Nu kan du stige på, skifte og stige af med VoiceOver og Stemmestyring. Desuden mere kontrast og mindre bevægelse. | 113 / 120 |

#### el

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Ενημέρωση προσβασιμότητας | 25 / 30 |
| 짧은 설명 | Επιβίβαση, αλλαγή και αποβίβαση με VoiceOver | 44 / 50 |
| 긴 설명 | Επιβίβαση, αλλαγή γραμμής και αποβίβαση πλέον με VoiceOver και Φωνητικό έλεγχο. Και περισσότερη αντίθεση. | 105 / 120 |

#### fi

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Saavutettavuuspäivitys | 22 / 30 |
| 짧은 설명 | Nouse, vaihda ja poistu VoiceOverilla | 37 / 50 |
| 긴 설명 | Nouse kyytiin, vaihda ja jää pois VoiceOverilla tai Puheohjauksella. Lisäksi enemmän kontrastia ja vähemmän liikettä. | 117 / 120 |

#### id

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Pembaruan Aksesibilitas | 23 / 30 |
| 짧은 설명 | Naik, transit, dan turun dengan VoiceOver | 41 / 50 |
| 긴 설명 | Kini naik, transit, dan turun bisa dengan VoiceOver dan Kontrol Suara. Juga kontras lebih tinggi dan gerakan dikurangi. | 119 / 120 |

#### nb

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Tilgjengelighetsoppdatering | 27 / 30 |
| 짧은 설명 | Gå på, bytt og gå av med VoiceOver | 34 / 50 |
| 긴 설명 | Nå kan du gå på, bytte og gå av med VoiceOver og Stemmestyring. I tillegg mer kontrast og mindre bevegelse. | 107 / 120 |

#### nl

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Toegankelijkheidsupdate | 23 / 30 |
| 짧은 설명 | In-, over- en uitstappen met VoiceOver | 38 / 50 |
| 긴 설명 | Instappen, overstappen en uitstappen werkt nu met VoiceOver en Stembediening. Plus meer contrast en minder beweging. | 116 / 120 |

#### pl

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Aktualizacja dostępności | 24 / 30 |
| 짧은 설명 | Wsiadaj, przesiadaj się i wysiadaj z VoiceOver | 46 / 50 |
| 긴 설명 | Wsiadanie, przesiadki i wysiadanie działają z VoiceOver i Sterowaniem głosowym. Do tego wyższy kontrast i mniej ruchu. | 118 / 120 |

#### sv

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Tillgänglighetsuppdatering | 26 / 30 |
| 짧은 설명 | Stig på, byt och stig av med VoiceOver | 38 / 50 |
| 긴 설명 | Nu kan du stiga på, byta och stiga av med VoiceOver och Röststyrning. Dessutom ökad kontrast och mindre rörelse. | 112 / 120 |

#### th

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | อัปเดตการช่วยการเข้าถึง | 23 / 30 |
| 짧은 설명 | ขึ้นรถ เปลี่ยนสาย และลงรถด้วย VoiceOver | 39 / 50 |
| 긴 설명 | ปัดเพื่อขึ้นรถ เปลี่ยนสาย และลงรถได้ด้วย VoiceOver และการควบคุมด้วยเสียง พร้อมรองรับเพิ่มความต่างสีและลดการเคลื่อนไหว | 117 / 120 |

#### tr

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Erişilebilirlik Güncellemesi | 28 / 30 |
| 짧은 설명 | VoiceOver ile bin, aktarma yap, in | 34 / 50 |
| 긴 설명 | Binme, aktarma ve inme artık VoiceOver ve Sesle Denetim ile yapılabiliyor. Ayrıca daha yüksek kontrast, daha az hareket. | 120 / 120 |

#### vi

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Bản cập nhật trợ năng | 21 / 30 |
| 짧은 설명 | Lên tàu, đổi tuyến, xuống tàu bằng VoiceOver | 44 / 50 |
| 긴 설명 | Giờ bạn có thể lên tàu, đổi tuyến và xuống tàu bằng VoiceOver và Khẩu lệnh. Kèm tăng độ tương phản, giảm chuyển động. | 117 / 120 |

---

## E2. Line 9 Express Check (다음 버전)

| 항목 | 값 |
|---|---|
| 참조 이름 (내부) | `2026-12 Line 9 Express Check` |
| 배지 | Major Update |
| 이벤트 시작 | 2026-12-18 00:00 (Asia/Seoul) |
| 이벤트 종료 | 2027-01-16 23:59 (Asia/Seoul) |
| 미리 노출 시작 | 2026-12-04 (시작 14일 전) |
| 우선순위 | 높음 |
| 목적 | 모든 사용자 (Appropriate for all users) |
| 국가·지역 | 앱 판매 국가 전체 (피처링 N2 의 중점 지역: 일본·대만·홍콩·미국·동남아) |
| 딥링크 | 비움 (앱 첫 화면 → 경로 고르기 → 카메라로 방향 확인) |
| 카드·상세 그림 | **아직 없음** — 아래 "필요한 것" |

**선행 조건**: 로드맵 `express` 가 `.building` 이다. 커밋 `2e236ce`·`68e0c56` 으로 판정은 들어갔지만 아직 배포되지 않았다. 12-10 까지 배포하지 못하면 이 이벤트는 만들지 않는다 (없는 기능을 이벤트로 내면 거절되고 신뢰도 잃는다). 배포하면 `KORARoadmap.swift` 의 `express` 를 `.shipped("<버전>")` 로 옮긴다.

**왜 Major Update 인가**: 카메라 방향 확인이 처음으로 열차 종류(급행/일반)를 읽는다. 9호선 38개 역 중 급행은 16곳에만 서므로, 잘못 타면 실제로 내릴 역을 지나친다.

**근거**: `SubwayLineData.swift` `line9Express` (김포공항~중앙보훈병원 16개 역, 표기 "급행"), navloc `scanSkipsStop`, 로드맵 `roadmapExpressDetail` ("9호선부터 시작").

**필요한 것 (그림)**: 레포 스크린샷(`docs/screenshots/raw/`)에는 급행 판정 화면이 없다. 그래서 E2 그림은 만들지 않았다. 다음 중 하나를 준비한다.
1. 실기기로 9호선 승강장(예: 김포공항·여의도·고속터미널)에서 급행 전광판을 비춰 "○○에 서지 않는 열차예요" 판정이 뜬 화면을 찍는다 (언어별로는 앱 언어만 바꿔 다시 찍기).
2. 또는 `scripts/capture_raw_screenshots.py` 에 급행 판정 장면(ScreenshotScene)을 더해 시뮬레이터로 23개 언어를 찍는다.
찍은 뒤 `python3 marketing/global/events/make_event_images.py <찍은 폴더> marketing/global/events/line9-express <화면 이름>` 으로 카드·상세 그림을 만든다 (폴더 구조는 `docs/screenshots/raw/<로케일>/<화면>.png` 와 같게).

### 언어별 문구 (23개)

#### ja

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | 9号線 急行チェック | 10 / 30 |
| 짧은 설명 | 急行が降りる駅に止まるか、すぐわかる | 18 / 50 |
| 긴 설명 | 9号線のホームで発車案内板にカメラを向けると、次の電車が降りる駅を通過する急行かどうかを教えます。通過なら各駅停車へ。 | 59 / 120 |

#### ko

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | 9호선 급행 확인 | 9 / 30 |
| 짧은 설명 | 급행이 내 역에 서는지 바로 알려 드려요 | 22 / 50 |
| 긴 설명 | 9호선 승강장 전광판을 카메라로 비추면 다음 열차가 내 역에 서지 않는 급행인지 알려 드려요. 그럴 땐 일반열차를 타세요. | 68 / 120 |

#### en-US

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Line 9 Express Check | 20 / 30 |
| 짧은 설명 | Find out if the express skips your stop | 39 / 50 |
| 긴 설명 | On Line 9, aim your camera at the platform board. KORA tells you if the next train is an express that skips your stop. | 118 / 120 |

#### zh-Hans

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | 9号线快车识别 | 7 / 30 |
| 짧은 설명 | 快车停不停你的站，一看便知 | 13 / 50 |
| 긴 설명 | 在9号线站台用相机对准列车信息屏，就能知道下一班是否为不停靠你目的站的快车。如果是，请改乘普通列车。 | 50 / 120 |

#### zh-Hant

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | 9號線快車辨識 | 7 / 30 |
| 짧은 설명 | 快車停不停你的站，一看就知道 | 14 / 50 |
| 긴 설명 | 在9號線月台用相機對準列車資訊看板，就能知道下一班是不是不停你目的站的快車。若是，改搭普通車即可。 | 49 / 120 |

#### de

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Expresszug-Check Linie 9 | 24 / 30 |
| 짧은 설명 | Sieh sofort, ob der Express bei dir hält | 40 / 50 |
| 긴 설명 | Richte auf Linie 9 die Kamera auf die Anzeige am Bahnsteig. KORA sagt dir, ob der nächste Express deinen Halt auslässt. | 119 / 120 |

#### es

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Exprés de la línea 9 | 20 / 30 |
| 짧은 설명 | Comprueba si el exprés para en tu estación | 42 / 50 |
| 긴 설명 | En la línea 9, apunta la cámara al panel del andén y KORA te dice si el próximo exprés se salta tu parada. | 106 / 120 |

#### fr

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | L’express de la ligne 9 | 23 / 30 |
| 짧은 설명 | Sachez si l’express s’arrête à votre station | 44 / 50 |
| 긴 설명 | Sur la ligne 9, visez l’écran du quai : KORA vous dit si le prochain express ne s’arrête pas à votre station. | 109 / 120 |

#### it

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Espressi sulla linea 9 | 22 / 30 |
| 짧은 설명 | Scopri se l’espresso salta la tua fermata | 41 / 50 |
| 긴 설명 | Sulla linea 9 inquadra il tabellone in banchina: KORA ti dice se il prossimo espresso salta la tua fermata. | 107 / 120 |

#### pt-BR

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Expresso da Linha 9 | 19 / 30 |
| 짧은 설명 | Saiba se o expresso para na sua estação | 39 / 50 |
| 긴 설명 | Na Linha 9, aponte a câmera para o painel da plataforma e o KORA avisa se o próximo expresso pula sua estação. | 110 / 120 |

#### ru

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Экспрессы на линии 9 | 20 / 30 |
| 짧은 설명 | Узнайте, остановится ли экспресс на вашей станции | 49 / 50 |
| 긴 설명 | На линии 9 наведите камеру на табло на платформе, и KORA подскажет, не проедет ли следующий экспресс вашу станцию. | 114 / 120 |

#### cs

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Rozpoznání expresů na lince 9 | 29 / 30 |
| 짧은 설명 | Zjistěte, jestli expres staví ve vaší stanici | 45 / 50 |
| 긴 설명 | Na lince 9 namiřte fotoaparát na tabuli na nástupišti a KORA vám řekne, jestli další expres vaši stanici přejede. | 113 / 120 |

#### da

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Ekspresstog på linje 9 | 22 / 30 |
| 짧은 설명 | Se, om ekspressen standser ved din station | 42 / 50 |
| 긴 설명 | Ret kameraet mod tavlen på perronen på linje 9, så fortæller KORA, om næste eksprestog springer din station over. | 113 / 120 |

#### el

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Ταχείς συρμοί στη γραμμή 9 | 26 / 30 |
| 짧은 설명 | Μάθετε αν ο ταχύς σταματά στη στάση σας | 39 / 50 |
| 긴 설명 | Στη γραμμή 9 στρέψτε την κάμερα στην πινακίδα της αποβάθρας και το KORA σας λέει αν ο επόμενος ταχύς δεν σταματά. | 113 / 120 |

#### fi

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Linjan 9 pikajunat | 18 / 30 |
| 짧은 설명 | Näe heti, pysähtyykö pikajuna asemallasi | 40 / 50 |
| 긴 설명 | Osoita linjalla 9 kameralla laiturin näyttötauluun, niin KORA kertoo, ohittaako seuraava pikajuna asemasi. | 106 / 120 |

#### id

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Cek Kereta Ekspres Jalur 9 | 26 / 30 |
| 짧은 설명 | Cek apakah kereta ekspres berhenti di stasiunmu | 47 / 50 |
| 긴 설명 | Di Jalur 9, arahkan kamera ke papan peron. KORA memberi tahu jika kereta berikutnya ekspres yang melewati stasiunmu. | 116 / 120 |

#### nb

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Ekspresstog på linje 9 | 22 / 30 |
| 짧은 설명 | Se om ekspressen stopper på stasjonen din | 41 / 50 |
| 긴 설명 | Rett kameraet mot tavlen på perrongen på linje 9, så sier KORA fra om neste tog er et ekspresstog som hopper over deg. | 118 / 120 |

#### nl

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Sneltreincheck lijn 9 | 21 / 30 |
| 짧은 설명 | Zie meteen of de sneltrein bij jou stopt | 40 / 50 |
| 긴 설명 | Richt op lijn 9 je camera op het bord op het perron. KORA zegt of de volgende sneltrein jouw station overslaat. | 111 / 120 |

#### pl

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Ekspresy na linii 9 | 19 / 30 |
| 짧은 설명 | Sprawdź, czy ekspres zatrzyma się na twojej stacji | 50 / 50 |
| 긴 설명 | Na linii 9 skieruj aparat na tablicę na peronie, a KORA powie, czy następny ekspres pominie twoją stację. | 105 / 120 |

#### sv

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Expresståg på linje 9 | 21 / 30 |
| 짧은 설명 | Se om expressen stannar vid din station | 39 / 50 |
| 긴 설명 | Rikta kameran mot skylten på perrongen på linje 9, så säger KORA om nästa expresståg hoppar över din station. | 109 / 120 |

#### th

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | เช็กขบวนด่วนสาย 9 | 17 / 30 |
| 짧은 설명 | รู้ทันทีว่าขบวนด่วนจอดสถานีของคุณไหม | 36 / 50 |
| 긴 설명 | บนชานชาลาสาย 9 ส่องกล้องไปที่ป้ายบอกขบวน แล้ว KORA จะบอกว่าขบวนถัดไปเป็นขบวนด่วนที่ไม่จอดสถานีของคุณหรือไม่ | 107 / 120 |

#### tr

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | 9. Hatta Ekspres Kontrolü | 25 / 30 |
| 짧은 설명 | Ekspresin durağında durup durmadığını gör | 41 / 50 |
| 긴 설명 | 9. hatta kamerayı perondaki tabelaya tut. KORA, sıradaki trenin durağını atlayan bir ekspres olup olmadığını söyler. | 116 / 120 |

#### vi

| 칸 | 글 | 글자 수 / 한도 |
|---|---|---|
| 이벤트 이름 | Nhận biết tàu nhanh tuyến 9 | 27 / 30 |
| 짧은 설명 | Biết ngay tàu nhanh có dừng ở ga bạn không | 42 / 50 |
| 긴 설명 | Ở tuyến số 9, hướng camera vào bảng điện tử trên sân ga. KORA cho biết chuyến tàu nhanh kế tiếp có bỏ qua ga bạn không. | 119 / 120 |
