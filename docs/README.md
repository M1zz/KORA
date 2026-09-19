# KORA Pages

KORA(한국 길찾기)의 소개·지원·개인정보 처리방침 사이트. GitHub Pages 로 `main` 브랜치의 `/docs` 를 그대로 싣는다.

## 언어별 주소

App Store Connect 의 언어별 칸(마케팅 URL, 지원 URL, 개인정보 처리방침 URL)에는 아래 주소를 넣는다.

| 언어 | 소개 (마케팅 URL) | 지원 URL | 개인정보 처리방침 URL |
|---|---|---|---|
| 한국어 | https://m1zz.github.io/KORA/ko/ | https://m1zz.github.io/KORA/ko/support.html | https://m1zz.github.io/KORA/ko/privacy.html |
| English | https://m1zz.github.io/KORA/en/ | https://m1zz.github.io/KORA/en/support.html | https://m1zz.github.io/KORA/en/privacy.html |
| 日本語 | https://m1zz.github.io/KORA/ja/ | https://m1zz.github.io/KORA/ja/support.html | https://m1zz.github.io/KORA/ja/privacy.html |
| 简体中文 | https://m1zz.github.io/KORA/zh-Hans/ | https://m1zz.github.io/KORA/zh-Hans/support.html | https://m1zz.github.io/KORA/zh-Hans/privacy.html |
| 繁體中文 | https://m1zz.github.io/KORA/zh-Hant/ | https://m1zz.github.io/KORA/zh-Hant/support.html | https://m1zz.github.io/KORA/zh-Hant/privacy.html |

예전 주소 `https://m1zz.github.io/KORA/`, `/support.html`, `/privacy.html` 는 이미 스토어에 등록돼 있을 수 있어 남겨 두었다.
브라우저 언어(zh-TW·zh-HK·zh-MO·zh-Hant 는 번체, 그 밖의 zh 는 간체)를 보고 위 페이지로 넘겨 주고, 스크립트가 꺼져 있으면 다섯 언어 링크를 보여 준다.

## 파일

- `<언어>/index.html` · `support.html` · `privacy.html` — 언어마다 한 벌. 서로 hreflang 으로 이어져 있다.
- `index.html` · `support.html` · `privacy.html` — 언어 고르기용 이동 페이지
- `style.css` — 공통 스타일 (다크 모드 포함), `icon.png` — 앱 아이콘 (1024×1024)
- `appstore/` — App Store Connect 에 붙여 넣을 언어별 메타데이터(이름·부제·설명·키워드·프로모션 텍스트)와 공통 답변(`appstore/README.md`: 카테고리, 연령 등급, 앱 개인정보 보호, 수출 규정, 심사 메모, 스크린샷 체크리스트)
- `release-notes/<버전>.md` — 릴리즈 노트 보관본. 스토어에 실제로 올라가는 글은 저장소 최상단 `RELEASE_NOTES.md` 이며 두 곳의 문구는 같아야 한다.

## 고칠 때

- 한 언어를 고치면 다섯 언어를 모두 고친다. 개인정보 처리방침은 한국어판이 우선한다.
- 앱이 새로 데이터를 보내게 되면(예: Crashlytics 추가) 처리방침 다섯 벌, `appstore/README.md` 의 앱 개인정보 보호 표, `KORA/PrivacyInfo.xcprivacy` 를 같이 고친다.

## GitHub Pages 활성화

GitHub 리포 → **Settings → Pages**: Source `Deploy from a branch`, Branch `main` / `/docs`. 푸시 후 1~2분 뒤 반영된다.
