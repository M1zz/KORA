#!/usr/bin/env python3
"""App Store 마케팅 스크린샷(아이폰 1242x2688): 헤드라인 + 서브카피 + 기기 목업, HTML → 헤드리스 Chrome.

  python3 scripts/make_marketing_screenshots.py [로케일 ...]     (없으면 23개 전부)

재료
  docs/screenshots/raw/<로케일>/{route,board,ride,search,language}.png   (scripts/capture_raw_screenshots.py)
  scripts/i18n/store/<로케일>.json 의 shots[] — [헤드라인, 서브카피] 다섯 쌍, 스토어 순서대로
결과
  docs/screenshots/marketing/<로케일>/01-route.png … 05-language.png   ← DeployBar 가 그대로 올린다

⚠️ 문구는 언어마다 따로 쓴다(기계번역 금지). 헤드라인은 2줄, 서브카피는 2줄 안에 들어가야 한다.
   글이 안 맞으면 그림을 만들지 않고 멈춘다 - 그러면 문구를 줄인다.
⚠️ 바탕 · 글자색은 앱 · 소개 페이지 · 헤더 그림(make_creative_assets.py)과 같은 팔레트다.
"""
import json, pathlib, sys, tempfile

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from make_creative_assets import chrome, TMP  # 같은 Chrome 처리(매달림 방지)를 쓴다

ROOT = pathlib.Path(__file__).resolve().parent.parent
RAW = ROOT / "docs" / "screenshots" / "raw"
OUT = ROOT / "docs" / "screenshots" / "marketing"
STORE = ROOT / "scripts" / "i18n" / "store"
W, H = 1242, 2688
LOCALES = ["ko", "en-US", "ja", "zh-Hans", "zh-Hant", "de", "es", "fr", "it", "pt-BR", "ru", "cs",
           "da", "el", "fi", "id", "nb", "nl", "pl", "sv", "th", "tr", "vi"]

# (파일 이름, 원본 화면, 배치) — 순서가 스토어 순서이고 shots[] 순서와 같다
SLIDES = [
    ("01-route.png", "route.png", "hero"),
    ("02-board.png", "board.png", "tilt"),
    ("03-ride.png", "ride.png", "accent"),
    ("04-search.png", "search.png", "hero"),
    ("05-language.png", "language.png", "dark"),
]

BASE_CSS = f"""
* {{ margin:0; padding:0; box-sizing:border-box; }}
html,body {{ width:{W}px; height:{H}px; overflow:hidden; }}
body {{ background:#fdfaf7; position:relative; -webkit-font-smoothing:antialiased;
  font-family:-apple-system, "SF Pro Display", "Apple SD Gothic Neo", sans-serif; }}
body:lang(ja) {{ font-family:-apple-system, "Hiragino Sans", sans-serif; }}
body:lang(zh-Hans) {{ font-family:-apple-system, "PingFang SC", sans-serif; }}
body:lang(zh-Hant) {{ font-family:-apple-system, "PingFang TC", sans-serif; }}
body:lang(th) {{ font-family:-apple-system, "Thonburi", sans-serif; }}
.glow {{ position:absolute; border-radius:50%; filter:blur(140px); pointer-events:none; }}
.text {{ position:absolute; left:90px; right:90px; top:190px; height:540px; text-align:center;
  display:flex; flex-direction:column; align-items:center; }}
.headline {{ font-weight:800; color:#1c1817; letter-spacing:-0.02em; line-height:1.18; text-wrap:balance; }}
.sub {{ font-weight:500; color:#6b6360; letter-spacing:-0.01em; line-height:1.35; margin-top:40px; text-wrap:balance; }}
:lang(ja) .headline, :lang(zh) .headline {{ letter-spacing:.01em; }}
:lang(ko) .headline, :lang(ko) .sub {{ word-break:keep-all; }}
:lang(ja) .headline, :lang(ja) .sub {{ word-break:auto-phrase; }}
.bar {{ width:120px; height:14px; border-radius:7px; background:#D85A30; margin-bottom:56px; }}
.phone {{ position:absolute; background:#17171a; border:4px solid #3a3a3e; padding:28px; border-radius:150px;
  box-shadow:0 70px 140px rgba(28,24,23,.24), 0 20px 50px rgba(28,24,23,.12); }}
.phone img {{ display:block; width:100%; border-radius:122px; }}
"""

