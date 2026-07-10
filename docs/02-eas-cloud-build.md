# 2. EAS Cloud Build

Expo が提供するクラウドビルドサービス（EAS Build）を使い、Expo/Mac 環境を持たないメンバーでも `eas build` コマンド一つで iOS/Android のビルドができるようにする方法です。

## セットアップ

```bash
npm install -g eas-cli   # または npx eas-cli を都度使う
eas login
eas init                  # app.json の extra.eas.projectId が設定される
eas credentials           # 証明書/キーストアの管理（EAS 側にホスティングする場合）
```

`app.json` の `extra.eas.projectId` を、`eas init` で発行された値に置き換えてください（このテンプレートでは `REPLACE_WITH_YOUR_EAS_PROJECT_ID` になっています）。

## ビルドプロファイル（`eas.json`）

このテンプレートには次のプロファイルを用意しています。

| プロファイル | 用途 | 配布 |
|---|---|---|
| `development` | Dev Client 入りのデバッグビルド | internal |
| `preview` | QA・社内配布用（Android は apk） | internal |
| `production` | ストア提出用（Android は app-bundle） | store |
| `production-local` | `production` と同一設定で `--local` 実行時に使用 | - |

実行例:

```bash
npx eas-cli build --profile development --platform all
npx eas-cli build --profile preview --platform all
npx eas-cli build --profile production --platform all
```

## 証明書・署名の管理方法（2択）

1. **EAS マネージド（デフォルト）**: `eas credentials` で EAS 側に証明書を生成・保管してもらう。個人開発や少人数チーム向け。
2. **自前管理（fastlane match 等）**: [docs/04](./04-github-actions-eas-fastlane.md) の match リポジトリを運用している場合、EAS Build にも同じ証明書を使わせることができます（`eas credentials` → "I want to reuse an existing certificate" のフローで `.p12` / `.mobileprovision` をインポート）。

## TestFlight へアップロード

EAS Build で生成した iOS ビルドを App Store Connect に提出し、TestFlight で配布します。

### 前提

1. [App Store Connect](https://appstoreconnect.apple.com/) でアプリレコードを作成済み（Bundle ID は `app.json` の `ios.bundleIdentifier` と一致）
2. `eas credentials` で iOS の Distribution 証明書・プロビジョニングプロファイルを設定済み（EAS マネージド推奨）
3. `eas.json` の `submit.production.ios` に `appleId` / `ascAppId` / `appleTeamId` を設定済み

### 手順

```bash
# 1. クラウドでビルド
npx eas-cli build --profile production --platform ios

# 2a. 直近のビルドを TestFlight へ提出
npx eas-cli submit --platform ios --latest --profile production

# 2b. ビルドと提出を一括実行
npx eas-cli build --profile production --platform ios --submit
```

非対話実行:

```bash
npx eas-cli submit --platform ios --latest --profile production --non-interactive
```

### 認証の設定

| 方式 | 設定場所 |
|---|---|
| Apple ID + App 専用パスワード | `eas.json` の `submit.production.ios`（`appleId` / `ascAppId` / `appleTeamId`） |
| App Store Connect API Key | EAS Secret または環境変数（`EXPO_APPLE_APP_STORE_CONNECT_API_KEY` 等）。詳細は [docs/secrets-and-env.md](./secrets-and-env.md) |

実際の値は `.env.example` を参照し、機密情報はコミットしないでください。

### アップロード後の確認

1. App Store Connect → **TestFlight** → **Builds** で Processing 完了を待つ
2. **Internal Testing** グループにビルドを割り当て、テスターを追加する

### トラブルシュート

| エラー | 対処 |
|---|---|
| `No suitable application records found` | App Store Connect でアプリを先に作成する |
| `The bundle version must be higher` | `eas.json` の `production` プロファイルで `autoIncrement: true` を確認（本テンプレートは設定済み） |
| 認証エラー | `eas credentials -p ios` で署名を再設定、または API Key を確認 |

## GitHub Actions から実行する場合

CI 上で EAS Cloud Build をトリガーしたい場合は [docs/04](./04-github-actions-eas-fastlane.md) の **4-A. EAS Cloud Build on GHA** を参照してください。
