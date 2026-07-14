# Secrets / 環境変数 一覧

このテンプレートで使う機密情報・設定値の置き場所と設定方法をまとめたドキュメントです。**実際の値は絶対にコミットしない**でください。

## 環境ファイル・設定先の早見表

| ビルド方法 | ローカル用ファイル | リモート（CI / クラウド） | 詳細ドキュメント |
|---|---|---|---|
| **4-B Fastlane Match（GHA / ローカル）** | `fastlane/.env` | GitHub Secrets / Variables | [05-github-actions-fastlane.md](./05-github-actions-fastlane.md) |
| **1 Local EAS Build** | シェル環境変数 + `eas.json` | — | [01-local-eas-build.md](./01-local-eas-build.md) |
| **2 EAS Cloud Build** | — | EAS Secrets + `eas.json` | [02-eas-cloud-build.md](./02-eas-cloud-build.md) |
| **3 Xcode Cloud** | — | Xcode Cloud の Environment Variables | [03-xcode-cloud.md](./03-xcode-cloud.md) |
| **4-A EAS on GHA** | — | GitHub Secrets + `eas.json` | [04-github-actions-eas-build.md](./04-github-actions-eas-build.md) |

### コミットしてよいファイル vs してはいけないファイル

| ファイル | コミット | 内容 |
|---|---|---|
| `fastlane/.env.example` | ○ | キー名のテンプレート（値は空） |
| `fastlane/.env` | **×** | 実際の機密値（`.gitignore` 対象） |
| `eas.json` | ○ | ビルドプロファイル。`submit.production` の Apple ID 等は **プレースホルダ** のままにし、本番値はコミットしない |
| `app.json` | ○ | Bundle ID・スキーム名など（機密情報は含めない） |
| `*.p8` / `*.jks` / `google-service-account.json` | **×** | 鍵ファイル（`.gitignore` 対象） |

---

## ローカル環境ファイル: `fastlane/.env`

Fastlane Match ビルド（方法 4-B）のローカル実行では、**`fastlane/.env` が唯一の環境ファイル**です。

```bash
cp fastlane/.env.example fastlane/.env
# エディタで実際の値を入力
```

`bundle exec fastlane` 実行時に fastlane が自動で `fastlane/.env` を読み込みます（`dotenv` 経由）。

### `fastlane/.env` に書くキー

| キー | 必須 | 用途 |
|---|---|---|
| `MATCH_GIT_URL` | ○ | 証明書用 Git リポジトリの URL |
| `MATCH_PASSWORD` | ○ | match の暗号化パスワード |
| `MATCH_TYPE` | △ | `appstore`（デフォルト）/ `development` 等 |
| `APP_IDENTIFIER` | △ | Bundle ID（未設定時は `app.json` のデフォルト値） |
| `APPLE_ID` | ○ | Apple ID |
| `APPLE_TEAM_ID` | ○ | Apple Developer Team ID |
| `APP_STORE_CONNECT_API_KEY_ID` | △ | TestFlight 提出時 |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | △ | TestFlight 提出時 |
| `APP_STORE_CONNECT_API_KEY_PATH` | △ | ローカル: `.p8` ファイルのパス |
| `APP_STORE_CONNECT_API_KEY_P8` | △ | CI 用 base64（ローカルでは `PATH` を推奨） |
| `ANDROID_KEYSTORE_*` | △ | Android fastlane ビルド時 |

`EXPO_TOKEN` は EAS ビルド用で、fastlane レーンでは不要です。

---

## GitHub Actions の設定（Secrets / Variables）

方法 **4-A** と **4-B** で GitHub に登録する値です。UI でも CLI でも設定できます。

### UI で設定する

リポジトリ → **Settings** → **Secrets and variables** → **Actions**

- **Secrets** タブ: パスワード・トークン・鍵
- **Variables** タブ: Bundle ID など漏洩しても実害が少ない設定値

### CLI で設定する（`gh`）

