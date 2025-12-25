# Claude Sonnet 4.5 で realize_EC を実装する具体的フロー
## Day 1-9 実装ワークフロー（ステップバイステップ）

---

## このドキュメントの目的

「Sonnet とペアプロ」を実際に進めるときの **実行フロー** を 9 日分、具体例とともに記載しています。

各 Day の終わりに「どのテンプレを使うか」「何をコミットするか」を示していますので、参考にしてください。

---

## Day 1-2: 基盤セットアップ（Rails 8 + Solidus + Docker）

### やること

1. Rails 8 プロジェクト生成
2. Solidus インストール
3. Docker + docker-compose セットアップ
4. ストア別設定ファイル作成（store_config.rb, stripe_config.rb）
5. GitHub に初期コミット

### Sonnet との進め方

```
【セッション 1: Rails 8 + Solidus 初期化】

1. セッション開始テンプレを貼る
2. Sonnet に確認質問を待つ

Sonnet の確認質問例:
- Solidus のバージョンは「最新」を想定してもいい？
- DB は PostgreSQL 前提？
- 管理画面のカスタマイズは最小限？

3. 以下を答える
「はい、以下で進めてください:
 - Solidus: 最新の Rails 8 対応版
 - DB: PostgreSQL 14+
 - 管理画面は Solidus デフォルト + STORE_NAME 分岐のみ」

4. Sonnet のステップ提案を受ける
   ↓
   - Bundle install コマンド
   - Solidus:install コマンド
   - 初期 DB セットアップ

5. 各ステップをターミナルで実行

6. 「完了した、次へ」と言う
```

### 実装テンプレ（Day 1）

```
あなたは Rails 8 + Solidus + Kamal 2 を使った EC サイト「realize_EC」のペアプロ相方です。

【プロジェクト概要】
- リポジトリ: realize_EC（GitHub）
- 構成: 1つのリポジトリで3ストア（radica, shrimpshells, huhfreg）を Git ブランチ・タグで管理
- 環境変数 STORE_NAME で、ストア別の設定を自動切り替え
- 本番: さくら VPS（Ubuntu 22.04, メモリ 2GB）+ Kamal 2
- 言語: Ruby 3.3.0+, Rails 8.x, Solidus 最新版

【重要な制約】
- PostgreSQL を使用（SQLite は使わない）
- Redis 不要（Solid Queue / Cache / Cable で Postgres ベース）
- Docker + docker-compose（ローカル開発）

【Day 1 今日の目標】
Rails 8 + Solidus をインストール、Docker セットアップして、ローカルで http://localhost:3000 で管理画面に入れるまで

確認質問を 3 つだけ出してから、セットアップコマンドを提案してください。
```

### このセッションで作成されるファイル

- `Gemfile` (Rails 8 + Solidus gem)
- `Dockerfile` (Rails 8 + Kamal 用)
- `docker-compose.yml` (ローカル開発用)
- `config/puma.rb` (Puma 設定)
- `config/initializers/store_config.rb` (ストア名管理)
- `config/initializers/stripe_config.rb` (Stripe キー管理)

### Git コミット

```bash
git add -A
git commit -m "feat: Rails 8 + Solidus 初期化 + Docker セットアップ"
git push origin main
```

---

## Day 2: ローカル3ストア並行開発環境準備

### やること

1. docker-compose.yml を「3ストア同時起動」に対応させる
2. bin/start_store.sh スクリプト作成
3. 各ストアの .env ファイル作成
4. 3 ターミナルで並行起動テスト

### Sonnet との進め方

