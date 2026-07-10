# 4. GitHub Actions（EAS Cloud Build + Fastlane Match Build）

GitHub Actions 上でビルド〜配信を自動化する方法です。2つの CI パスから選べます。

| パス | 概要 | ワークフロー |
|---|---|---|
| **4-A. EAS Cloud Build on GHA** | GHA から EAS クラウドビルドをキック（ubuntu ランナー） | [`.github/workflows/eas-build.yml`](../.github/workflows/eas-build.yml) |
| **4-B. Fastlane Match Build on GHA** | macOS ランナー上で prebuild → match → gym → TestFlight | [`.github/workflows/ios-fastlane-match-build.yml`](../.github/workflows/ios-fastlane-match-build.yml) |

## どちらを選ぶか

| 観点 | 4-A EAS on GHA | 4-B Fastlane on GHA |
|---|---|---|
| ランナー | ubuntu（安価） | macos（高コスト） |
| 証明書 | EAS 管理 | match 専用 Git リポ |
| Android | 対応 | Fastfile に Android レーンあり |
| カスタムネイティブ | EAS ビルド環境依存 | prebuild + gym で完全制御 |

---

## 4-A. EAS Cloud Build on GHA

手元で `eas build` を叩く代わりに、push や手動実行で EAS Cloud Build をキックし、オプションで TestFlight 提出まで行います。

### 必要な Secret

| 名前 | 用途 | 設定場所 |
|---|---|---|
| `EXPO_TOKEN` | EAS への API 認証トークン | GitHub Secrets |

`EXPO_TOKEN` は https://expo.dev/accounts/[account]/settings/access-tokens から発行してください。

### トリガー

- **`main` ブランチへの push**: デフォルト設定（`ios` / `production`）で EAS Build をキック
- **`workflow_dispatch`（手動実行）**: 以下の入力を指定可能
  - `platform`: `ios` / `android` / `all`
  - `profile`: EAS ビルドプロファイル（デフォルト `production`）
  - `submit`: `true` にするとビルド完了後に `eas submit` も実行

### 手動実行例

GitHub Actions → **EAS Build** → **Run workflow** → 必要に応じて `submit: true` を指定。

### TestFlight へアップロード

手動実行時に `submit: true` を指定すると、ビルド完了後に以下が実行されます。

```bash
npx eas-cli submit --platform ios --latest --profile production --non-interactive
```

`eas.json` の `submit.production.ios` 設定と App Store Connect API Key（EAS Secret または環境変数）が必要です。詳細は [docs/secrets-and-env.md](./secrets-and-env.md) および [docs/02-eas-cloud-build.md](./02-eas-cloud-build.md) を参照してください。

---

## 4-B. Fastlane Match Build on GHA

証明書・プロビジョニングプロファイルを、アプリ本体とは別の非公開 Git リポジトリで一元管理し（fastlane match の標準的な運用方法）、GitHub Actions の macOS ランナー上でネイティブビルド〜TestFlight 配信まで行う方法です。EAS を使わず、自前の CI で完結させたいチーム向けです。

### 全体構成

```
アプリリポジトリ（このテンプレート）
├─ fastlane/Matchfile ── 証明書リポジトリの URL・種別を指定
├─ fastlane/Fastfile   ── prebuild → match → build → TestFlight upload のレーン
└─ .github/workflows/ios-fastlane-match-build.yml

証明書専用リポジトリ（非公開・別リポジトリ）
└─ match が生成する暗号化済み証明書・プロビジョニングプロファイル一式
   （match init で自動生成されるので、事前に空の非公開リポジトリを用意するだけでよい）
```

### 手順

#### 1. 証明書専用リポジトリを作る

GitHub 上に **空の非公開リポジトリ**（例: `your-org/ios-certificates`）を作成します。中身は match が自動で作るので、README だけあれば十分です。

#### 2. ローカルで match を初期化する

```bash
cd fastlane
bundle install
MATCH_GIT_URL=git@github.com:your-org/ios-certificates.git \
APP_IDENTIFIER=com.example.expomultibuildtemplate \
APPLE_ID=you@example.com \
APPLE_TEAM_ID=XXXXXXXXXX \
bundle exec fastlane ios certificates_renew
```

初回実行時に match が証明書・プロファイルを作成し、`MATCH_PASSWORD` で暗号化して証明書リポジトリに push します。このパスワードは絶対に紛失しないこと（紛失した場合は証明書の作り直しが必要）。

#### 3. 証明書リポジトリへの CI アクセスを用意する

CI（GitHub Actions）が証明書リポジトリを clone できるよう、以下のいずれかを設定します。

