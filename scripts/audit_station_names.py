#!/usr/bin/env python3
"""
Offline audit of station English names in SubwayStationLocale.swift.

A station's English name MUST be a romanization (e.g. 소요산 → "Soyosan"),
never a translation (e.g. 소요산 → "Soyo Mountain"). Some stations have
officially-translated names (시청 → "City Hall") and live in an exception
list mirroring the Swift validator.

Usage:
    python3 scripts/audit_station_names.py            # exits 1 if issues
    python3 scripts/audit_station_names.py --quiet    # only print issues
"""
from __future__ import annotations
import re
import sys
import pathlib

LOCALE_FILE = pathlib.Path(__file__).resolve().parent.parent / "KORA/Sources/Features/Subway/SubwayStationLocale.swift"

# Mirror the Swift `officialTranslationExceptions` whitelist.
EXCEPTIONS = {
    "시청", "서울역", "대공원", "어린이대공원", "올림픽공원",
    "효창공원앞", "월드컵경기장", "종합운동장", "부천종합운동장",
    "삼산체육관", "디지털미디어시티", "고속터미널", "남부터미널",
    "동대문역사문화공원", "가락시장", "영등포시장", "공항시장",
    "경찰병원", "중앙보훈병원", "경마공원", "뚝섬유원지",
    "국회의사당",
    "금천구청", "영등포구청", "양천구청", "강남구청", "마포구청",
    "강동구청", "부평구청", "부천시청", "하남시청",
}

# Words that indicate translation rather than romanization.
TRANSLATION_MARKERS = [
    "Mountain", "Hospital", "Park", "Hall", "Office", "Bridge",
    "Market", "Center", "Tomb", "Forest", "River", "Lake",
    "Stadium", "College", "Entrance", "Tunnel", "Beach", "Island",
    "Gate", "Garden", "Library", "Museum", "School", "Wall",
    "Tower", "Fortress", "Square", "Resort",
]

# Match entries like:  "소요산": .init(ja: "ソヨサン", en: "Soyosan"),
ENTRY = re.compile(
    r'"(?P<ko>[가-힣\d·]+)"\s*:\s*\.init\(\s*ja:\s*"(?P<ja>[^"]+)"\s*,\s*en:\s*"(?P<en>[^"]+)"\s*\)'
)


def audit(text: str) -> list[tuple[str, str, str]]:
    issues: list[tuple[str, str, str]] = []
    for m in ENTRY.finditer(text):
        ko = m.group("ko")
        en = m.group("en")

        if not en.strip():
            issues.append((ko, en, "English is empty"))
            continue

        if ko in EXCEPTIONS:
            continue

        for marker in TRANSLATION_MARKERS:
            # Word-boundary match so e.g. "Park" doesn't match "Sparks".
            if re.search(rf"\b{re.escape(marker)}\b", en):
                issues.append((ko, en, f'translation marker "{marker}" — should be romanization'))
                break

    return issues


def main(argv: list[str]) -> int:
    quiet = "--quiet" in argv
    if not LOCALE_FILE.exists():
        print(f"locale file not found: {LOCALE_FILE}", file=sys.stderr)
        return 2

    text = LOCALE_FILE.read_text()
    issues = audit(text)

    if issues:
        print(f"❌ {len(issues)} station name issue(s):", file=sys.stderr)
        for ko, en, reason in issues:
            print(f'  - {ko} → "{en}": {reason}', file=sys.stderr)
        return 1

    if not quiet:
        total = len(ENTRY.findall(text))
        print(f"✅ All {total} station English names look like romanizations "
              f"(plus {len(EXCEPTIONS)} whitelisted official translations).")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
