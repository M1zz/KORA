# -*- coding: utf-8 -*-
"""간체(zh-Hans) 문장을 번체(zh-Hant, 대만 어휘)로 바꾼다.

두 단계다 (ClipKeyboard 의 scripts/make_zh_hant.py 와 같은 방식).
  1) 글자: macOS 의 ICU 변환(Hans-Hant). `zh_hant_transform.swift` 가 한다.
  2) 말  : 대만에서 쓰는 어휘·인용부호. 아래 RULES 표가 한다. UI 문장에만 쓴다.
           역 이름은 고유명사라 글자만 바꾼다 (往十里 의 里 가 裡 로 바뀌면 안 된다).

⚠️ 지하철은 대만에서 捷運 이라 부르지만, 이 앱은 한국 지하철 이야기라 地鐵 를 그대로 둔다.
"""
import os
import re
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
SWIFT = os.path.join(HERE, "zh_hant_transform.swift")
NEWLINE_MARK = "⏎"

# 긴 것부터. 순서가 중요하다.
RULES = [
    ("換乘站", "轉乘站"),
    ("站台", "月台"),
    ("顯示屏", "顯示幕"),
    ("識別", "辨識"),
    ("獲取", "取得"),
    ("乘車", "搭車"),
    ("匹配", "符合"),
    ("去往", "前往"),
    ("換乘", "轉乘"),
    ("站臺", "月台"),
    ("實時", "即時"),
    ("當前", "目前"),
    ("攝像頭", "相機"),
    ("手動選擇", "手動選擇"),
    ("設置", "設定"),
    ("默認", "預設"),
    ("屏幕", "螢幕"),
    ("視頻", "影片"),
    ("網絡", "網路"),
    ("信息", "資訊"),
    ("用戶", "使用者"),
    ("數據", "資料"),
    ("打開", "開啟"),
    ("支持", "支援"),
    ("通過", "透過"),
    ("點擊", "點選"),
    ("點按", "點選"),
    ("保存", "儲存"),
    ("搜索", "搜尋"),
    ("界面", "介面"),
    ("智能", "智慧"),
    ("鎖屏", "鎖定畫面"),
    ("反饋", "意見回饋"),
    ("訪問", "存取"),
    ("隱私政策", "隱私權政策"),
    ("添加", "新增"),
    ("文本", "文字"),
    ("質量", "品質"),
    ("準確度", "準確度"),
]

_LI = re.compile(r"(?<![公英])里")


def transform(lines):
    """ICU 로 글자만 번체로 바꾼다 (macOS 의 CFStringTransform)."""
    if not lines:
        return []
    folded = [l.replace("\n", NEWLINE_MARK) for l in lines]
    out = subprocess.run(
        ["swift", SWIFT], input="\n".join(folded), capture_output=True, text=True, check=True
    ).stdout.split("\n")
    if out and out[-1] == "":
        out.pop()
    assert len(out) == len(lines), f"줄 수가 어긋남: {len(lines)} → {len(out)}"
    return [l.replace(NEWLINE_MARK, "\n") for l in out]


def to_taiwan(text):
    for a, b in RULES:
        text = text.replace(a, b)
    text = _LI.sub("裡", text)
    if text.count("“") == text.count("”"):
        text = text.replace("“", "「").replace("”", "」")
    return text


def ui(lines):
    """UI 문장: 글자 변환 + 대만 어휘."""
    return [to_taiwan(l) for l in transform(lines)]


def names(lines):
    """고유명사(역 이름): 글자만."""
    return transform(lines)


if __name__ == "__main__":
    # 새 NavLoc 문구의 번체를 뽑을 때: python3 scripts/i18n/zh_hant.py "简体文句" ...
    import sys
    for line in ui(sys.argv[1:]):
        print(line)
