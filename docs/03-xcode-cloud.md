# 3. Xcode Cloud Build

Apple 公式の CI/CD である Xcode Cloud を使ったビルド方法です。
App Store Connect と統合されており、TestFlight への配信まで GUI ベースで完結します。
macOS ランナーを自前で用意する必要がありません。

## 前提となる注意点（CNG との関係）

このテンプレートは通常、`ios/` `android/` フォルダを `.gitignore` している「Continuous Native Generation（CNG）」方式です（[docs/01](./01-local-eas-build.md) 参照）。

しかし Xcode Cloud は **ワークフローを作成する時点で、リポジトリ内に実際の `.xcodeproj`（または `.xcworkspace`）とスキームが存在すること** を前提に、App Store Connect の UI 上でプロジェクト・スキームを選択させます。そのため、運用は次の2通りから選びます。

### 方式A: 一時的に prebuild してワークフロー作成 → 以後は ci_post_clone.sh に任せる（推奨・このテンプレートの既定）

1. ローカルで一度だけ実行してコミットする:
   ```bash
   npx expo prebuild --platform ios
   git add -f ios
   git commit -m "chore: temporary ios/ for Xcode Cloud workflow setup"
   git push
   ```
2. App Store Connect → Xcode Cloud でワークフローを作成し、リポジトリ・スキームを選択する（[手順](#ワークフロー作成手順)参照）。
3. ワークフロー作成後、`ios/` を再度 `.gitignore` に戻してコミットから外して構いません（このテンプレートの `.gitignore` は既に `ios/ci_scripts` 以外を無視する設定になっています）。
4. 以後のビルドでは `ios/ci_scripts/ci_post_clone.sh` が clone 直後に `expo prebuild` を再実行し、`ios/` を都度生成します。

### 方式B: `ios/` を通常通りコミットして管理する（Bare workflow 寄り）

Config Plugin での自動生成に頼らず、ネイティブコードを直接触りたい場合はこちら。`ios/` を `.gitignore` から外し、`ios/ci_scripts/ci_post_clone.sh` 内の `expo prebuild` 実行部分を削除して `pod install` だけ残してください（環境変数 `XCODE_CLOUD_SKIP_PREBUILD=true` を Xcode Cloud のワークフロー設定で追加すると、スクリプトを変更せずに prebuild をスキップできます）。

## ワークフロー作成手順

1. Xcode で `ios/xxx.xcworkspace` を開き、Xcode 右上の「Product」→「Xcode Cloud」→「Create Workflow」（もしくは App Store Connect の Xcode Cloud タブから）。
2. リポジトリ（GitHub 連携）とプロジェクト/スキームを選択。
3. Start Condition（例: `main` ブランチへの push、または任意のタグ）を設定。
4. Actions に「Archive」を追加し、Post-Actions に「TestFlight (Internal/External Testing)」を追加。
5. 環境変数が必要な場合は Xcode Cloud のワークフロー設定 → Environment Variables で追加（Secret 指定可能）。npm 用のプライベートレジストリトークンなどをここに設定できる。

## TestFlight へアップロード

Xcode Cloud のワークフロー Post-Action により、Archive 完了後に自動で TestFlight へ配信できます。

### App Store Connect 側の初回準備

1. [App Store Connect](https://appstoreconnect.apple.com/) → **My Apps** → **+** でアプリを作成
2. Bundle ID を `app.json` の `ios.bundleIdentifier` と一致させる
3. **TestFlight** タブで利用規約に同意する（初回のみ）

### Xcode Cloud ワークフロー設定（TestFlight 配信）

ワークフロー作成・編集画面で以下を設定します。

| 設定項目            | 推奨値                                          |
| ------------------- | ----------------------------------------------- |
| **Environment**     | `Production` または `Release`                   |
| **Actions**         | **Archive**（Release 構成）                     |
| **Post-Actions**    | **TestFlight Internal Testing**（まず内部向け） |
| **Start Condition** | `main` への push、または `ios-v*` タグなど      |

外部テスター向けには Post-Actions に **TestFlight External Testing** を追加できます。初回ビルドのみ Beta App Review（通常 24 時間以内）が必要で、以降は即時配布されます。

### ビルドの実行

```bash
# 例: main ブランチへ push するとワークフローが起動
git push origin main

# 例: タグで起動するよう設定した場合
git tag ios-v1.0.0
git push origin ios-v1.0.0
```

ビルドの進捗は Xcode（**Report Navigator** → **Cloud**）または [App Store Connect](https://appstoreconnect.apple.com/) → **Xcode Cloud** で確認できます。

### アップロード後の確認

1. App Store Connect → **TestFlight** → **Builds** でステータスが **Processing** → **Ready to Test** になるまで待つ
2. **Internal Testing** グループ（最大 100 名）にテスターを追加する（Apple Developer Program のチームメンバーが対象、審査不要）
3. 外部テスターには **External Testing** グループを作成し、ビルドを割り当てる

### トラブルシュート

| 症状                               | 対処                                                                                  |
| ---------------------------------- | ------------------------------------------------------------------------------------- |
| `ci_post_clone.sh` で失敗          | ビルドログで Node / `npm ci` / `expo prebuild` / `pod install` のどこで止まったか確認 |
| 署名エラー                         | Xcode Cloud ワークフローで **Xcode Managed Signing** を有効化する                     |
| TestFlight にビルドが出ない        | Post-Actions に TestFlight が追加されているか、Archive が成功しているか確認           |
| prebuild をスキップしたい（方式B） | ワークフローの Environment Variables に `XCODE_CLOUD_SKIP_PREBUILD=true` を設定       |

## `ci_scripts/ci_post_clone.sh` の役割

このリポジトリの `ios/ci_scripts/ci_post_clone.sh` は次を行います。

1. Homebrew で Node.js をインストール（Xcode Cloud のイメージには Node が入っていないため）
2. `npm ci` で依存関係をインストール
3. （方式Aの場合）`npx expo prebuild --platform ios` でネイティブプロジェクトを再生成
4. `pod install` で CocoaPods 依存関係を解決

Xcode Cloud は `ci_post_clone.sh` / `ci_post_xcodebuild.sh` などのファイル名を自動検出して指定のタイミングで実行するため、ファイル名・配置場所（`ios/ci_scripts/`）を変えないでください。また、実行権限（`chmod +x`）が付与されている必要があります。

## 証明書について

Xcode Cloud は Apple の証明書管理を **自動（Xcode Managed Signing）** で行うのが基本です。[docs/04](./04-github-actions-eas-fastlane.md) の fastlane match を既に運用している場合でも、Xcode Cloud 上では自動署名に任せるのがシンプルです（Xcode Cloud は Apple 純正のためチーム間の証明書共有もApple側で完結します）。手動署名にこだわる場合は Xcode Cloud のワークフロー設定で証明書・プロファイルをアップロードすることも可能です。

## 制限事項

- Xcode Cloud は iOS/macOS/tvOS/watchOS 向けのみで、Android ビルドは行えません（Android は [docs/02](./02-eas-cloud-build.md) や [docs/04](./04-github-actions-eas-fastlane.md) の Android レーンを利用）。
- 無料枠は月あたりのビルド分数に上限があります（Apple Developer Program の契約内容によって異なるため、最新情報は App Store Connect の Xcode Cloud 利用状況画面で確認してください）。
