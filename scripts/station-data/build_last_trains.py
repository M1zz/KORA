#!/usr/bin/env python3
"""막차 데이터 생성기 (KORA Pro 막차 알림).

원본: 서울 열린데이터광장
  SearchSTNBySubwayLineInfo       역 코드 목록 (노선별)
  SearchLastTrainTimeByIDService  역·요일·방향별 마지막 열차들 (늦은 시각부터)
키:   KORA/Config/Secrets.xcconfig 의 SEOUL_DATA_KEY (또는 같은 이름의 환경 변수).
      키는 이 스크립트만 쓴다. 앱에는 결과 JSON 만 들어간다.
출력: KORA/last_trains.json
      { "앱역이름|노선번호": { "평일/토/휴일 태그": { "방향 태그": [[행선지, 출발분], …] } } }
      출발분은 자정 기준 분이고 자정 넘김은 24시 이후로 센다 (00:46 → 1486).
      행선지마다 그 행선지로 가는 마지막 열차 하나만 남긴다.

  python3 scripts/station-data/build_last_trains.py

시간표가 바뀌면(보통 철도 시간표 개정 때) 다시 돌린다.
"""
import concurrent.futures as cf, json, os, pathlib, re, sys, time, urllib.parse, urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "KORA/last_trains.json"
CACHE = pathlib.Path(os.environ.get("KORA_LASTTRAIN_CACHE", "/tmp/kora-lasttrain-cache"))

# API 노선 이름 → 앱 노선 번호 (SubwayLineData*.swift 의 number)
LINES = {
    "01호선": 1, "02호선": 2, "03호선": 3, "04호선": 4, "05호선": 5, "06호선": 6,
    "07호선": 7, "08호선": 8, "09호선": 9, "공항철도": 10, "신분당선": 11,
    "수인분당선": 12, "경의선": 13, "GTX-A": 14, "경춘선": 15, "경강선": 16,
    "서해선": 17, "김포도시철도": 18, "신림선": 19, "우이신설경전철": 20,
    "의정부경전철": 21, "용인경전철": 22, "인천선": 23, "인천2호선": 24,
}
# API 역 이름 → 앱 역 이름 (동명이역 괄호, 앱이 옛 이름을 쓰는 역)
ALIASES = {
    (5, "양평"): "양평(서울)",
    (13, "신촌"): "신촌(경의중앙)",
    (4, "불암산"): "당고개",
    (7, "자양"): "뚝섬유원지",
}
WEEK_TAGS = ("1", "2", "3")   # 평일, 토요일, 일요일·공휴일
INOUT_TAGS = ("1", "2")       # 상행·내선, 하행·외선


def api_key():
    if os.environ.get("SEOUL_DATA_KEY"):
        return os.environ["SEOUL_DATA_KEY"].strip()
    m = re.search(r"^SEOUL_DATA_KEY\s*=\s*(\S+)", (ROOT / "KORA/Config/Secrets.xcconfig").read_text(), re.M)
    if not m:
        sys.exit("SEOUL_DATA_KEY 가 없다: KORA/Config/Secrets.xcconfig 에 넣을 것")
    return m.group(1)


def get(key, path):
    url = f"http://openapi.seoul.go.kr:8088/{key}/json/{path}/"
    for attempt in range(4):
        try:
            with urllib.request.urlopen(url, timeout=20) as r:
                return json.loads(r.read())
        except Exception:
            time.sleep(1.5 * (attempt + 1))
    raise RuntimeError(f"요청 실패: {path}")


def app_station_names():
    names = set()
    for f in (ROOT / "KORA/Sources/Features/Subway").glob("SubwayLineData*.swift"):
        names |= set(re.findall(r'"([가-힣][가-힣0-9()·]*)"', f.read_text()))
    return names


def minutes(hms):
    h, m, *_ = hms.split(":")
    return int(h) * 60 + int(m)


def fetch_station(key, code):
    """한 역의 요일·방향별 마지막 열차들. 캐시가 있으면 쓴다."""
    CACHE.mkdir(parents=True, exist_ok=True)
    cached = CACHE / f"{code}.json"
    if cached.exists():
        return json.loads(cached.read_text())
    out = {}
    for w in WEEK_TAGS:
        for d in INOUT_TAGS:
            res = get(key, f"SearchLastTrainTimeByIDService/1/60/{code}/{w}/{d}")
            out[f"{w}{d}"] = res.get("SearchLastTrainTimeByIDService", {}).get("row", [])
    cached.write_text(json.dumps(out, ensure_ascii=False))
    return out


def main():
    key = api_key()
    stations = get(key, "SearchSTNBySubwayLineInfo/1/1000")["SearchSTNBySubwayLineInfo"]["row"]
    known = app_station_names()

    targets, skipped = [], set()
    for s in stations:
        line = LINES.get(s["LINE_NUM"])
        if line is None:
            skipped.add(f"노선 {s['LINE_NUM']}")
            continue
        name = ALIASES.get((line, s["STATION_NM"]), s["STATION_NM"])
        if name not in known:
            skipped.add(f"{s['LINE_NUM']} {s['STATION_NM']}")
            continue
        targets.append((name, line, s["STATION_CD"]))

    with cf.ThreadPoolExecutor(max_workers=6) as pool:
        raw = dict(zip(targets, pool.map(lambda t: fetch_station(key, t[2]), targets)))

    table, empty_lines, unknown_dest = {}, {}, set()
    for (name, line, code), by_tag in raw.items():
        entry = {}
        for tag, rows in by_tag.items():
            latest = {}
            for r in rows:
                dest, t = r["SUBWAYENAME"].strip(), minutes(r["LEFTTIME"])
                dest = ALIASES.get((line, dest), dest)
                if dest not in known:
                    unknown_dest.add(f"{line}호선 {dest}")
                    continue
                if t < 4 * 60:          # 일부 원본은 00:30 처럼 적는다
                    t += 24 * 60
                if t > latest.get(dest, -1):
                    latest[dest] = t
            if latest:
                entry.setdefault(tag[0], {})[tag[1]] = sorted(latest.items(), key=lambda kv: -kv[1])
        if entry:
            # 환승역은 노선마다 역 코드가 따로 있으므로 키에 노선을 붙인다.
            table[f"{name}|{line}"] = entry
        else:
            empty_lines.setdefault(line, 0)
            empty_lines[line] += 1

    OUT.write_text(json.dumps(table, ensure_ascii=False, separators=(",", ":"), sort_keys=True) + "\n")
    covered = {}
    for k in table:
        covered.setdefault(int(k.split("|")[1]), 0)
        covered[int(k.split("|")[1])] += 1
    print(f"{OUT.relative_to(ROOT)}: 역·노선 {len(table)}개, {OUT.stat().st_size // 1024}KB")
    print("노선별 막차 데이터 있는 역:", dict(sorted(covered.items())))
    if empty_lines:
        print("원본에 막차가 없는 역 수:", dict(sorted(empty_lines.items())))
    if unknown_dest:
        print("앱에 없는 행선지라 뺀 열차:", ", ".join(sorted(unknown_dest)))
    if skipped:
        print("앱에 없어 건너뜀:", ", ".join(sorted(skipped)))


if __name__ == "__main__":
    main()
