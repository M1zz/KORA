#!/usr/bin/env python3
"""역 이름 번체 표(SubwayStationChineseTraditionalNames.swift)를 간체 표에서 다시 만든다.

간체의 출처는 두 곳이고 앱과 같은 우선순위로 합친다.
  1) SubwayStationChineseNames.swift 의 stationChineseNames (서울시 공식 중문 노선도)
  2) SubwayStationLocale.swift · SubwayStationDataExpansion.swift 의 `.init(..., zh: "…")`
역 이름은 고유명사라 글자만 바꾼다(zh_hant.names).

쓰는 법:
    python3 scripts/i18n/gen_station_zh_hant.py          # 다시 만든다
    python3 scripts/i18n/gen_station_zh_hant.py --check  # 다시 만든 것과 다르면 실패 (predeploy)
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SUBWAY = os.path.join(ROOT, "KORA", "Sources", "Features", "Subway")
OUT = os.path.join(SUBWAY, "SubwayStationChineseTraditionalNames.swift")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import zh_hant  # noqa: E402


def read(name):
    return open(os.path.join(SUBWAY, name), encoding="utf-8").read()


def collect():
    hans = {}
    for ko, zh in re.findall(r'"([^"]+)":\s*"([^"]+)"', read("SubwayStationChineseNames.swift")):
        hans.setdefault(ko, zh)
    for f in ("SubwayStationLocale.swift", "SubwayStationDataExpansion.swift"):
        for ko, zh in re.findall(r'"([^"]+)":\s*\.init\([^)]*zh:\s*"([^"]+)"\)', read(f)):
            hans.setdefault(ko, zh)
    return hans


def render(hans):
    keys = sorted(hans)
    hant = zh_hant.names([hans[k] for k in keys])
    rows = "\n".join(f'        "{k}": "{v}",' for k, v in zip(keys, hant))
    return f"""import Foundation

// MARK: - Chinese station names (traditional)
//
// ⚠️ 생성 파일 — 손으로 고치지 말 것. 간체 표를 고친 뒤
//    `python3 scripts/i18n/gen_station_zh_hant.py` 로 다시 만든다.
//    간체(stationChineseNames + StationLocale.zh)를 ICU Hans-Hant 로 글자만 바꾼 것이다.

extension MetroLineData {{

    static let stationChineseTraditionalNames: [String: String] = [
{rows}
    ]
}}
"""


def main():
    text = render(collect())
    if "--check" in sys.argv:
        current = open(OUT, encoding="utf-8").read() if os.path.exists(OUT) else ""
        if current != text:
            print("❌ 역 이름 번체 표가 간체 표와 어긋남 — gen_station_zh_hant.py 를 돌릴 것")
            return 1
        print("✅ 역 이름 번체 표 최신")
        return 0
    open(OUT, "w", encoding="utf-8").write(text)
    print(f"역 이름 번체 {text.count(chr(10) + '        ' + chr(34))}건 생성 → {os.path.relpath(OUT, ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
