#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Parse agent research files (L|/R|/S| format), apply rename map,
emit Swift dict entries for SubwayStationDataExpansion.swift, and
validate (duplicate keys, missing coords, translation markers)."""
import re, glob, sys, math, unicodedata

REPO = "."
SCRATCH = "scripts/station-data"

# (line-name-substring, station) -> canonical renamed key
# region tag suffixes for ja/en of renamed stations
REGION_TAG = {
    "대구": ("テグ", "Daegu", "大邱"),
    "대전": ("テジョン", "Daejeon", "大田"),
    "부산": ("プサン", "Busan", "釜山"),
    "광주": ("クァンジュ", "Gwangju", "光州"),
    "동해선": ("トンヘソン", "Donghae Line", "东海线"),
}

RENAMES = {
    ("대구 1호선", "대곡"): "대곡(대구)",
    ("대구 1호선", "교대"): "교대(대구)",
    ("대구 1호선", "신천"): "신천(대구)",
    ("대구 1호선", "중앙로"): "중앙로(대구)",
    ("대구 2호선", "용산"): "용산(대구)",
    ("대구 2호선", "죽전"): "죽전(대구)",
    ("대구 3호선", "동천"): "동천(대구)",
    ("대구 3호선", "구암"): "구암(대구)",
    ("대구 3호선", "남산"): "남산(대구)",
    ("대전 1호선", "신흥"): "신흥(대전)",
    ("대전 1호선", "중앙로"): "중앙로(대전)",
    ("대전 1호선", "용문"): "용문(대전)",
    ("대전 1호선", "시청"): "시청(대전)",
    ("대전 1호선", "구암"): "구암(대전)",
    ("대전 1호선", "월드컵경기장"): "월드컵경기장(대전)",
    ("광주 1호선", "화정"): "화정(광주)",
    ("광주 1호선", "공항"): "공항(광주)",
    ("부산 3호선", "종합운동장"): "종합운동장(부산)",
    ("부산 4호선", "고촌"): "고촌(부산)",
    ("부산김해경전철", "공항"): "공항(부산)",
    ("동해선", "교대"): "교대(부산)",
    ("동해선", "부전"): "부전(동해선)",
    ("동해선", "동래"): "동래(동해선)",
    ("동해선", "송정"): "송정(부산)",
    ("동해선", "좌천"): "좌천(동해선)",
    # 부산 1호선 (agent A4)
    ("부산 1호선", "시청"): "시청(부산)",
    ("부산 1호선", "중앙"): "중앙(부산)",
    ("부산 1호선", "남산"): "남산(부산)",
    ("부산 1호선", "양정"): "양정(부산)",
    ("부산 1호선", "교대"): "교대(부산)",
    # 부산 2호선 (agent A4)
    ("부산 2호선", "금곡"): "금곡(부산)",
    ("부산 2호선", "중동"): "중동(부산)",
    ("부산 2호선", "증산"): "증산(부산)",   # 서울 6호선 증산과 충돌
    ("부산 2호선", "동백"): "동백(부산)",   # 용인 에버라인 동백과 충돌
}

def tag_for(new):
    m = re.search(r"\((.+)\)$", new)
    return REGION_TAG.get(m.group(1)) if m else None

def parse(path):
    line_name = None
    out = []  # (line, kr, lat, lng, ja, en, zh, flag)
    for raw in open(path, encoding="utf-8"):
        raw = raw.strip()
        if raw.startswith("L|"):
            line_name = raw.split("|")[1]
        elif raw.startswith("S|"):
            p = raw.split("|")
            if len(p) < 9:
                print(f"!! malformed S row in {path}: {raw}", file=sys.stderr); continue
            _, idx, kr, lat, lng, ja, en, zh, flag = p[:9]
            out.append((line_name, kr.strip(), float(lat), float(lng),
                        ja.strip(), en.strip(), zh.strip(), flag.strip()))
    return out

def core_keys():
    keys = set()
    for f, pat in [
        (f"{REPO}/KORA/Sources/Features/Subway/SubwayStationCoordinates.swift",
         re.compile(r'^\s*"([^"]+)":\s*\(')),
        (f"{REPO}/KORA/Sources/Features/Subway/SubwayStationLocale.swift",
         re.compile(r'^\s*"([^"]+)":\s*\.init')),
    ]:
        s = set()
        for ln in open(f, encoding="utf-8"):
            m = pat.match(ln)
            if m: s.add(m.group(1))
        keys |= s
    return keys

def hav(a, b):
    la1, lo1, la2, lo2 = map(math.radians, [a[0], a[1], b[0], b[1]])
    h = math.sin((la2-la1)/2)**2 + math.cos(la1)*math.cos(la2)*math.sin((lo2-lo1)/2)**2
    return 2 * 6371000 * math.asin(math.sqrt(h))

MARKERS = ["Mountain","Hospital","Park","Hall","Office","Bridge","Market","Center",
           "Tomb","Forest","River","Lake","Stadium","College","Entrance","Tunnel",
           "Beach","Island","Gate","Garden","Library","Museum","School","Wall",
           "Tower","Fortress","Square","Resort"]

def width(s):
    return sum(2 if unicodedata.east_asian_width(c) in "WF" else 1 for c in s)

def pad(s, w):
    return s + " " * max(1, w - width(s))

rows = []
for path in sorted(glob.glob(f"{SCRATCH}/agent_*.txt")):
    rows += parse(path)

core = core_keys()
coords, locales, srcline = {}, {}, {}
warnings, marker_hits, core_overlaps = [], [], []

for line, kr, lat, lng, ja, en, zh, flag in rows:
    key = RENAMES.get((line, kr), kr)
    tag = tag_for(key) if key != kr else None
    if tag:
        ja = f"{ja}({tag[0]})"
        # avoid "Busan Nat'l Univ. of Education (Busan)"-style duplication
        if tag[1].split()[0].lower() not in en.lower():
            en = f"{en} ({tag[1]})"
        if zh not in ("-", ""): zh = f"{zh}({tag[2]})"
    if key in core:
        core_overlaps.append((key, line))
        continue  # already in core tables — must be the SAME physical station
    if key in coords:
        d = hav(coords[key], (lat, lng))
        if d > 400:
            warnings.append(f"CONFLICT {key}: {srcline[key]} vs {line} — {d:.0f} m apart")
        continue
    coords[key] = (lat, lng)
    srcline[key] = line
    locales[key] = (ja, en, zh)
    for m in MARKERS:
        if m in en:
            marker_hits.append((key, en, m))
            break

with open(f"{SCRATCH}/generated_coords.swift", "w", encoding="utf-8") as f:
    for k in sorted(coords):
        lat, lng = coords[k]
        f.write(f'        {pad(chr(34)+k+chr(34)+":", 22)}({lat:.5f}, {lng:.5f}),\n')

with open(f"{SCRATCH}/generated_locale.swift", "w", encoding="utf-8") as f:
    for k in sorted(locales):
        ja, en, zh = locales[k]
        zh_part = "" if zh in ("-", "") else f', zh: "{zh}"'
        f.write(f'        {pad(chr(34)+k+chr(34)+":", 22)}.init(ja: "{ja}", en: "{en}"{zh_part}),\n')

print(f"stations parsed: {len(rows)}, new keys: {len(coords)}")
print("\n-- coordinate conflicts (>400m):")
for w in warnings: print("  " + w)
print("\n-- English names with translation markers (need exception entries):")
for k, en, m in sorted(marker_hits): print(f'  "{k}",   // {en}  [{m}]')
print("\n-- station names already in core tables (verify SAME physical station / intended transfer):")
for k, line in sorted(set(core_overlaps)): print(f"  {k}  <- {line}")
