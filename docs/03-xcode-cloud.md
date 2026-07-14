# 3. Xcode Cloud Build

`ios/` 全体は CNG のため `.gitignore` 対象です。コミットするのは `ios/ci_scripts/` のみで、ビルド時に `ci_post_clone.sh` が `expo prebuild` を実行します。

## 初回セットアップ

1. `ios/ci_scripts/ci_post_clone.sh` がリポジトリに含まれていることを確認する（このテンプレートでは既にコミット済み）
2. ワークフロー作成のため、ローカルで一時的に prebuild する（**`ios/` はコミットしない**）

```bash
npx expo prebuild --platform ios
```

3. Xcode で `ios/*.xcworkspace` を開き、**Product** → **Xcode Cloud** → **Create Workflow** でワークフローを作成する（[ワークフロー作成](#ワークフロー作成)参照）
4. 作成後、ローカルの `ios/` 生成物はコミットせず破棄してよい（`ci_scripts/` だけ残す）

## ワークフロー作成

1. Xcode で `ios/*.xcworkspace` を開く
2. **Product** → **Xcode Cloud** → **Create Workflow**
3. リポジトリ（GitHub 連携）とプロジェクト・スキームを選択する
4. Start Condition を設定する（例: `main` への push、またはタグ）
5. Actions に **Archive** を追加し、Post-Actions に **TestFlight** を追加する
6. 環境変数を設定する（Xcode Cloud ワークフロー設定 → Environment Variables）

必要な環境変数は [docs/secrets-and-env.md](./secrets-and-env.md) の **3. Xcode Cloud** を参照。

| 設定項目 | 値 |
|---|---|
| **Environment** | `Production` または `Release` |
| **Actions** | **Archive**（Release 構成） |
| **Post-Actions** | **TestFlight Internal Testing** |
| **Start Condition** | `main` への push、または `ios-v*` タグ |

## App Store Connect 初回準備

1. App Store Connect → **My Apps** → **+** でアプリを作成する（Bundle ID は `app.json` の `ios.bundleIdentifier` と一致）
2. **TestFlight** タブで利用規約に同意する

## ビルド実行

```bash
# main ブランチへ push
git push origin main

# タグで起動するよう設定した場合
git tag ios-v1.0.0
git push origin ios-v1.0.0
```

Xcode Cloud はクローン後に `ios/ci_scripts/ci_post_clone.sh` を実行し、Node 導入 → `npm ci` → `expo prebuild` → `pod install` まで行います。

## TestFlight 確認

1. App Store Connect → **TestFlight** → **Builds** で Processing 完了を確認する
2. **Internal Testing** グループにテスターを追加する
3. （任意）**External Testing** グループを作成し、ビルドを割り当てる