[GitHub CLI](https://cli.github.com/) がインストール済みで、`gh auth login` 済みであること。リポジトリの admin 権限が必要です。

```bash
# 現在のリポジトリで作業（または --repo owner/repo を付ける）

# --- Secrets（機密情報）---
gh secret set MATCH_PASSWORD --body "your-match-password"
gh secret set MATCH_GIT_URL --body "https://github.com/your-org/ios-certificates.git"
gh secret set APPLE_TEAM_ID --body "XXXXXXXXXX"
gh secret set APPLE_ID --body "you@example.com"

# HTTPS + PAT で証明書リポにアクセスする場合
gh secret set MATCH_GIT_BASIC_AUTHORIZATION --body "$(echo -n 'username:ghp_xxx' | base64)"

# App Store Connect API Key（TestFlight 提出）
gh secret set APP_STORE_CONNECT_API_KEY_ID --body "3P6949Z9V8"
gh secret set APP_STORE_CONNECT_API_KEY_ISSUER_ID --body "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
gh secret set APP_STORE_CONNECT_API_KEY_P8 < <(base64 -i AuthKey_XXXXX.p8 | tr -d '\n')

# EAS on GHA（方法 4-A）
gh secret set EXPO_TOKEN --body "your-expo-token"

# --- Variables（非機密の設定値）---
gh variable set APP_IDENTIFIER --body "com.testkun08080.template-expo-build"
gh variable set SCHEME_NAME --body "templateexpobuild"
gh variable set MATCH_TYPE --body "appstore"
```

**一覧・削除**

```bash
gh secret list
gh variable list
gh secret delete OLD_SECRET
```

**注意**

- Secret は設定後に値を読み戻せません。誤設定したら上書きしてください。
- `gh secret set -f fastlane/.env` で一括登録できますが、`MATCH_TYPE` など Variables 向けのキーも Secret になってしまうため、**Secrets と Variables は分けて登録する**ことを推奨します。

### Secret と Variable の使い分け

| 種別 | 用途 | ワークフローでの参照 |
|---|---|---|
| **Secrets** | パスワード・トークン・鍵 | `${{ secrets.XXX }}` |
| **Variables** | Bundle ID・スキーム名・match 種別など | `${{ vars.XXX }}` |

---

## ビルド方法ごとの必要な値

### 共通（Apple 開発）

| 名前 | 用途 | 主な設定場所 |
|---|---|---|
| `APP_IDENTIFIER` | iOS Bundle ID | `app.json` / `fastlane/.env` / GHA Variable |
| `APPLE_ID` | Apple ID | `fastlane/.env` / GHA Secret / `eas.json` |
| `APPLE_TEAM_ID` | Apple Developer Team ID | 同上 |
| `SCHEME_NAME` | Xcode スキーム名（通常 `app.json` の `scheme` と同じ） | GHA Variable / 環境変数 |

---

### 1. Local EAS Build

ローカル Mac で `eas build --local` を実行します。証明書は手元の Keychain か EAS credentials で管理します。

| 名前 | 用途 | 設定場所 |
|---|---|---|
| `eas.json` の `submit.production.ios` | TestFlight 提出用（Apple ID / ASC App ID / Team ID） | `eas.json`（機密はプレースホルダのまま、本番値はコミットしない） |
| `EXPO_APPLE_APP_SPECIFIC_PASSWORD` | Apple ID 認証時の App 専用パスワード | シェル環境変数（API Key 使用時は不要） |
| App Store Connect API Key 環境変数 | `eas submit` の API Key 認証 | シェル環境変数 |

```bash
# 例: シェルに一時的に export して submit
export EXPO_APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"
npx eas-cli submit --platform ios --path ./build-XXXXXXXX.ipa --profile production --non-interactive
```

---

### 2. EAS Cloud Build

| 名前 | 用途 | 設定場所 |
|---|---|---|
| EAS Secret（`eas secret:create`） | ビルド内で使う機密環境変数 | [EAS ダッシュボード](https://expo.dev) / CLI |
| `eas.json` の `submit.production` | TestFlight / Play Store 提出 | `eas.json` |
| App Store Connect API Key | `eas submit` の代替認証 | EAS Secret または環境変数 |

```bash
# EAS Secret の登録例
eas secret:create --name EXPO_TOKEN --value "xxx" --type string
```

TestFlight 提出: `eas submit --platform ios --latest --profile production`

---

### 3. Xcode Cloud

TestFlight 配信は Post-Action で自動実行されるため、**TestFlight 専用の Secret は通常不要**です。Xcode Managed Signing により証明書関連の Secret も不要です。

| 名前 | 用途 | 設定場所 |
|---|---|---|
| プライベート npm レジストリのトークン等 | `npm ci` がプライベートパッケージに依存する場合 | Xcode Cloud ワークフローの Environment Variables |

---

### 4-A. EAS Cloud Build on GHA

ワークフロー: [`.github/workflows/eas-build.yml`](../.github/workflows/eas-build.yml)

| 名前 | 種別 | 用途 |
|---|---|---|
| `EXPO_TOKEN` | Secret | EAS への API 認証トークン |
| `eas.json` の `submit.production` | ファイル | TestFlight 提出（`submit: true` 時） |

```bash
gh secret set EXPO_TOKEN --body "your-expo-token"
```

手動実行で `submit: true` にするとビルド後に `eas submit` も実行されます。詳細は [04-github-actions-eas-build.md](./04-github-actions-eas-build.md)。

---

### 4-B. Fastlane Match Build on GHA

ワークフロー: [`.github/workflows/ios-fastlane-match-build.yml`](../.github/workflows/ios-fastlane-match-build.yml)

証明書用リポジトリの初回作成は **管理者のみ** が行います。参加者は共有された値を `fastlane/.env`（ローカル）または GitHub Secrets / Variables（CI）に設定します。手順の詳細は [05-github-actions-fastlane.md](./05-github-actions-fastlane.md)。

#### GitHub Secrets（機密情報）

| 名前 | 用途 | 誰が設定 | ローカル対応キー |
|---|---|---|---|
| `MATCH_GIT_URL` | 証明書用 Git リポジトリ URL | 管理者 | `MATCH_GIT_URL` |
| `MATCH_PASSWORD` | match の暗号化パスワード | 管理者 | `MATCH_PASSWORD` |
| `MATCH_GIT_BASIC_AUTHORIZATION` | HTTPS + PAT の `base64(user:token)` | 管理者 | ローカルでは PAT を Git に直接設定 |
| `APPLE_ID` | Apple ID | 全員 | `APPLE_ID` |
| `APPLE_TEAM_ID` | Team ID | 全員 | `APPLE_TEAM_ID` |
| `APP_STORE_CONNECT_API_KEY_ID` | ASC API Key ID | 提出権限者 | 同名 |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | ASC API Key Issuer ID | 提出権限者 | 同名 |
| `APP_STORE_CONNECT_API_KEY_P8` | `.p8` を base64 化（改行なし） | 提出権限者 | ローカルは `APP_STORE_CONNECT_API_KEY_PATH` |
| `ANDROID_KEYSTORE_BASE64` | Android keystore（base64） | 管理者 | 同名 |
| `ANDROID_KEYSTORE_PASSWORD` | keystore パスワード | 管理者 | 同名 |
| `ANDROID_KEY_ALIAS` | キーエイリアス | 管理者 | 同名 |
| `ANDROID_KEY_PASSWORD` | キーパスワード | 管理者 | 同名 |

#### GitHub Variables（非機密）

| 名前 | 推奨値 | ローカル対応キー |
|---|---|---|
| `APP_IDENTIFIER` | `com.testkun08080.template-expo-build` | `APP_IDENTIFIER` |
| `SCHEME_NAME` | `templateexpobuild` | 環境変数 `SCHEME_NAME` |
| `MATCH_TYPE` | `appstore` | `MATCH_TYPE` |

未設定の Variable はワークフロー内のデフォルト値が使われます（`APP_IDENTIFIER` / `SCHEME_NAME` / `MATCH_TYPE`）。

#### ローカルと CI の対応表

| 用途 | ローカル（`fastlane/.env`） | CI（GitHub） |
|---|---|---|
| 証明書リポジトリ | `MATCH_GIT_URL` | Secret `MATCH_GIT_URL` |
| match パスワード | `MATCH_PASSWORD` | Secret `MATCH_PASSWORD` |
| 証明書リポへのアクセス | PAT（Git の HTTPS 設定） | Secret `MATCH_GIT_BASIC_AUTHORIZATION` |
| TestFlight 提出 | `APP_STORE_CONNECT_API_KEY_PATH`（.p8 パス） | Secret `APP_STORE_CONNECT_API_KEY_P8`（base64） |
| ビルド番号 | `BUILD_NUMBER`（任意） | `github.run_number` を自動設定 |
| Bundle ID | `APP_IDENTIFIER` | Variable `APP_IDENTIFIER` |

#### API キーの base64 化

```bash
base64 -i AuthKey_XXXXX.p8 | tr -d '\n'
```

出力を `APP_STORE_CONNECT_API_KEY_P8` Secret に設定します。

---

## 新規プロジェクト開始時のチェックリスト

1. `app.json` の `name` / `slug` / `ios.bundleIdentifier` / `android.package` / `extra.eas.projectId` を自分の値に変更
2. `eas.json` の `submit.production` プレースホルダを自分の Apple 情報に変更（**コミットする場合はダミー値のまま**にし、本番値は Secrets 側で管理）
3. 使うビルド方法のドキュメントを読み、上表の設定先に値を登録
4. Fastlane を使う場合: `cp fastlane/.env.example fastlane/.env` して値を入力
5. GHA を使う場合: `gh secret set` / `gh variable set` で登録（または UI）
6. `npm install` して動作確認
