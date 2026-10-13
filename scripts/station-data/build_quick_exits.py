#!/usr/bin/env python3
"""빠른 하차 데이터 생성기 (KORA Pro 캐리어 모드).

원본: 공공데이터포털 "서울교통공사_빠른하차정보" (getFstExit)
      https://www.data.go.kr/data/15143840/openapi.do
      역·진행 방향마다 엘리베이터·에스컬레이터·계단에 가장 가까운 열차 칸-문 번호.
키:   KORA/Config/Secrets.xcconfig 의 DATA_GO_KR_KEY (Encoding 키, 또는 같은 이름의 환경 변수).
      키는 이 스크립트만 쓴다. 앱에는 결과 JSON 만 들어간다.
출력: KORA/quick_exits.json
      { "앱역이름|노선번호": { "진행 방향 다음 역": { "e": [문, …], "s": [문, …] } } }
      e = 엘리베이터, s = 에스컬레이터. (계단은 짐이 있을 때 피할 곳이라 넣지 않는다)

  python3 scripts/station-data/build_quick_exits.py
"""
import json, os, pathlib, re, sys, time, urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "KORA/quick_exits.json"
URL = "https://apis.data.go.kr/B553766/inout/getFstExit"

LINES = {f"{n}호선": n for n in range(1, 10)}
ALIASES = {
    (5, "양평"): "양평(서울)",
    (4, "불암산"): "당고개",
    (7, "자양"): "뚝섬유원지",
}
KINDS = {"엘리베이터": "e", "에스컬레이터": "s"}
DOOR = re.compile(r"^\d{1,2}-\d$")


def api_key():
    if os.environ.get("DATA_GO_KR_KEY"):
        return os.environ["DATA_GO_KR_KEY"].strip()
    m = re.search(r"^DATA_GO_KR_KEY\s*=\s*(\S+)", (ROOT / "KORA/Config/Secrets.xcconfig").read_text(), re.M)
    if not m:
        sys.exit("DATA_GO_KR_KEY 가 없다: KORA/Config/Secrets.xcconfig 에 넣을 것")
    return m.group(1)


def page(key, n):
    url = f"{URL}?serviceKey={key}&dataType=JSON&numOfRows=1000&pageNo={n}"
    for attempt in range(4):
        try:
            with urllib.request.urlopen(url, timeout=30) as r:
                body = json.loads(r.read())["response"]["body"]
                items = body["items"]["item"] if body.get("items") else []
                return body["totalCount"], items if isinstance(items, list) else [items]
        except Exception:
            time.sleep(2 * (attempt + 1))
    raise RuntimeError(f"요청 실패: {n}쪽")


def app_station_names():
    names = set()
    for f in (ROOT / "KORA/Sources/Features/Subway").glob("SubwayLineData*.swift"):
        names |= set(re.findall(r'"([가-힣][가-힣0-9()·]*)"', f.read_text()))
    return names


def door_key(d):
    car, door = d.split("-")
    return int(car), int(door)


def main():
    key = api_key()
    total, rows = page(key, 1)
    n = 2
    while len(rows) < total:
        _, more = page(key, n)
        if not more:
            break
        rows += more
        n += 1

    known = app_station_names()
    table, skipped = {}, set()
    for r in rows:
        line = LINES.get(r.get("lineNm", ""))
        kind = KINDS.get(r.get("plfmCmgFac", ""))
        door = (r.get("qckgffVhclDoorNo") or "").strip()
        if line is None or kind is None or not DOOR.match(door):
            continue
        name = ALIASES.get((line, r["stnNm"].strip()), r["stnNm"].strip())
        toward = ALIASES.get((line, r["drtnInfo"].strip()), r["drtnInfo"].strip())
        if name not in known or toward not in known:
            skipped.add(f"{line}호선 {r['stnNm']}→{r['drtnInfo']}")
            continue
        doors = table.setdefault(f"{name}|{line}", {}).setdefault(toward, {}).setdefault(kind, [])
        if door not in doors:
            doors.append(door)
    for by_dir in table.values():
        for kinds in by_dir.values():
            for k in kinds:
                kinds[k].sort(key=door_key)

    OUT.write_text(json.dumps(table, ensure_ascii=False, separators=(",", ":"), sort_keys=True) + "\n")
    with_elevator = sum(1 for v in table.values() if any("e" in k for k in v.values()))
    print(f"{OUT.relative_to(ROOT)}: 원본 {len(rows)}줄, 역·노선 {len(table)}개 (엘리베이터 있는 곳 {with_elevator}), "
          f"{OUT.stat().st_size // 1024}KB")
    if skipped:
        print("앱 노선 데이터와 맞지 않아 뺀 줄:", ", ".join(sorted(skipped)))


if __name__ == "__main__":
    main()
