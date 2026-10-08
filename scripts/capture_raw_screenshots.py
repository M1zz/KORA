#!/usr/bin/env python3
"""App Store 원본 캡처: 시뮬레이터에서 언어마다 같은 여정(홍대입구 → 명동)을 찍는다.

  python3 scripts/capture_raw_screenshots.py <UDID> [로케일 ...]     (없으면 23개 전부)

- 앱은 Debug 빌드로 미리 설치해 둔다(-KORAShotScene 은 Debug 에서만 듣는다).
- 위치 권한은 미리 허용해 둔다(`xcrun simctl privacy <UDID> grant location com.kora.leeo`).
  스크린샷 모드는 출발역을 고정하므로 위치 팝업이 뜨지 않는다.
- 상태 막대는 `xcrun simctl status_bar <UDID> override --time 9:41 ...` 로 고정해 둔다.
- 결과: docs/screenshots/raw/<로케일>/{route,board,ride,search,language}.png (1320x2868)
  화면이 아직 비어 있으면(전환 중) 다시 찍는다.
"""
import subprocess, sys, time, pathlib
from PIL import Image, ImageStat

ROOT = pathlib.Path(__file__).resolve().parent.parent
RAW = ROOT / "docs" / "screenshots" / "raw"
BUNDLE = "com.kora.leeo"
SCENES = ["route", "board", "ride", "search", "language"]

# 스토어 로케일 → (앱 언어 StationLanguage raw, AppleLanguages, AppleLocale)
LOCALES = {
    "ko": ("korean", "ko", "ko_KR"), "en-US": ("english", "en-US", "en_US"), "ja": ("japanese", "ja", "ja_JP"),
    "zh-Hans": ("chinese", "zh-Hans", "zh_CN"), "zh-Hant": ("chineseTraditional", "zh-Hant", "zh_TW"),
    "de": ("german", "de", "de_DE"), "es": ("spanish", "es", "es_ES"), "fr": ("french", "fr", "fr_FR"),
    "it": ("italian", "it", "it_IT"), "pt-BR": ("portugueseBrazil", "pt-BR", "pt_BR"),
    "ru": ("russian", "ru", "ru_RU"), "cs": ("czech", "cs", "cs_CZ"), "da": ("danish", "da", "da_DK"),
    "el": ("greek", "el", "el_GR"), "fi": ("finnish", "fi", "fi_FI"), "id": ("indonesian", "id", "id_ID"),
    "nb": ("norwegian", "nb", "nb_NO"), "nl": ("dutch", "nl", "nl_NL"), "pl": ("polish", "pl", "pl_PL"),
    "sv": ("swedish", "sv", "sv_SE"), "th": ("thai", "th", "th_TH"), "tr": ("turkish", "tr", "tr_TR"),
    "vi": ("vietnamese", "vi", "vi_VN"),
}


def blank(path):
    """상태 막대 아래가 거의 한 색이면 아직 그려지지 않은 화면이다."""
    im = Image.open(path).convert("L")
    body = im.crop((0, 260, im.width, im.height // 2))
    return ImageStat.Stat(body).stddev[0] < 6


def ensure_booted(udid):
    """다른 작업이 기기를 꺼 버리는 일이 있다 — 꺼져 있으면 다시 켜고 상태 막대·위치를 다시 맞춘다."""
    out = subprocess.run(["xcrun", "simctl", "list", "devices"], capture_output=True, text=True, timeout=300).stdout
    if f"({udid}) (Booted)" in out:
        return
    subprocess.run(["xcrun", "simctl", "boot", udid], capture_output=True, timeout=600)
    subprocess.run(["xcrun", "simctl", "bootstatus", udid, "-b"], capture_output=True, timeout=900)
    subprocess.run(["xcrun", "simctl", "status_bar", udid, "override", "--time", "9:41", "--batteryState", "charged",
                    "--batteryLevel", "100", "--cellularBars", "4", "--wifiBars", "3", "--dataNetwork", "wifi"],
                   capture_output=True, timeout=300)
    subprocess.run(["xcrun", "simctl", "location", udid, "set", "37.5572,126.9245"], capture_output=True, timeout=300)


def shoot(udid, loc, scene):
    app_lang, apple_lang, apple_locale = LOCALES[loc]
    out = RAW / loc / f"{scene}.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    for attempt in range(10):
        # 여러 시뮬레이터가 함께 돌면 simctl 이 가끔 멈춘다 — 시간 제한을 두고 다시 한다.
        try:
            ensure_booted(udid)
            subprocess.run(["xcrun", "simctl", "launch", "--terminate-running-process", udid, BUNDLE,
                            "-KORAShotScene", scene, "-kora.display_language", app_lang,
                            "-AppleLanguages", f"({apple_lang})", "-AppleLocale", apple_locale],
                           check=True, capture_output=True, timeout=240)
            time.sleep(7 + min(attempt, 4) * 2)
            subprocess.run(["xcrun", "simctl", "io", udid, "screenshot", str(out)],
                           check=True, capture_output=True, timeout=180)
        except (subprocess.TimeoutExpired, subprocess.CalledProcessError):
            continue
        if out.exists() and not blank(out):
            print(f"{loc} {scene}", flush=True)
            return True
    print(f"실패(빈 화면 또는 시간 초과): {loc} {scene}", flush=True)
    return False


if __name__ == "__main__":
    udid, *locs = sys.argv[1:]
    failed = [(loc, scene) for loc in locs or list(LOCALES) for scene in SCENES if not shoot(udid, loc, scene)]
    if failed:
        raise SystemExit("다시 찍을 것: " + ", ".join(f"{l}/{s}" for l, s in failed))
    subprocess.run(["xcrun", "simctl", "terminate", udid, BUNDLE], capture_output=True)
