#!/usr/bin/env python3
"""앱 아이콘 생성기: 흰 바탕에 열차 정면, 몸체는 태극(위 빨강 · 아래 파랑), 선로는 검정.

  python3 scripts/make_app_icon.py

태극기의 네 색(흰 바탕 · 빨강 · 파랑 · 검정)을 그대로 쓴다.
열차 모양은 일본길찾기 아이콘과 같다. 두 앱이 한 시리즈로 보이도록 모양은 그대로 두고 색만 나라에 맞춘다.
모양을 고치면 ../일본길찾기/scripts/make_app_icon.py 도 같이 고친다.

출력 (1024, 모서리 없음, 투명 없음. iOS 가 모서리를 깎으므로 정사각형을 꽉 채운다)
  KoreaNavi/Assets.xcassets/AppIcon.appiconset/AppIcon.png         밝은 화면
  KoreaNavi/Assets.xcassets/AppIcon.appiconset/AppIcon-dark.png    어두운 화면 (선로는 흰색)
  KoreaNavi/Assets.xcassets/AppIcon.appiconset/AppIcon-tinted.png  색조 화면 (회색조)
  KoreaNaviWatch/Assets.xcassets/AppIcon.appiconset/AppIcon.png    워치 (밝은 화면과 같은 그림)
  docs/icon.png                                                     웹사이트용 (밝은 화면과 같은 그림)
"""
import pathlib
from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parents[1]
ICONSET = ROOT / "KoreaNavi/Assets.xcassets/AppIcon.appiconset"
S = 4                      # 슈퍼샘플링 배율 (가장자리를 매끄럽게)
N = 1024 * S

RED = (205, 46, 58)        # 태극 빨강 #CD2E3A
BLUE = (0, 71, 160)        # 태극 파랑 #0047A0
BLACK = (24, 24, 24)       # 괘의 검정
WHITE = (255, 255, 255)


def s(*v):
    return [x * S for x in v]


def gradient(top, bottom):
    img = Image.new("RGB", (N, N))
    d = ImageDraw.Draw(img)
    for y in range(N):
        t = y / (N - 1)
        d.line([(0, y), (N, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)))
    return img


def taegeuk(red, blue, cx=512, cy=468, r=400, angle=33.7):
    """태극기처럼 기울인 태극. 큰 판에 그려 돌린 뒤 잘라 가장자리가 비지 않게 한다."""
    cx, cy, R, M = cx * S + N, cy * S + N, r * S, N
    layer = Image.new("RGBA", (3 * N, 3 * N), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse([cx - R, cy - R, cx + R, cy + R], fill=blue)
    d.pieslice([cx - R, cy - R, cx + R, cy + R], 180, 360, fill=red)
    d.ellipse([cx - R, cy - R / 2, cx, cy + R / 2], fill=red)
    d.ellipse([cx, cy - R / 2, cx + R, cy + R / 2], fill=blue)
    return layer.rotate(-angle, center=(cx, cy), resample=Image.BICUBIC).crop((M, M, M + N, M + N))


def draw(bg_top, bg_bottom, red, blue, face, rail):
    img = gradient(bg_top, bg_bottom)
    # 열차 몸체 = 태극
    body = Image.new("L", (N, N), 0)
    ImageDraw.Draw(body).rounded_rectangle(s(272, 176, 752, 760), radius=120 * S, fill=255)
    img.paste(taegeuk(red, blue), (0, 0), body)
    d = ImageDraw.Draw(img)
    # 행선지 표시판 · 앞 유리 · 전조등
    d.rounded_rectangle(s(402, 222, 622, 262), radius=20 * S, fill=face)
    d.rounded_rectangle(s(330, 304, 694, 520), radius=48 * S, fill=face)
    for cx in (392, 632):
        d.ellipse(s(cx - 38, 610, cx + 38, 686), fill=face)
    # 다리와 선로
    for x0, x1 in ((392, 330), (632, 694)):
        d.line(s(x0, 740, x1, 852), fill=rail, width=44 * S)
        d.ellipse(s(x1 - 22, 830, x1 + 22, 874), fill=rail)
    d.rounded_rectangle(s(232, 852, 792, 892), radius=20 * S, fill=rail)
    return img.resize((1024, 1024), Image.LANCZOS)


def main():
    light = draw(WHITE, (238, 238, 240), RED, BLUE, WHITE, BLACK)
    dark = draw((43, 43, 47), (20, 20, 22), RED, BLUE, WHITE, WHITE)
    tinted = draw((0, 0, 0), (0, 0, 0), (255, 255, 255), (170, 170, 170), (70, 70, 70), (255, 255, 255))
    light.save(ICONSET / "AppIcon.png")
    dark.save(ICONSET / "AppIcon-dark.png")
    tinted.save(ICONSET / "AppIcon-tinted.png")
    light.save(ROOT / "KoreaNaviWatch/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
    light.save(ROOT / "docs/icon.png")
    print("AppIcon.png, AppIcon-dark.png, AppIcon-tinted.png, Watch AppIcon.png, docs/icon.png")


if __name__ == "__main__":
    main()
