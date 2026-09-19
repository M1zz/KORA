#!/bin/sh
# 배포 전 게이트 - 여기서 실패하면 DeployBar 가 아카이브를 만들지 않는다.
#
# 사용법:
#   sh scripts/predeploy.sh
#
# 카탈로그(.xcstrings) 빈칸 검사는 DeployBar 에도 있지만, 여기서는 이 앱만의 사정을 본다.
#   화면 문구는 앱 안 언어 선택을 따라야 해서 카탈로그가 아니라 NavLoc(코드)에 있다.
#   NavLoc 은 다섯 언어가 모두 필수 인자라 빠지면 컴파일이 멈춘다 - 그래서 빌드가 곧 검사다.
#
# ⚠️ 이 앱에는 테스트 타겟이 없다. 이 게이트는 "컴파일은 된다"까지만 말해 준다.
set -e
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

SCHEME="KORA"
PROJECT="KORA.xcodeproj"
VERSION_XCCONFIG="KORA/Config/Version.xcconfig"
LANGS="en ja ko zh-Hans zh-Hant"

# ── 1. 버전 소스가 한 곳인지 ────────────────────────────────────────────
# project.pbxproj 에 MARKETING_VERSION 이 되살아나면 xcconfig 를 이겨서
# DeployBar 가 올린 버전이 조용히 무시되고 앱·위젯 버전이 어긋난다.
echo "🔢 [1/4] 버전 소스 확인"
for KEY in MARKETING_VERSION CURRENT_PROJECT_VERSION; do
  if ! grep -qE "^[[:space:]]*$KEY[[:space:]]*=" "$VERSION_XCCONFIG"; then
    echo "❌ $VERSION_XCCONFIG 에 $KEY 줄이 없습니다"
    exit 1
  fi
  if grep -qE "^[[:space:]]*$KEY[[:space:]]*=" "$PROJECT/project.pbxproj"; then
    echo "❌ project.pbxproj 에 $KEY 가 되살아났습니다 - xcconfig 를 이겨 버립니다"
    echo "   (Xcode 타겟 > General 의 Version·Build 칸을 고치면 이렇게 됩니다)"
    echo "   그 줄을 지우고 $VERSION_XCCONFIG 에서만 고쳐 주세요"
    exit 1
  fi
done
echo "   $(grep -E '^[[:space:]]*MARKETING_VERSION' "$VERSION_XCCONFIG" | tr -s ' ') · $(grep -E '^[[:space:]]*CURRENT_PROJECT_VERSION' "$VERSION_XCCONFIG" | tr -s ' ')"

# ── 2. 카탈로그가 다섯 언어로 다 찼는지 ──────────────────────────────────
echo "🌐 [2/4] 카탈로그 언어 확인 ($LANGS)"
python3 - "$LANGS" KORA/InfoPlist.xcstrings widget/Localizable.xcstrings <<'PY'
import json, sys
langs = sys.argv[1].split()
bad = []
for path in sys.argv[2:]:
    for key, entry in json.load(open(path, encoding="utf-8"))["strings"].items():
        if key == "CFBundleName" or entry.get("shouldTranslate") is False:
            continue
        locs = entry.get("localizations", {})
        missing = [l for l in langs if not locs.get(l, {}).get("stringUnit", {}).get("value")]
        if missing:
            bad.append(f"{path}: {key} - {', '.join(missing)}")
if bad:
    print("❌ 번역 빈칸\n   " + "\n   ".join(bad))
    sys.exit(1)
print("   빈칸 없음")
PY

# ── 3. 역 이름 번체 표가 간체 표와 맞는지 ────────────────────────────────
echo "🀄 [3/4] 역 이름 번체 표 확인"
python3 scripts/i18n/gen_station_zh_hant.py --check

# ── 4. Release 빌드가 서는지 ────────────────────────────────────────────
echo "🏗  [4/4] Release 빌드"
xcodebuild build \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=iOS Simulator' \
  -quiet

echo ""
echo "✅ 모든 검사 통과 - 배포 가능"