```
【セッション 2: ローカル開発環境（3ストア並行化）】

テンプレ:

---

あなたは Rails 8 + Solidus + Kamal 2 を使った EC サイト「realize_EC」のペアプロ相方です。

【プロジェクト概要】
...（前回と同じ）

【Day 2 今日の目標】
ローカルで 3 ストア（radica, shrimpshells, huhfreg）を同時に起動して、
- http://localhost:3000 (radica)
- http://localhost:3001 (shrimpshells)
- http://localhost:3002 (huhfreg)
すべてで Solidus 管理画面にアクセスできるようにする

進め方:
1. 確認質問（3 つ以内）
2. docker-compose.yml 修正案
3. bin/start_store.sh スクリプト
4. 各 .env ファイルのテンプレ
5. 起動・動作確認手順

---

このセッション後:
- 各ストアで独立した DB が起動
- 環境変数 STORE_NAME で「どのストアか」が自動分岐
- git checkout feature/radica/xxx → docker-compose up で radica が起動
```

### コマンド参考

```bash
# ターミナル1
export STORE_NAME=radica APP_PORT=3000 DB_PORT=5432
docker-compose up

# ターミナル2
export STORE_NAME=shrimpshells APP_PORT=3001 DB_PORT=5433
docker-compose up

# ターミナル3
export STORE_NAME=huhfreg APP_PORT=3002 DB_PORT=5434
docker-compose up
```

### Git コミット

```bash
git add bin/start_store.sh .env.* docker-compose.yml
git commit -m "feat: ローカル3ストア並行開発環境セットアップ"
git push origin main
```

---

## Day 3-5: 各ストア向け機能実装

### Day 3: radica（ラディカ向け）

```
【セッション 3: radica スパイス度管理機能】

実装テンプレ:

【対象ストア】
STORE_NAME: radica

【対象ブランチ】
git checkout -b feature/radica/add-spice-level

【実装したい機能】
機能名: スパイス度管理（辛さレベル：1-5）
概要: 各商品に「辛さレベル」を設定して、注文時に選択できるようにしたい
ユースケース:
  1. 管理画面で商品登録時に「スパイス度」を選択（1: 甘い ～ 5: 激辛）
  2. フロント側で「スパイス度」に応じた警告表示（5は「激辛注意」）
  3. 注文完了後、スパイス度を Invoice に表示

【既存コードの参考】
- Solidus の Product モデル（spree_products テーブル）
- Solidus の Variant（色やサイズのような「バリエーション」）
- 既存の OrderItem モデル

【お願い】
1. 確認質問（3 つ以内）
2. DB マイグレーション戦略（新カラム？ポリモーフィック関連？）
3. モデル設計
4. 管理画面 UI（Solidus admin の拡張方法）
5. テストの書き方

---

ここまでで一旦区切る？」
```

### Day 4: shrimpshells（シュリンプシェルズ向け）

```
【セッション 4: shrimpshells 冷凍品配送トラッキング】

【対象ストア】
STORE_NAME: shrimpshells

【対象ブランチ】
git checkout -b feature/shrimpshells/frozen-tracking

【実装したい機能】
機能名: 冷凍配送トラッキング
概要: 冷凍便の温度管理・配送状態をリアルタイムで顧客に見せたい
ユースケース:
  1. 注文後、配送業者の温度ロガーデータを API で取得
  2. 「常に -18°C 以下を維持」みたいなバッジを表示
  3. トラッキングページで配送中の温度グラフ表示

【既存コードの参考】
- Solidus の Shipment モデル
- 配送業者 API の仕様（実装ずみ？）

【お願い】
1. 外部 API 呼び出しの設計（webhook vs polling）
2. DB スキーマ（温度ログの保存方法）
3. UI（フロント側の表示）
4. 本番環境でのスケーリング考慮
```

### Day 5: huhfreg（フフフレグ向け）

```
【セッション 5: huhfreg レシピ提案機能】

【対象ストア】
STORE_NAME: huhfreg

【対象ブランチ】
git checkout -b feature/huhfreg/recipe-suggestions

【実装したい機能】
機能名: 購入履歴に基づくレシピ提案
概要: 顧客が購入した食材に応じて「モンゴル料理のレシピ」を提案
ユースケース:
  1. カートに「羊肉」を入れたら「羊肉の準備食」レシピを表示
  2. レシピをクリックすると「足りない調味料」が自動カートに
  3. レシピページに動画リンク（YouTube 埋め込み）

【既存コードの参考】
- Product モデル（カテゴリ分類）
- Solidus の LineItem（カート内容）

【お願い】
1. レシピデータの保存（JSON 型？テーブル？）
2. 提案アルゴリズム（ルールベース？）
3. 「足りない調味料」の自動判定ロジック
4. モバイル UI での見やすさ
```

