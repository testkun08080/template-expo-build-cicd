# 1. Local EAS Build

手元の Mac（iOS の場合は必須）や Linux/Windows（Android のみ）上で、EAS Build と同じ手順を `--local` フラグ付きで実行する方法です。クラウドのビルドサーバーを使わず、本番相当のビルドをデバッグしたい時に有効です。

## セットアップ

```bash
npm install
npm install -g eas-cli   # または npx eas-cli を都度使う
eas login
```

## ローカルビルド

```bash
# iOS（macOS + Xcode 必須）
npx eas-cli build --profile production --platform ios --local

# Android
npx eas-cli build --profile production --platform android --local
```

### 注意点

- `--local` 実行時、`eas.json` の `node` / `image` / `fastlane` / `cocoapods` / `ndk` などのバージョン指定は無視されます（手元にインストール済みのバージョンがそのまま使われます）。
- ビルドキャッシュは効きません。
- EAS の Secret 変数（Visibility: Secret）は参照できません。`.env.local` などローカルの環境変数を使ってください。
- iOS の場合、事前に証明書・プロビジョニングプロファイルがローカルの Keychain / Xcode に設定されている必要があります。`fastlane match` を使っている場合は [docs/04](./04-github-actions-eas-fastlane.md) の match セクションを参照し、先に `bundle exec fastlane match appstore` などを実行してから local build してください。
- このテンプレートは Continuous Native Generation（CNG）方式のため `ios/` `android/` は `.gitignore` 対象です。`eas build --local` 実行時に自動生成されます。

## TestFlight へアップロード

ローカルビルドで生成した `.ipa` を App Store Connect にアップロードし、TestFlight で配布する手順です。

### 前提

1. [App Store Connect](https://appstoreconnect.apple.com/) でアプリレコードを作成済みであること（Bundle ID は `app.json` の `ios.bundleIdentifier` と一致させる）
2. Distribution 証明書と App Store 用プロビジョニングプロファイルが手元に設定済みであること（`eas credentials` または [docs/04](./04-github-actions-eas-fastlane.md) の `fastlane match appstore`）
3. `eas.json` の `submit.production.ios` に Apple ID / ASC App ID / Team ID を設定済みであること（[docs/secrets-and-env.md](./secrets-and-env.md) 参照）

### 手順

```bash
# 1. ローカルで .ipa を生成
npx eas-cli build --profile production --platform ios --local

# 2. 生成された .ipa を TestFlight へアップロード
npx eas-cli submit --platform ios --path ./build-XXXXXXXX.ipa --profile production

# CI やスクリプト向け（対話なし）
npx eas-cli submit --platform ios --path ./build-XXXXXXXX.ipa --profile production --non-interactive
```

- ビルド完了時に表示される `.ipa` のパスを `--path` に指定する
- App Store Connect API Key を使う場合は `EXPO_APPLE_APP_STORE_CONNECT_API_KEY` 等の環境変数を設定すれば、App 専用パスワードは不要（詳細は [docs/secrets-and-env.md](./secrets-and-env.md)）

### アップロード後の確認

1. App Store Connect → **TestFlight** → **Builds** でステータスが **Processing** → **Ready to Submit**（または **Testing**）になるまで待つ（通常 5〜30 分）
2. **Internal Testing** グループにビルドを割り当て、チームメンバーを追加する（内部テスターは審査不要で即時配布可能）
3. 外部テスター向けには **External Testing** グループを作成する（初回ビルドのみ Beta App Review が必要）

## 前提ツール

| ツール | 用途 |
|---|---|
| Node.js 20.x | プロジェクト全般 |
| Xcode（最新安定版） | iOS ビルド |
| CocoaPods | iOS ネイティブ依存管理 |
| Android Studio / Android SDK・NDK | Android ビルド |
| `eas-cli`（`npx eas-cli` でも可） | EAS Build のローカル実行・TestFlight 提出 |
