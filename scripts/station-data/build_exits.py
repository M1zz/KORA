#!/usr/bin/env python3
"""출구 안내 데이터 생성기 (KORA Pro).

원본: 공공데이터포털 "서울교통공사_역별 역세권 현황" (파일데이터, 인증키 필요 없음)
      https://www.data.go.kr/data/15044230/fileData.do
      1~8호선, 9호선 2·3단계 역의 출구번호별 주변 장소 (한글, 역 안 표지판 표기).
출력: KORA/station_exits.json  — { 앱 역 이름: [[출구번호, [장소, …]], …] }

  python3 scripts/station-data/build_exits.py            # 내려받아서 생성
  python3 scripts/station-data/build_exits.py 원본.csv   # 받아 둔 CSV 로 생성

원본이 갱신되면(포털 '수정일') 다시 돌린다. 앱 역 이름과 맞지 않는 역은 끝에 알린다.
"""
import csv, io, json, pathlib, re, sys, urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "KORA/station_exits.json"
URL = ("https://www.data.go.kr/cmm/cmm/fileDownload.do"
       "?atchFileId=FILE_000000007644618&fileDetailSn=1&insertDataPrcus=N")

# (호선, 원본 역명) → 앱 역 이름. 동명이역 구분 괄호와, 앱이 아직 옛 이름을 쓰는 역.
ALIASES = {
    ("5", "양평"): "양평(서울)",
    ("4", "불암산"): "당고개",       # 2024 개명
    ("7", "자양"): "뚝섬유원지",     # 2025 개명
}


def app_station_names():
    names = set()
    for f in (ROOT / "KORA/Sources/Features/Subway").glob("SubwayLineData*.swift"):
        names |= set(re.findall(r'"([가-힣][가-힣0-9()·]*)"', f.read_text()))
    return names


EXIT_NO = re.compile(r"^\d+(-\d+)?$")


def exit_sort_key(no):
    # "1", "2", "3-1", "10" → 숫자 순서
    return [int(p) for p in no.split("-")]


def main():
    if len(sys.argv) > 1:
        raw = pathlib.Path(sys.argv[1]).read_bytes()
    else:
        req = urllib.request.Request(URL, headers={"User-Agent": "Mozilla/5.0"})
        raw = urllib.request.urlopen(req, timeout=60).read()
    text = raw.decode("cp949", errors="strict") if not raw.startswith(b"\xef\xbb\xbf") else raw.decode("utf-8-sig")
    rows = list(csv.DictReader(io.StringIO(text)))
    if not rows or "출구번호" not in rows[0]:
        sys.exit("원본 형식이 바뀌었다: 열 이름을 확인할 것")

    known = app_station_names()
    exits, unmatched = {}, set()
    for r in rows:
        line, name = r["호선"].strip(), r["전철역명"].strip()
        no, place = r["출구번호"].strip(), r["역세권명"].strip()
        if not EXIT_NO.match(no) or not place:
            continue  # "00(연결통로)" 처럼 출구가 아닌 줄
        key = ALIASES.get((line, name), name)
        if key not in known:
            unmatched.add(f"{line}호선 {name}")
            continue
        places = exits.setdefault(key, {}).setdefault(no, [])
        if place not in places:
            places.append(place)

    out = {
        st: [[no, sorted(ps)] for no, ps in sorted(by_no.items(), key=lambda kv: exit_sort_key(kv[0]))]
        for st, by_no in sorted(exits.items())
    }
    OUT.write_text(json.dumps(out, ensure_ascii=False, separators=(",", ":")) + "\n")
    total = sum(len(v) for v in out.values())
    print(f"{OUT.relative_to(ROOT)}: 역 {len(out)}개, 출구 {total}개, {OUT.stat().st_size // 1024}KB")
    if unmatched:
        print("앱 노선 데이터에 없는 역 (건너뜀):", ", ".join(sorted(unmatched)))


if __name__ == "__main__":
    main()
