# Expo Multi Build Template

Expo プロジェクトを、4通りのビルド方法にそれぞれ対応できるようにしたテンプレートリポジトリです。プロジェクトの性質やチーム体制に応じて、どれか一つ、または複数を併用できます。

| # | 方法 | 特徴 | ドキュメント |
|---|---|---|---|
| 1 | Local EAS Build | 手元 Mac で `eas build --local` | [docs/01-local-eas-build.md](./docs/01-local-eas-build.md) |
| 2 | EAS Cloud Build | `eas build` で Expo クラウドビルド | [docs/02-eas-cloud-build.md](./docs/02-eas-cloud-build.md) |
| 3 | Xcode Cloud Build | Apple 公式 CI（iOS のみ） | [docs/03-xcode-cloud.md](./docs/03-xcode-cloud.md) |
| 4-A | GitHub Actions | EAS Cloud Build on GHA | [docs/04-github-actions-eas-build.md](./docs/04-github-actions-eas-build.md) |
| 4-B | GitHub Actions | Fastlane Match Build on GHA | [docs/05-github-actions-fastlane.md](./docs/05-github-actions-fastlane.md)（初回は管理者、参加者は証明書リポ作成をスキップ可） |

環境変数・Secrets の一覧と設定方法は [docs/secrets-and-env.md](./docs/secrets-and-env.md) にまとめています。

## このテンプレートの使い方（新しいプロジェクトを始める場合）

1. GitHub の "Use this template" からリポジトリを複製する（または `git clone` してリモートを付け替える）。
2. 以下を自分のプロジェクトの値に置き換える。

   | ファイル | 置き換える項目 |
   |---|---|
   | `app.json` | `name` / `slug` / `ios.bundleIdentifier` / `android.package` / `extra.eas.projectId` |
   | `package.json` | `name` |
   | `eas.json` | `submit.production` の Apple ID / ASC App ID / Team ID（本番値はコミットしない） |

3. 使いたいビルド方法のドキュメント（上表）を読み、環境変数を設定する。

   | ビルド方法 | ローカル | CI / クラウド |
   |---|---|---|
   | Fastlane Match（4-B） | `cp fastlane/.env.example fastlane/.env` | `gh secret set` / `gh variable set` |
   | EAS（1 / 2 / 4-A） | シェル環境変数 + `eas.json` | `EXPO_TOKEN`（GHA）/ EAS Secrets |
   | Xcode Cloud（3） | — | ワークフローの Environment Variables |

4. `npm install` して `npm start` で動作確認。

## リポジトリ構成

```
.
├── app.json                 # Expo設定（アプリ名・Bundle ID・EASプロジェクトIDなど）
├── eas.json                 # EAS Buildのビルド/提出プロファイル
├── App.tsx
├── docs/                    # 各ビルド方法の詳細ガイド + secrets一覧
├── fastlane/
│   ├── .env.example         # ローカル fastlane 用環境変数テンプレート（.env は gitignore）
│   └── ...                  # 証明書管理(match) + iOS/Androidビルドレーン
├── .github/workflows/
│   ├── eas-build.yml               # GHAからEAS Cloud Buildをキック
│   └── ios-fastlane-match-build.yml # GHA上でmatch証明書を使いネイティブビルド
└── ios/ci_scripts/
    └── ci_post_clone.sh     # Xcode Cloud用のセットアップスクリプト
```

`ios/` `android/` フォルダ自体は Continuous Native Generation（CNG）方式のため `.gitignore` 対象です（`ios/ci_scripts` のみ例外的にコミットされています）。詳細は各 docs を参照してください。

## 4つの方法の比較

| 観点 | Local EAS Build | EAS Cloud Build | Xcode Cloud Build | GitHub Actions |
|---|---|---|---|---|
| Mac 必須か | iOS は必須 | 不要 | 不要（Apple 提供） | 4-A: 不要 / 4-B: macOS ランナー |
| 証明書管理 | 手元 / match | EAS 管理 or 持ち込み | Apple 自動管理が基本 | 4-A: EAS / 4-B: 専用 Git リポ |
| セットアップの手間 | 小 | 小 | 中 | 中〜大 |
| 費用 | 無料（自前マシン） | 無料枠 + 従量課金 | Apple Developer Program に含まれる枠あり | GitHub Actions の分数課金 |
| Android 対応 | ○ | ○ | × | ○ |
| 主な用途 | ローカル検証・デバッグ | 汎用・チーム開発 | iOS 特化・Apple 完結志向 | CI 自動化（EAS または Fastlane） |

## 開発時の実行

日常の開発・デバッグでは `npm run ios` / `npm run android`（内部的に `expo run`）を使えます。これは上記 4 工程のビルド配信パイプラインとは別の開発用コマンドです。

## 前提ツール

Node.js 20.x / Xcode / CocoaPods / Android Studio（SDK・NDK）/ `eas-cli` / `fastlane`。詳細は各 docs のページを参照してください。