### 各 Day のコミット

```bash
# Day 3: radica
git add -A
git commit -m "feat: radica スパイス度管理機能 + テスト"
git push origin feature/radica/add-spice-level
# → PR 作成、develop にマージ

# Day 4: shrimpshells
git add -A
git commit -m "feat: shrimpshells 冷凍配送トラッキング + テスト"
git push origin feature/shrimpshells/frozen-tracking
# → PR 作成、develop にマージ

# Day 5: huhfreg
git add -A
git commit -m "feat: huhfreg レシピ提案機能 + テスト"
git push origin feature/huhfreg/recipe-suggestions
# → PR 作成、develop にマージ
```

---

## Day 6-8: 本番準備＆ステージングデプロイ

### Day 6: さくら VPS セットアップ + Kamal 初期化

```
【セッション 6: さくら VPS セットアップ】

このセッションは「Sonnet は不要」（手作業メイン）

1. さくら VPS コントロールパネルで VPS 契約
2. SSH でログイン
3. realize_ec_sakura_vps_guide.md の「Step 1-7」を順番に実行
4. VPS IP アドレスをメモ

確認:
ssh deploy@YOUR_SAKURA_VPS_IP
→ 接続できたら OK

次のセッションで Kamal 設定に進む
```

### Day 7: Kamal 設定＆Docker Hub 連携

```
【セッション 7: Kamal + Docker Hub 設定】

テンプレ:

---

あなたは Rails 8 + Solidus + Kamal 2 を使った EC サイト「realize_EC」のペアプロ相方です。

【プロジェクト概要】
...（いつもと同じ）

【Day 7 今日の目標】
Kamal でワンコマンドデプロイできるようにする

【現在の状況】
- さくら VPS: セットアップ完了（IP: YOUR_SAKURA_VPS_IP）
- deploy ユーザー: 作成済み、SSH キー認証設定済み
- Docker Hub: アカウント作成済み、username と token を取得

【やること】
1. config/deploy.yml を「radica 本番用」に設定
2. .env.production.local に認証情報を設定
3. ローカルで docker build + docker push テスト
4. kamal deploy テスト実行（ステージングで）
5. ロールバック / リスタート の動作確認

【お願い】
1. Kamal 初期化コマンド
2. config/deploy.yml の詳細解説
3. 環境変数の設定方法
4. デプロイ実行コマンド
5. 本番デプロイ前のチェックリスト

---

このセッション終了後:
kamal deploy → ステージング URL で確認可能
```

### Day 8: Solidus 管理画面のカスタマイズ＋テスト

```
【セッション 8: 本番リリース前の QA】

テンプレ:

---

あなたは Rails 8 + Solidus + Kamal 2 を使った EC サイト「realize_EC」のペアプロ相方です。

【Day 8 今日の目標】
ステージング環境（ラディカ）で「本番レベルの QA」をして、リリース判定

【QA 項目】
□ 管理画面で商品登録 → フロント表示で確認
□ 決済フロー（Stripe テストモード）
□ 注文完了メール送信
□ スマホ（iOS Safari, Android Chrome）での動作
□ パフォーマンス（ページロード時間）
□ セキュリティ（SQL インジェクション、CSRF, XSS）

【既知の問題】
- （あれば列挙）

【お願い】
QA テストの「チェックシート」を作成してください

---

Sonnet に:
「本番リリース前の QA テストリストを作成してください。チェック項目は:
- 機能テスト（radica スパイス度, shrimpshells 配送, huhfreg レシピ）
- 決済テスト（Stripe）
- セキュリティテスト
- パフォーマンステスト
- DB 整合性テスト

各項目に『テスト手順』『期待動作』『NG 条件』を記載してください」
```

