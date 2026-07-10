# Secrets / 環境変数 一覧

各ビルド方法ごとに必要な値をまとめたものです。実際の値は絶対にコミットせず、GitHub の場合は Settings → Secrets and variables → Actions、EAS の場合は `eas secret:create`、Xcode Cloud の場合はワークフローの Environment Variables に設定してください。`.env.example` をコピーしてローカル用の `.env.local` を作る場合も同様に扱ってください。

## 共通

| 名前 | 用途 | どこで使う |
|---|---|---|
| `APP_IDENTIFIER` | iOS の bundle identifier | GHA / fastlane |
| `APPLE_ID` | Apple ID（App Store Connect ログイン用） | GHA / fastlane / EAS submit |
| `APPLE_TEAM_ID` | Apple Developer Team ID | GHA / fastlane / EAS submit |

## 1. Local EAS Build

EAS `--local` ビルド時はマシンに Apple の Distribution 証明書がインストール済みであること。TestFlight 提出（`eas submit`）時は以下が必要です。

| 名前 | 用途 | 設定場所 |
|---|---|---|
| `eas.json` の `submit.production.ios` | Apple ID / ASC App ID / Team ID | `eas.json`（機密情報はコミットしない） |
| `EXPO_APPLE_APP_SPECIFIC_PASSWORD` | Apple ID 認証時の App 専用パスワード | `.env.local`（API Key 使用時は不要） |
| `EXPO_APPLE_APP_STORE_CONNECT_API_KEY` 等 | App Store Connect API Key 認証 | `.env.local` または環境変数 |

## 2. EAS Cloud Build

| 名前 | 用途 | 設定場所 |
|---|---|---|
| EAS Secret 各種（`eas secret:create` で登録） | EAS ビルド内で使う機密環境変数 | EAS ダッシュボード / CLI |
| `eas.json` の `submit.production.ios` | TestFlight 提出用（Apple ID / ASC App ID / Team ID） | `eas.json` |
| App Store Connect API Key | `eas submit` の代替認証方式 | EAS Secret または環境変数 |

TestFlight 提出は `eas submit --platform ios --latest --profile production` で実行します。

## 3. GitHub Actions

### 3-A. EAS Cloud Build on GHA

| 名前 | 用途 | 設定場所 |
|---|---|---|
| `EXPO_TOKEN` | EAS への API 認証トークン | GitHub Secrets |
| `eas.json` の `submit.production.ios` | TestFlight 提出用（`submit: true` 時） | `eas.json` |
| App Store Connect API Key | `eas submit` の代替認証方式 | EAS Secret または環境変数 |

GitHub Actions から提出する場合は [`.github/workflows/eas-build.yml`](../.github/workflows/eas-build.yml) の `submit` 入力を `true` に設定してください。

### 3-B. Fastlane Match Build on GHA

| 名前 | 用途 | 設定場所 |
|---|---|---|
| `MATCH_GIT_URL` | 証明書用 Git リポジトリの URL | GitHub Secrets |
| `MATCH_PASSWORD` | match の暗号化パスワード | GitHub Secrets |
| `MATCH_GIT_BASIC_AUTHORIZATION` | HTTPS + PAT でアクセスする場合の `base64(user:token)` | GitHub Secrets（SSH 方式なら不要） |
| `MATCH_GIT_SSH_PRIVATE_KEY` | SSH Deploy Key でアクセスする場合の秘密鍵 | GitHub Secrets（HTTPS 方式なら不要） |
| `MATCH_TYPE` | `development` / `appstore` / `adhoc` 等 | GitHub Variables |
| `APP_STORE_CONNECT_API_KEY_P8` | App Store Connect API キー（`.p8` の中身、base64 推奨） | GitHub Secrets |
| `APP_STORE_CONNECT_API_KEY_ID` / `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | 上記キーのメタ情報 | GitHub Secrets |
| `ANDROID_KEYSTORE_BASE64` | Android keystore を base64 化したもの | GitHub Secrets |
| `ANDROID_KEYSTORE_PASSWORD` / `ANDROID_KEY_ALIAS` / `ANDROID_KEY_PASSWORD` | keystore のパスワード類 | GitHub Secrets |

## 4. Xcode Cloud

TestFlight 配信は Xcode Cloud の Post-Action で自動実行されるため、**TestFlight 専用の Secret は通常不要**です。Xcode Managed Signing により証明書関連の Secret も不要です。

| 名前 | 用途 | 設定場所 |
|---|---|---|
| プライベート npm レジストリのトークン等（必要な場合のみ） | `npm ci` がプライベートパッケージに依存する場合 | Xcode Cloud ワークフローの Environment Variables |
| `XCODE_CLOUD_SKIP_PREBUILD` | 方式B（`ios/` をコミットする運用）にする場合に `true` を設定 | Xcode Cloud ワークフローの Environment Variables |

## Secret と Variable の使い分け（GitHub Actions）

- パスワード・トークン・鍵など漏洩してはいけないもの → **Secrets**
- `MATCH_TYPE` や `APP_IDENTIFIER` のように漏洩しても実害が少ない設定値 → **Variables**（ワークフローファイル内で `${{ vars.XXX }}` として参照）
