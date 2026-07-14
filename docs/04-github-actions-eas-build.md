# 4-A. EAS Cloud Build on GHA

ワークフロー: `[.github/workflows/eas-build.yml](../.github/workflows/eas-build.yml)`

## セットアップ

1. [expo.dev](https://expo.dev) で Access Token を発行する
2. `EXPO_TOKEN` を GitHub Secrets に登録する

| 名前 | 設定場所 |
|---|---|
| `EXPO_TOKEN` | GitHub Secrets |

```bash
# UI: Settings → Secrets and variables → Actions
# CLI:
gh secret set EXPO_TOKEN --body "your-expo-token"
```

TestFlight 提出（`submit: true`）を使う場合は `eas.json` の `submit.production` も設定してください。詳細は [docs/secrets-and-env.md](./secrets-and-env.md) の **4-A** を参照。

## 実行

1. `main` ブランチへの push で自動実行される
2. または GitHub Actions → **EAS Build** → **Run workflow** で手動実行する
  - `platform`: `ios` / `android` / `all`
  - `profile`: ビルドプロファイル（デフォルト `production`）
  - `submit`: `true` でビルド完了後に `eas submit` も実行

## TestFlight へアップロード

1. 手動実行時に `submit: true` を指定する

```bash
npx eas-cli submit --platform ios --latest --profile production --non-interactive
```

詳細は [docs/secrets-and-env.md](./secrets-and-env.md) の **4-A** を参照。
