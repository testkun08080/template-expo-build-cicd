# 1. Local EAS Build

## セットアップ

1. `npm install`
2. `npm install -g eas-cli`（または `npx eas-cli` を都度使う）
3. `eas login`
4. `eas.json` の `submit.production` に Apple ID / ASC App ID / Team ID を設定（本番値はコミットしない）

```bash
npm install
npm install -g eas-cli
eas login
```

必要な環境変数の一覧は [docs/secrets-and-env.md](./secrets-and-env.md) の **1. Local EAS Build** を参照。

## ローカルビルド

```bash
# iOS
npx eas-cli build --profile production --platform ios --local

# Android
npx eas-cli build --profile production --platform android --local
```

## TestFlight へアップロード

1. ローカルで `.ipa` を生成する

```bash
npx eas-cli build --profile production --platform ios --local
```

2. `eas submit` でアップロードする

```bash
npx eas-cli submit --platform ios --path ./build-XXXXXXXX.ipa --profile production

# 対話なし
npx eas-cli submit --platform ios --path ./build-XXXXXXXX.ipa --profile production --non-interactive
```

3. App Store Connect → **TestFlight** → **Builds** で Processing 完了を確認する
4. **Internal Testing** グループにビルドを割り当てる
