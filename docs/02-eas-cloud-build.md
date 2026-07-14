# 2. EAS Cloud Build

## セットアップ

1. `eas-cli` をインストールしてログインする
2. `eas init` でプロジェクトを登録する
3. `eas credentials` で証明書・キーストアを設定する
4. `app.json` の `extra.eas.projectId` を `eas init` で発行された値に置き換える
5. 必要に応じて EAS Secrets を登録する（`eas secret:create`）

```bash
npm install -g eas-cli
eas login
eas init
eas credentials
```

環境変数・Secrets の詳細は [docs/secrets-and-env.md](./secrets-and-env.md) の **2. EAS Cloud Build** を参照。

## ビルド

| プロファイル | 用途 |
|---|---|
| `development` | Dev Client 入りデバッグビルド |
| `preview` | QA・社内配布用 |
| `production` | ストア提出用 |

```bash
npx eas-cli build --profile development --platform all
npx eas-cli build --profile preview --platform all
npx eas-cli build --profile production --platform all
```

## TestFlight へアップロード

1. クラウドでビルドする

```bash
npx eas-cli build --profile production --platform ios
```

2. `eas submit` で提出する

```bash
# 直近のビルドを提出
npx eas-cli submit --platform ios --latest --profile production

# ビルドと提出を一括実行
npx eas-cli build --profile production --platform ios --submit

# 対話なし
npx eas-cli submit --platform ios --latest --profile production --non-interactive
```

3. App Store Connect → **TestFlight** → **Builds** で Processing 完了を確認する
4. **Internal Testing** グループにビルドを割り当て、テスターを追加する
