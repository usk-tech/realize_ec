# realize_EC

複数ブランドを単一リポジトリで運用する EC プラットフォーム

## 概要

realize_EC は、Rails 8 + Solidus を使用した EC サイトです。
1つのリポジトリで3つの異なるブランドを運用できるマルチストア構成になっています。

### 対応ストア

| ストア名 | 説明 | ポート | 絵文字 |
|---------|------|--------|--------|
| **radika** | 本格インドカレーをご家庭で | 3000 | 🍛 |
| **shrimpshells** | ハワイの味を冷凍でお届け | 3001 | 🦐 |
| **khukh_khuleg** | モンゴルの伝統料理 | 3002 | 🥟 |

## 技術スタック

- **Ruby**: 3.3+
- **Rails**: 8.0.0
- **Database**: PostgreSQL 14+
- **EC Engine**: Solidus 4.6.2
- **認証**: solidus_auth_devise
- **決済**: Stripe (ストア別アカウント)
- **開発環境**: Docker + docker-compose
- **デプロイ**: Kamal 2 (予定)

### Rails 8 の新機能を活用
- Solid Queue (ジョブ処理 - Redis不要)
- Solid Cache (キャッシュ - Redis不要)
- Solid Cable (WebSocket - Redis不要)

## 開発環境のセットアップ

### 前提条件

- Docker & docker-compose がインストール済み
- Git がインストール済み

### ストアの起動方法

各ストアは独立したポートと DB で起動します。

```bash
# radika を起動 (http://localhost:3000)
./bin/start_store.sh radika

# shrimpshells を起動 (http://localhost:3001)
./bin/start_store.sh shrimpshells

# khukh_khuleg を起動 (http://localhost:3002)
./bin/start_store.sh khukh_khuleg
```

### 環境変数

各ストアの設定は `.env.{store_name}` で管理:
- `.env.radika`
- `.env.shrimpshells`
- `.env.khukh_khuleg`

## プロジェクト構成

### ストア切り替えの仕組み

環境変数 `STORE_NAME` でストアを切り替えます。

```ruby
# config/initializers/store_config.rb
STORE_NAME = ENV.fetch('STORE_NAME', 'radika').to_sym

STORE_CONFIG = {
  radika: { ... },
  shrimpshells: { ... },
  khukh_khuleg: { ... }
}
```

### Stripe 設定

ストアごとに異なる Stripe アカウントを使用:
- `config/initializers/stripe_config.rb` で自動切り替え
- API キーは環境変数で管理

## デプロイ (予定)

- **インフラ**: さくら VPS (Ubuntu 22.04, 2GB RAM 推奨)
- **ツール**: Kamal 2
- **構成**: 各ストアを独立したコンテナでデプロイ

## 現在の状態

✅ 完了:
- Rails 8.0 プロジェクト作成
- Solidus 4.6.2 インストール
- Docker 環境構築 (3ストア並行開発対応)
- ストア切り替えスクリプト作成
- 環境変数ファイル作成
- Git リポジトリ初期化

⏳ 次のステップ:
- Docker 起動テスト
- データベースマイグレーション実行
- Solidus 管理画面の動作確認
- Kamal 2 によるデプロイ設定

## 開発メモ

- Rails 8.1 は Solidus 4.6.2 と互換性がないため 8.0 を使用
- Propshaft 使用のため `app/assets/config/manifest.js` を作成
