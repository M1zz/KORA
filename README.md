# KORA — 日本人向け韓国旅行アプリ

> インスタで見つけて、KORAで行く。

## 概要

KORAは、日本人旅行者が韓国を「現地人のように」旅するためのiOSアプリです。

### 4つのコア機能

| タブ | 機能 |
|------|------|
| **Save** | InstagramのURLを貼り付けてスポット情報を自動取得・日本語変換 |
| **Go** | 保存リスト基づいたAI動線最適化 + Naverマップ連携ナビ |
| **Now** | 現在地周辺のリアルタイム情報（営業状況・待ち時間・イベント） |
| **Share** | 日本人旅行者による日本語レビューコミュニティ |

## 開発環境

- Xcode 15.3+
- iOS 17.0+
- Swift 5.9+
- SwiftUI

## セットアップ

```bash
git clone <repo>
cd KORA
open KORA.xcodeproj
```

## アーキテクチャ

```
KORA/
├── KORAApp.swift          # App entry point
├── MainTabView.swift      # Tab navigation
├── Sources/
│   ├── Features/
│   │   ├── Save/          # Instagram URL parser + saved places
│   │   ├── Go/            # Map + route optimization
│   │   ├── Now/           # Real-time local info
│   │   └── Share/         # JP community reviews
│   └── Common/
│       ├── Models/        # Place, Review
│       ├── Components/    # Shared UI
│       └── Theme/         # KORATheme design system
└── Assets.xcassets
```

## MVP ロードマップ

- [x] プロジェクト構造・デザインシステム
- [x] Saveタブ（URL貼り付け → スポットカード）
- [x] Goタブ（地図表示 + 動線最適化）
- [x] Nowタブ（イベント + 周辺スポット）
- [x] Shareタブ（レビューコミュニティ）
- [ ] Instagram Graph API 実連携
- [ ] Naver Map SDK 統合
- [ ] 位置情報リアルタイムフィルタリング
- [ ] チケット代行機能
- [ ] WOWPASS連携

## Bundle ID

`com.kora.app`

開発チームIDは Xcode の Signing & Capabilities から設定してください。