---

## Day 9: Go Live（本番デプロイ）

### ラディカを本番デプロイ

```bash
# ローカル
git tag radica-v1.0.0
git push origin radica-v1.0.0

# config/deploy.yml の STORE_NAME: radica を確認
kamal deploy

# 本番環境確認
curl https://radica.example.com

# ログ確認
kamal logs -f
```

### デプロイ後の確認

```bash
# DB マイグレーション
kamal app exec --interactive 'bundle exec rails db:migrate RAILS_ENV=production'

# シード実行（本番初回のみ）
kamal app exec --interactive 'bundle exec rails db:seed RAILS_ENV=production'

# Rails console で確認
kamal app exec --interactive 'bundle exec rails console -e production'

> Spree::Store.all
> Spree::Product.count
```

### 本番リリーステンプレ

```
【本番リリース直前チェック】

Sonnet に以下を確認:

「本番デプロイ前の最終確認リスト:

□ git tag は正しいか（radica-v1.0.0）
□ config/deploy.yml の STORE_NAME は radica か
□ 環境変数（RAILS_MASTER_KEY, DATABASE_URL, STRIPE_KEY）は設定済みか
□ DNS は propagate されているか
□ Let's Encrypt 証明書取得できるか
□ ステージングでの QA テストはすべてパスしているか
□ ロールバック手順は理解しているか

上記をすべて確認してから kamal deploy を実行してください」
```

---

## セッション管理まとめ

| Day | セッション | 使うテンプレ | 成果物 |
|-----|---------|---------|------|
| 1 | Rails 8 初期化 | 開始テンプレ | Gemfile, Dockerfile |
| 2 | Docker 3ストア並行 | 開始テンプレ | docker-compose.yml |
| 3 | radica 機能実装 | 機能実装テンプレ | models, views, tests |
| 4 | shrimpshells 機能 | 機能実装テンプレ | models, views, tests |
| 5 | huhfreg 機能 | 機能実装テンプレ | models, views, tests |
| 6 | VPS セットアップ | **Sonnet 不要** | ssh キー設定 |
| 7 | Kamal 設定 | 開始テンプレ | config/deploy.yml |
| 8 | QA テスト作成 | デバッグテンプレ | チェックリスト |
| 9 | 本番デプロイ | **Sonnet 最終確認** | git tag, デプロイ実行 |

---

## Day 9 以降: 次のストア本番化

同じフローで shrimpshells / huhfreg も本番化します。

```
Day 10-11: shrimpshells 本番準備
Day 12: shrimpshells 本番デプロイ

Day 13-14: huhfreg 本番準備
Day 15: huhfreg 本番デプロイ

あとは「運用フェーズ」へ
```

---

## Sonnet とのセッション切り方のコツ

**セッション終了時（Day ごと）：**

```
「ここまでで Day X セッション終了します。

コミット内容:
- [コミットメッセージ]

次のセッション（Day Y）で:
- [やることリスト]

では、新しいチャットを開きます。」
```

**新しいセッション開始時：**

```
「新しいセッションです。前回のサマリ:

前回（Day 6）:
- さくら VPS セットアップ完了
- Kamal 設定開始予定

今回（Day 7）:
- Kamal + Docker Hub 連携完了を目標

[開始テンプレを貼る]」
```

---

## まとめ

この 9 日間フローで、「年内ラディカ本番化」を確実にできます。

大事なポイント:

1. **各 Day ごとにセッションを区切る** → トークン節約 + 集中力維持
2. **テンプレを毎回使う** → 説明時間を削減
3. **テストとコミットを同時にやる** → 品質を下げない
4. **本番デプロイ直前に「最終確認リスト」を Sonnet に作成させる** → ヒューマンエラー防止

では、Day 1 開始です！🚀
