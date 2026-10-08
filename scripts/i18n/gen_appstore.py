#!/usr/bin/env python3
"""APPSTORE.md · RELEASE_NOTES.md(최신 버전 절) 생성기.

원본: scripts/i18n/store/<로케일>.json
  name · subtitle · keywords · promo · description · release_notes[] · shots[] · creative{}
  python3 scripts/i18n/gen_appstore.py <버전>
"""
import json, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "scripts/i18n/store"
# deploy.env LOCALES 순서 → 웹 페이지 폴더
LOCALES = ["ko", "en-US", "ja", "zh-Hans", "zh-Hant", "de", "es", "fr", "it", "pt-BR", "ru", "cs",
           "da", "el", "fi", "id", "nb", "nl", "pl", "sv", "th", "tr", "vi"]
WEB = {"en-US": "en"}
LANGNAME = {"ko": "한국어", "en-US": "English", "ja": "日本語", "zh-Hans": "중국어 간체", "zh-Hant": "중국어 번체",
            "de": "독일어", "es": "스페인어", "fr": "프랑스어", "it": "이탈리아어", "pt-BR": "포르투갈어 브라질",
            "ru": "러시아어", "cs": "체코어", "da": "덴마크어", "el": "그리스어", "fi": "핀란드어",
            "id": "인도네시아어", "nb": "노르웨이어 보크말", "nl": "네덜란드어", "pl": "폴란드어", "sv": "스웨덴어",
            "th": "태국어", "tr": "튀르키예어", "vi": "베트남어"}


def load(loc):
    return json.loads((SRC / f"{loc}.json").read_text(encoding="utf-8"))


def appstore():
    out = ["# 한국길찾기 App Store 문구", "",
           "원본은 scripts/i18n/store/<로케일>.json — 고친 뒤 python3 scripts/i18n/gen_appstore.py <버전> 으로 다시 만든다.", ""]
    for loc in LOCALES:
        d = load(loc)
        web = WEB.get(loc, loc)
        out += [f"## {loc}", "",
                "### 이름", "", d["name"], "",
                "### 부제", "", d["subtitle"], "",
                "### 키워드", "", d["keywords"], "",
                "### 프로모션 텍스트", "", d["promo"], "",
                "### 설명", "", d["description"], "",
                "### 지원 URL", "", f"https://m1zz.github.io/KORA/{web}/support.html", "",
                "### 개인정보처리방침 URL", "", f"https://m1zz.github.io/KORA/{web}/privacy.html", "",
                "### 마케팅 URL", "", f"https://m1zz.github.io/KORA/{web}/", ""]
    (ROOT / "APPSTORE.md").write_text("\n".join(out), encoding="utf-8")


def release_notes(version):
    path = ROOT / "RELEASE_NOTES.md"
    text = path.read_text(encoding="utf-8")
    head, sep, rest = text.partition("\n## ")
    rest = sep + rest if sep else ""
    # 같은 버전 절이 이미 있으면 바꾼다
    if rest.startswith(f"\n## {version}\n"):
        nxt = rest.find("\n## ", 4)
        rest = rest[nxt:] if nxt != -1 else ""
    sec = [f"## {version}", ""]
    for loc in LOCALES:
        d = load(loc)
        sec += [f"### 앱스토어 ({LANGNAME[loc]} {loc})", "", "```", *d["release_notes"], "```", ""]
    body = head.rstrip("\n") + "\n\n" + "\n".join(sec)
    if rest:
        body += "\n" + rest.lstrip("\n")
    path.write_text(body, encoding="utf-8")


if __name__ == "__main__":
    appstore()
    if len(sys.argv) > 1:
        release_notes(sys.argv[1])
    print("ok")
