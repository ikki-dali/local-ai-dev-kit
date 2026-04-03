# Local AI Dev Kit

セキュアなローカルAI開発環境を1コマンドでセットアップ。

データは一切外部に送信されません。全てローカルで完結します。

## 対象

- AIコーディングツールを使いたいが、セキュリティ要件で外部APIが使えない企業
- オフライン環境（飛行機、セキュアルーム等）で開発したい方
- AI利用のコストを抑えたい方

## 要件

- macOS（Apple Silicon: M1/M2/M3/M4/M5）
- RAM 8GB以上（24GB以上推奨。8-16GBでも軽量モデルで動作可能）

## セットアップ

```bash
curl -fsSL https://raw.githubusercontent.com/ikki-dali/local-ai-dev-kit/main/setup.sh | bash
```

## 使い方

### チャットモード

```bash
local-ai
```

ターミナルでAIとチャット。コードの質問、生成、レビューに。

### Claude Code モード

```bash
local-claude
```

Claude Codeと同じインターフェースで、ファイル読み書き・bash実行・コード生成を全てローカルで実行。

## 搭載モデル

| モデル | メモリ | 推奨RAM | 用途 |
|--------|-------|--------|------|
| Gemma 4 26B | ~17GB | 24GB+ | 高性能。単独使用推奨 |
| Gemma 4 E4B | ~10GB | 20GB+ | 中量。他アプリと共存可 |
| Gemma 4 E2B | ~2GB | 16GB+ | 軽量。16GB Macでも快適 |

全モデル Apache 2.0 ライセンス（Google DeepMind製、商用利用可）。

## セキュリティ

- 全ての推論処理はローカルMac上で完結
- インターネット接続不要（モデルDL後）
- 入力データ・生成コードは外部に一切送信されない
- モデルはApache 2.0ライセンスで監査可能

## 提供

Cradle Inc. (crdl.co.jp)

セットアップ支援・カスタマイズ・研修についてはお問い合わせください。