LAYOUTS = {
    # 정면 대형, 아래로 블리드
    "hero": """
.phone { left:131px; top:770px; width:980px; }
""",
    # 살짝 기운 폰, 아래로 블리드
    "tilt": """
.phone { left:150px; top:800px; width:980px; transform:rotate(-5deg); }
""",
    # 코랄 바탕 반전
    "accent": """
body { background:#D85A30; }
.headline { color:#ffffff; }
.sub { color:rgba(255,255,255,.82); }
.bar { background:#ffffff; }
.phone { left:131px; top:770px; width:980px; border-color:#5a2a1a;
  box-shadow:0 70px 140px rgba(60,20,10,.35); }
""",
    # 어두운 바탕 반전(마지막 장)
    "dark": """
body { background:#16130f; }
.headline { color:#f7f3ef; }
.sub { color:#a39b96; }
.phone { left:131px; top:770px; width:980px; border-color:#48484e;
  box-shadow:0 0 160px rgba(216,90,48,.28), 0 70px 120px rgba(0,0,0,.55); }
""",
}

FIT_JS = """
<script>
function lines(el) {
  return Math.round(el.getBoundingClientRect().height / parseFloat(getComputedStyle(el).lineHeight));
}
function fit(el, max, min, want) {
  let size = max;
  el.style.fontSize = size + 'px';
  while (size > min && (lines(el) > want || el.scrollWidth > el.clientWidth + 1)) {
    size -= 2; el.style.fontSize = size + 'px';
  }
  return lines(el) <= want && el.scrollWidth <= el.clientWidth + 1;
}
document.fonts.ready.then(() => {
  const box = document.querySelector('.text');
  const ok = fit(document.querySelector('.headline'), 104, 72, 2) &&
             fit(document.querySelector('.sub'), 54, 40, 2) &&
             box.scrollHeight <= box.clientHeight + 1;
  if (!ok) document.body.dataset.overflow = '1';
  document.body.dataset.done = '1';
});
</script>
"""


def page(loc, headline, sub, raw, layout):
    glow = ('<div class="glow" style="left:120px;top:1100px;width:1000px;height:1200px;'
            'background:rgba(216,90,48,.14)"></div>') if layout in ("hero", "tilt") else ""
    lang = "en" if loc == "en-US" else loc
    return (f'<!doctype html><html lang="{lang}"><head><meta charset="utf-8"><style>{BASE_CSS}{LAYOUTS[layout]}'
            f'</style></head><body>{glow}'
            f'<div class="text"><div class="bar"></div><div class="headline">{headline}</div>'
            f'<div class="sub">{sub}</div></div>'
            f'<div class="phone"><img src="{raw.as_uri()}"></div>{FIT_JS}</body></html>')


def render(loc):
    shots = json.loads((STORE / f"{loc}.json").read_text(encoding="utf-8"))["shots"]
    if len(shots) != len(SLIDES):
        raise SystemExit(f"{loc}: shots[] 가 {len(shots)}개 — {len(SLIDES)}개여야 한다")
    out_dir = OUT / loc
    out_dir.mkdir(parents=True, exist_ok=True)
    for (fname, raw_name, layout), (headline, sub) in zip(SLIDES, shots):
        raw = RAW / loc / raw_name
        if not raw.exists():
            raise SystemExit(f"원본 캡처가 없다: {raw}")
        html_path = pathlib.Path(tempfile.gettempdir()) / f"kora-shot-{loc}-{fname}.html"
        html_path.write_text(page(loc, headline, sub, raw, layout), encoding="utf-8")
        flags = [f"--window-size={W},{H}", "--force-device-scale-factor=1", "--disable-gpu",
                 "--virtual-time-budget=3000", "--allow-file-access-from-files"]
        dom_txt = TMP / f"shot-{loc}-{fname}.dom"
        chrome(["--dump-dom", *flags, html_path.as_uri()], dom_txt,
               lambda: "</html>" in dom_txt.read_text(errors="ignore"))
        dom = dom_txt.read_text(errors="ignore")
        if 'data-done="1"' not in dom:
            raise SystemExit(f"글 맞추기가 끝나지 않았다: {loc} {fname}")
        if 'data-overflow="1"' in dom:
            raise SystemExit(f"글이 자리를 넘는다: {loc} {fname} - 문구를 줄일 것")
        out_png = out_dir / fname
        out_png.unlink(missing_ok=True)
        sizes = []

        def written():
            sizes.append(out_png.stat().st_size if out_png.exists() else 0)
            return len(sizes) > 2 and sizes[-1] > 0 and sizes[-1] == sizes[-2] == sizes[-3]
        if not chrome([f"--screenshot={out_png}", "--hide-scrollbars", *flags, html_path.as_uri()],
                      TMP / f"shot-{loc}-{fname}.log", written):
            raise SystemExit(f"Chrome 이 그리지 못했다: {out_png}")
        print(f"rendered {out_png.relative_to(ROOT)}")


if __name__ == "__main__":
    for loc in sys.argv[1:] or LOCALES:
        if loc not in LOCALES:
            raise SystemExit(f"모르는 로케일: {loc}")
        render(loc)
