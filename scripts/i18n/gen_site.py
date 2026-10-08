#!/usr/bin/env python3
"""소개 · 지원 · 개인정보 페이지 생성기 (GitHub Pages, docs/<로케일>/).

- scripts/i18n/site/<로케일>.py 의 T 사전으로 그 언어의 세 페이지를 만든다
  (ko·en·ja·zh-Hans·zh-Hant 다섯 언어는 손으로 쓴 페이지라 생성하지 않는다).
- 모든 페이지(손으로 쓴 것 포함)의 언어 메뉴와 hreflang 을 23개 언어로 맞춘다.

  python3 scripts/i18n/gen_site.py
"""
import html, importlib.util, pathlib, re

ROOT = pathlib.Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs"
BASE = "https://m1zz.github.io/KORA"
LANGS = [("ko", "한국어"), ("en", "English"), ("ja", "日本語"), ("zh-Hans", "简体中文"), ("zh-Hant", "繁體中文"),
         ("de", "Deutsch"), ("es", "Español"), ("fr", "Français"), ("it", "Italiano"), ("pt-BR", "Português (Brasil)"),
         ("ru", "Русский"), ("cs", "Čeština"), ("da", "Dansk"), ("el", "Ελληνικά"), ("fi", "Suomi"),
         ("id", "Bahasa Indonesia"), ("nb", "Norsk"), ("nl", "Nederlands"), ("pl", "Polski"), ("sv", "Svenska"),
         ("th", "ไทย"), ("tr", "Türkçe"), ("vi", "Tiếng Việt")]
HANDWRITTEN = {"ko", "en", "ja", "zh-Hans", "zh-Hant"}
PAGES = {"index": "", "support": "support.html", "privacy": "privacy.html"}
EMAIL = "mizzking75@gmail.com"


def page_url(loc, page):
    return f"{BASE}/{loc}/{PAGES[page]}"


def alternates(page):
    lines = [f'<link rel="alternate" hreflang="{l}" href="{page_url(l, page)}">' for l, _ in LANGS]
    root = f"{BASE}/" + ("" if page == "index" else PAGES[page])
    lines.append(f'<link rel="alternate" hreflang="x-default" href="{root}">')
    return "\n".join(lines)


def lang_nav(loc, page):
    fn = "index.html" if page == "index" else PAGES[page]
    items = []
    for l, name in LANGS:
        cur = ' aria-current="true"' if l == loc else ""
        items.append(f'    <a href="../{l}/{fn}" hreflang="{l}" lang="{l}"{cur}>{name}</a>')
    return '  <nav class="langs" aria-label="Language">\n' + "\n".join(items) + "\n  </nav>"


def fix_nav(text, loc, page):
    """언어 메뉴와 hreflang 블록을 23개 언어로 바꾼다."""
    text = re.sub(r'(<link rel="alternate" hreflang="[^"]+" href="[^"]+">\n?)+', alternates(page) + "\n", text, count=1)
    text = re.sub(r'  <nav class="langs" aria-label="Language">.*?</nav>', lambda m: lang_nav(loc, page), text,
                  count=1, flags=re.S)
    return text


def li(items):
    return "\n".join(f"        <li>{x}</li>" for x in items)


def shell(loc, page, T, title, desc, main):
    nav_cur = {p: (' aria-current="page"' if p == page else "") for p in PAGES}
    return f"""<!doctype html>
<html lang="{loc}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="color-scheme" content="light dark">
<title>{title}</title>
<meta name="description" content="{html.escape(desc, quote=True)}">
<link rel="canonical" href="{page_url(loc, page)}">
{alternates(page)}
<link rel="stylesheet" href="../style.css">
<link rel="icon" href="../icon.png">
<link rel="apple-touch-icon" href="../icon.png">
</head>
<body>
<div class="container">

  <header class="site">
    <img src="../icon.png" alt="{T['icon_alt']}">
    <div>
      <div class="title">{T['site_title']}</div>
      <div class="subtitle">{T['site_subtitle']}</div>
    </div>
  </header>

{lang_nav(loc, page)}

  <nav class="pages" aria-label="Pages">
    <a href="index.html"{nav_cur['index']}>{T['nav_home']}</a>
    <a href="support.html"{nav_cur['support']}>{T['nav_support']}</a>
    <a href="privacy.html"{nav_cur['privacy']}>{T['nav_privacy']}</a>
  </nav>

  <main>
{main}
  </main>

  <footer class="site">
    © 2026 Leeo · <a href="support.html">{T['nav_support']}</a> · <a href="privacy.html">{T['nav_privacy']}</a>
  </footer>
</div>
</body>
</html>
"""


def index_page(loc, T):
    cards = "\n".join(f"""      <div class="card">
        <h3>{h}</h3>
        <p>{p}</p>
      </div>""" for h, p in T["features"])
    main = f"""<h1>{T['index_h1']}</h1>
    <p class="lead">{T['index_lead']}</p>

    <h2>{T['features_h2']}</h2>
    <div class="features">
{cards}
    </div>

    <h2>{T['coverage_h2']}</h2>
    <p>{T['coverage_p']}</p>

    <h2>{T['privacy_h2']}</h2>
    <p>{T['privacy_p']}</p>

    <div class="contact">
      {T['index_contact']}
    </div>"""
    return shell(loc, "index", T, T["index_title"], T["index_desc"], main)


