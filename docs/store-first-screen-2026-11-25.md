## 스토어 첫 화면 — 노출 대비 다운로드 1% 미만 (2026-11-25)

(todo.md 에 다른 세션의 미커밋 변경이 있어 이 파일에 따로 적는다. 정리할 때 todo.md 맨 위로 옮길 것.)

진단: 검색 목록에서 보이는 첫 스크린샷이 "Every transfer at a glance"(어느 지하철 앱이나 하는 말)라서 서울 · 길 잃지 않음이라는 결과가 안 보이고, 영어 부제 "Seoul Metro Guide for Visitors" 도 무엇이 다른지 말하지 않는다. 비교 상대는 평가 수만 개의 Subway Korea · 네이버지도인데 이 앱은 평가가 0~1개다(2026-11-25 iTunes 조회). 한국 스토어 노출은 대부분 한국인 검색일 텐데, 이 앱은 여행자용이라 애초에 받을 이유가 적다(추측, 지역별 노출 숫자는 확인 못 함).

- [x] en-US · en-GB 부제: Seoul Metro Guide for Visitors → Seoul metro, never miss a stop (30자)
- [x] en-US · en-GB 프로모션 텍스트: 서울 · 부산에서 길 잃지 않는다는 결과를 맨 앞에 (157자)
- [x] 스크린샷 1장 캡션: en "Every transfer at a glance" → "Get around Seoul without getting lost", ko "환승까지 한눈에" → "서울 지하철, 헤매지 않게" (`scripts/i18n/store/*.json` shots[0], ko · en-US · en-GB 다시 그림)
- [x] ko 부제 · 프로모션 · 설명 첫 줄은 이미 결과(타는 방향 · 하차 진동)를 말하고 있어 그대로 둠. 키워드는 11월 검색 처방 그대로(부제와 겹치는 말 없음)
- [x] 길이 검사: 부제 30 · 키워드 100 · 프로모션 170 글자 — 모든 언어 통과
- [ ] App Store Connect 에 en-US · en-GB 부제 · 프로모션 텍스트 반영(프로모션은 심사 없이 바로 바뀐다), 스크린샷 1장(ko · en-US · en-GB) 바꿔 올리기
- [ ] 다른 23개 언어의 스크린샷 1장 캡션도 같은 뜻("서울에서 헤매지 않게")으로 바꿀지 검토 — 지금은 "환승 한눈에" 뜻 그대로
- [ ] 이름 제안 검토: "Korea Navi: Subway Routes" → "Korea Navi: Seoul Subway" (이름은 검색 가중치가 가장 크고, 사람들이 치는 말은 "seoul subway"다 — 추측, 순위 자료로 확인 필요)
- [ ] 아이콘 제안 검토: 흰 열차 그림은 다른 지하철 앱과 구분이 안 된다. 한국(한글 역 이름 표지 · 서울 노선 색)을 드러내는 요소를 넣을지
- [ ] 2주 뒤 허브에서 노출 → 페이지 조회 · 조회 → 받기를 다시 보고, 국가별로 어디서 노출이 나오는지 확인