- **Deploy Key（推奨・読み取り専用）**: 証明書リポジトリ側で Deploy Key を発行し、秘密鍵をアプリリポジトリの Secret `MATCH_GIT_SSH_PRIVATE_KEY` に登録。
- **Personal Access Token（HTTPS）**: `user:token` を base64 化し `MATCH_GIT_BASIC_AUTHORIZATION` Secret に登録。

#### 4. アプリリポジトリに Secrets / Variables を設定する

`docs/secrets-and-env.md` の **4. GitHub Actions → 4-B** 一覧を参照し、GitHub の Settings → Secrets and variables → Actions に登録してください。

#### 5. ワークフローを実行する

- タグ `ios-v*` を push すると自動で `beta` レーンが実行される
- または Actions タブから `workflow_dispatch` で手動実行（`lane` に `build` または `beta` を指定）

### TestFlight へアップロード

#### 前提: App Store Connect API Key

TestFlight へのアップロードには App Store Connect API Key が必要です（CI では Apple ID ログインは使えません）。

1. [App Store Connect](https://appstoreconnect.apple.com/) → **Users and Access** → **Integrations** → **App Store Connect API**
2. **Team Keys** でキーを生成し、`.p8` ファイルをダウンロード（再ダウンロード不可のため保管すること）
3. 以下を GitHub Secrets に登録する（[docs/secrets-and-env.md](./secrets-and-env.md) 参照）:
   - `APP_STORE_CONNECT_API_KEY_ID` — Key ID
   - `APP_STORE_CONNECT_API_KEY_ISSUER_ID` — Issuer ID
   - `APP_STORE_CONNECT_API_KEY_P8` — `.p8` ファイルの中身（base64 エンコード推奨）

#### ローカルで TestFlight へアップロード

```bash
cd fastlane
bundle install

# 環境変数を設定（例）
export MATCH_GIT_URL=git@github.com:your-org/ios-certificates.git
export MATCH_PASSWORD=your-match-password
export MATCH_TYPE=appstore
export APP_IDENTIFIER=com.testkun08080.template-expo-build
export APPLE_ID=you@example.com
export APPLE_TEAM_ID=XXXXXXXXXX
export APP_STORE_CONNECT_API_KEY_ID=XXXXXXXXXX
export APP_STORE_CONNECT_API_KEY_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
export APP_STORE_CONNECT_API_KEY_P8=$(base64 -i AuthKey_XXXXX.p8)

# ビルドのみ（.ipa 生成）
bundle exec fastlane ios build

# ビルド + TestFlight アップロード
bundle exec fastlane ios beta
```

#### CI で TestFlight へアップロード

```bash
# タグ push で自動実行（beta レーン = ビルド + TestFlight）
git tag ios-v1.0.0
git push origin ios-v1.0.0
```

手動実行: GitHub Actions → **iOS Fastlane Match Build** → **Run workflow** → `lane` に `beta` を指定。

`ios beta` レーンは次を順に実行します:

1. `expo prebuild --platform ios`
2. `pod install`
3. `match`（readonly）で証明書を取得
4. `gym` で `.ipa` を生成
5. `upload_to_testflight` で App Store Connect にアップロード

#### アップロード後の確認

1. App Store Connect → **TestFlight** → **Builds** で Processing 完了を待つ
2. **Internal Testing** グループにビルドを割り当て、テスターを追加する

### Fastfile のレーン構成

| レーン | 内容 |
|---|---|
| `ios certificates` | 証明書を読み取り専用で同期（`readonly: true`） |
| `ios certificates_renew` | 証明書を新規作成・更新（ローカルの管理者のみが実行） |
| `ios build` | `expo prebuild` → Pod install → match（readonly）→ `.ipa` 生成 |
| `ios beta` | `build` に続けて TestFlight へアップロード |
| `android build` | Android 側のプレビルド + keystore 復元 + Release バンドル生成 |

### Android の証明書について

Android は Apple の Developer Portal のような集中管理の仕組みがないため、多くのチームは **keystore ファイルを base64 化して GitHub Secrets に直接格納**する方式を使います（`ANDROID_KEYSTORE_BASE64` など）。`fastlane/Fastfile` の `android build` レーンはこの方式を前提にしています。

### スキーム名について

`fastlane/Fastfile` は `app.json` の `expo.scheme`（本テンプレートでは `templateexpobuild`）をデフォルトのスキーム名として使います。`expo prebuild` 実行後に生成される実際のスキーム名と異なる場合は、CI の env に `SCHEME_NAME` を追加して上書きしてください。