def support_page(loc, T):
    cards = []
    for item in T["faq"]:
        h, body = item[0], item[1:]
        parts = []
        for b in body:
            parts.append(f"      <ul>\n{li(b)}\n      </ul>" if isinstance(b, list) else f"      <p>{b}</p>")
        cards.append(f'    <div class="card">\n      <h3>{h}</h3>\n' + "\n".join(parts) + "\n    </div>")
    main = f"""<h1>{T['nav_support']}</h1>
    <p class="lead">{T['support_lead']}</p>

    <h2>{T['faq_h2']}</h2>

""" + "\n\n".join(cards) + f"""

    <h2>{T['a11y_h2']}</h2>
    <p>{T['a11y_p']}</p>

    <div class="contact">
      {T['support_contact']}
    </div>"""
    return shell(loc, "support", T, T["support_title"], T["support_desc"], main)


def table(rows, head=None):
    out = ['    <div class="table-wrap">', "      <table>"]
    if head:
        out.append("        <thead><tr>" + "".join(f"<th>{h}</th>" for h in head) + "</tr></thead>")
    out.append("        <tbody>")
    for r in rows:
        if head:
            out.append("          <tr>" + "".join(f"<td>{c}</td>" for c in r) + "</tr>")
        else:
            out.append(f"          <tr><th>{r[0]}</th><td>{r[1]}</td></tr>")
    out += ["        </tbody>", "      </table>", "    </div>"]
    return "\n".join(out)


def privacy_page(loc, T):
    P = T["privacy"]
    blocks = [f"<h1>{T['nav_privacy']}</h1>", f'    <p class="lead">{P["effective"]}</p>', f"    <p>{P['intro']}</p>",
              f'    <div class="card">\n      <h3>{P["glance_h"]}</h3>\n      <ul>\n{li(P["glance"])}\n      </ul>\n    </div>']
    for sec in P["sections"]:
        kind = sec[0]
        if kind == "h2":
            blocks.append(f"    <h2>{sec[1]}</h2>")
        elif kind == "h3":
            blocks.append(f"    <h3>{sec[1]}</h3>")
        elif kind == "p":
            blocks.append(f"    <p>{sec[1]}</p>")
        elif kind == "ul":
            blocks.append(f"    <ul>\n{li(sec[1])}\n    </ul>".replace("        <li>", "      <li>"))
        elif kind == "table":
            blocks.append(table(sec[2], sec[1]))
        elif kind == "kv":
            blocks.append(table(sec[1]))
    return shell(loc, "privacy", T, T["privacy_title"], T["privacy_desc"], "\n\n".join(blocks))


ROOT_LABELS = {"ko": ("홈", "지원", "개인정보 처리방침"), "en": ("Home", "Support", "Privacy Policy"),
               "ja": ("ホーム", "サポート", "プライバシーポリシー"), "zh-Hans": ("首页", "支持", "隐私政策"),
               "zh-Hant": ("首頁", "支援", "隱私權政策")}

PICK_JS = """  function pick(tag) {
    var t = String(tag || '').toLowerCase();
    if (t.indexOf('zh') === 0) {
      return /hant|-tw|-hk|-mo/.test(t) ? 'zh-Hant' : 'zh-Hans';
    }
    if (t.indexOf('pt') === 0) return 'pt-BR';
    if (/^(nb|no|nn)(-|$)/.test(t)) return 'nb';
    var base = t.split('-')[0];
    if (base === 'in') base = 'id';
    var known = %s;
    return known.indexOf(base) >= 0 ? base : null;
  }"""


def fix_root(page, labels):
    """docs/ 맨 위의 언어 고르기 페이지(index·support·privacy)."""
    f = DOCS / ("index.html" if page == "index" else PAGES[page])
    text = f.read_text(encoding="utf-8")
    text = re.sub(r'(<link rel="alternate" hreflang="[^"]+" href="[^"]+">\n?)+', alternates(page) + "\n", text, count=1)
    simple = [l for l, _ in LANGS if l not in ("zh-Hans", "zh-Hant", "pt-BR", "nb")]
    js = PICK_JS % ("[" + ", ".join(f"'{l}'" for l in simple) + "]")
    text = re.sub(r"  function pick\(tag\) \{.*?\n  \}", lambda m: js, text, count=1, flags=re.S)
    idx = list(PAGES).index(page)
    href = "" if page == "index" else PAGES[page]
    items = "\n".join(f'    <li><a href="{l}/{href}" hreflang="{l}" lang="{l}">{name} — {labels[l][idx]}</a></li>'
                      for l, name in LANGS)
    text = re.sub(r'  <ul class="picker">.*?</ul>', lambda m: f'  <ul class="picker">\n{items}\n  </ul>', text,
                  count=1, flags=re.S)
    f.write_text(text, encoding="utf-8")


def main():
    labels = dict(ROOT_LABELS)
    for loc, _ in LANGS:
        d = DOCS / loc
        if loc in HANDWRITTEN:
            for page in PAGES:
                f = d / ("index.html" if page == "index" else PAGES[page])
                f.write_text(fix_nav(f.read_text(encoding="utf-8"), loc, page), encoding="utf-8")
            continue
        src = ROOT / "scripts/i18n/site" / f"{loc}.py"
        spec = importlib.util.spec_from_file_location(loc.replace("-", "_"), src)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        T = mod.T
        labels[loc] = (T["nav_home"], T["nav_support"], T["nav_privacy"])
        d.mkdir(exist_ok=True)
        (d / "index.html").write_text(index_page(loc, T), encoding="utf-8")
        (d / "support.html").write_text(support_page(loc, T), encoding="utf-8")
        (d / "privacy.html").write_text(privacy_page(loc, T), encoding="utf-8")
        print("wrote", loc)
    for page in PAGES:
        fix_root(page, labels)


if __name__ == "__main__":
    main()
