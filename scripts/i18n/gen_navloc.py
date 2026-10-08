#!/usr/bin/env python3
"""화면 문구 카탈로그(NavLoc) 생성기.

원본: scripts/i18n/navloc.json  — { 키: { 로케일: 문구 } }, 23개 언어 전부.
출력: KORA/Sources/Features/Subway/SubwayNavigatorCatalog.swift (손으로 고치지 않는다)

  python3 scripts/i18n/gen_navloc.py

자리표시자는 {0} {1} … — NavLoc.fill(lang, …) 이 채운다.
빈칸이 있으면 생성하지 않고 멈춘다(컴파일러가 막던 것과 같은 보장).
"""
import json, pathlib, sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "scripts/i18n/navloc.json"
OUT = ROOT / "KORA/Sources/Features/Subway/SubwayNavigatorCatalog.swift"

# JSON 로케일 → NavLoc 필드 이름 (순서 = init 인자 순서)
FIELDS = [
    ("ko", "ko"), ("ja", "ja"), ("en", "en"), ("zh-Hans", "zh"), ("zh-Hant", "zhHant"),
    ("de", "de"), ("es", "es"), ("fr", "fr"), ("it", "it"), ("pt-BR", "ptBR"),
    ("ru", "ru"), ("cs", "cs"), ("da", "da"), ("el", "el"), ("fi", "fi"),
    ("id", "id"), ("nb", "nb"), ("nl", "nl"), ("pl", "pl"), ("sv", "sv"),
    ("th", "th"), ("tr", "tr"), ("vi", "vi"),
]


def swift_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def main():
    data = json.loads(SRC.read_text(encoding="utf-8"))
    missing = [f"{k}.{loc}" for k, v in data.items() for loc, _ in FIELDS if not v.get(loc)]
    if missing:
        sys.exit("빈 문구: " + ", ".join(missing))
    out = ["// 자동 생성 — scripts/i18n/gen_navloc.py 가 scripts/i18n/navloc.json 에서 만든다. 직접 고치지 말 것.",
           "", "extension NavLoc {"]
    for key, v in data.items():
        args = ",\n".join(f"        {f}: {swift_str(v[loc])}" for loc, f in FIELDS)
        out.append(f"    static let {key} = NavLoc(\n{args}\n    )")
    out.append("}")
    OUT.write_text("\n".join(out) + "\n", encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)} ({len(data)} keys)")


if __name__ == "__main__":
    main()
