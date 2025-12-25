# Claude Sonnet 4.5 デバッグプレイブック
## realize_EC で「あるあるトラブル」と対策集

---

## このドキュメントの目的

Rails 8 + Solidus + さくら VPS で実装中に、よく出るエラーやハマりやすいポイントを **事前に知ること**で、時間を節約できます。

「エラーが出た → Sonnet に相談」ではなく、「こういう場合はこう対策する」という **プレイブック** を事前に用意しています。

---

## トラブルシューティング（起動・セットアップ時）

### T-1: Docker Compose で「permission denied」

**症状:**

```
ERROR: permission denied while trying to connect to the Docker daemon
```

**原因:**
- `docker` コマンドが `sudo` が必要な状態
- ユーザが docker グループに属していない

**対策:**

```bash
# ローカル側
sudo usermod -aG docker $USER
newgrp docker

# VPS 側（deploy ユーザで実行）
# すでに done（Step 3 で設定済み）
sudo systemctl restart docker
sudo usermod -aG docker deploy
```

**Sonnet に聞く場合:**

```
「Docker のパーミッション設定をやり直す必要があります。

現在のユーザ情報:
id

の出力結果と、
docker ps
の出力結果を教えてください。」
```

---

### T-2: PostgreSQL が起動しない、DB 接続できない

**症状:**

```
FATAL: remaining connection slots are reserved for non-replication superuser connections
```

または

```
could not connect to database
```

**原因:**
- PostgreSQL コンテナが起動していない
- DB ユーザ / パスワードが違う
- ホスト名が違う（localhost vs db コンテナ名）

**対策:**

```bash
# docker-compose.yml の DATABASE_HOST をチェック
# 開発: db
# 本番: localhost（VPS 上の PostgreSQL を使う）

# ローカルで確認
docker-compose ps

# コンテナが running か確認
docker-compose logs db

# DB にアクセス
docker-compose exec db psql -U postgres -c "\l"
```

**修正例（docker-compose.yml）:**

```yaml
services:
  app:
    environment:
      DATABASE_HOST: db    # コンテナ名（ローカル開発用）
      DATABASE_USER: postgres
      DATABASE_PASSWORD: password
      DATABASE_NAME: realize_ec_${STORE_NAME:-radica}_development

  db:
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
      POSTGRES_DB: realize_ec_${STORE_NAME:-radica}_development
```

---

### T-3: Bundle install で gem 依存性エラー

**症状:**

```
Gem::Resolver::ActivationError: conflicting requirements for activesupport
```

**原因:**
- Rails 8 と Solidus のバージョンが合わない
- 古い Gemfile.lock が残っている

**対策:**

```bash
# Gemfile.lock を削除して再生成
rm Gemfile.lock
bundle install

# または特定の Gem だけ更新
bundle update solidus rails

# Rails 8 + Solidus の最新版を確認
bundle show rails
bundle show solidus
```

**Sonnet に聞く場合:**

```
「以下のエラーが出ました:

[エラーメッセージ全文]

Gemfile は以下の通りです:

[Gemfile の内容]

どの Gem バージョンを落とすべきですか？」
```

---

## トラブルシューティング（開発時）

### T-4: 3ストア並行開発時に DB が競合する

**症状:**

```
ActiveRecord::Migrationspending
pending migration detected
```

複数ターミナルで同時にマイグレーション実行

**原因:**
- 3 ストアが「同じ develop ブランチ」にいて、共通のマイグレーションを読み込んでいる
- 複数ターミナルが同時に db:migrate を実行

**対策:**

```bash
# ターミナル1（radica）
docker-compose up

# 別ターミナル（同じディレクトリ）
docker-compose exec app bundle exec rails db:migrate

# ターミナル2（shrimpshells）は「別ブランチ」で
cd ~/projects/realize_ec
git checkout develop     # あるいは feature/shrimpshells/...
export STORE_NAME=shrimpshells APP_PORT=3001 DB_PORT=5433
docker-compose up

# ターミナル2 のマイグレーションは shrimpshells が起動したあと
docker-compose exec app bundle exec rails db:migrate
```

**Prevention (予防法):**

- 1 ターミナル = 1 ストア = 1 Git ブランチ
- マイグレーションはターミナル1（radica）だけで実行
- 他は「読み取り専用」で使う

---

### T-5: STORE_NAME 環境変数が効いていない

**症状:**

```
http://localhost:3000 にアクセスしたら「radica」が出るべきなのに「shrimpshells」が出ている
```

**原因:**
- STORE_NAME が設定されていない
- 古い コンテナイメージが起動している

**対策:**

```bash
# STORE_NAME を確認
echo $STORE_NAME

# 設定されていなければセット
export STORE_NAME=radica

# 古いコンテナを削除
docker-compose down

# あらためて起動
docker-compose up --build
```

**Sonnet に聞く場合:**

```
「環境変数 STORE_NAME が効いていません。

docker-compose.yml 抜き出し:
[該当部分を貼る]

.env.radica の内容:
[内容を貼る]

どこを修正すべきですか？」
```

---

## トラブルシューティング（Solidus 管理画面）

### T-6: Solidus 管理画面にアクセスできない

**症状:**

```
http://localhost:3000/admin
→ 404 Not Found または 500 Internal Server Error
```

**原因:**
- Solidus が正しくインストールされていない
- ルーティングが設定されていない
- マイグレーションが実行されていない

**対策:**

```bash
# 1. Solidus が Gemfile に入っているか確認
grep solidus Gemfile

# 2. マイグレーション実行
docker-compose exec app bundle exec rails db:migrate

# 3. Solidus ルーティング確認
docker-compose exec app bundle exec rails routes | grep /admin

# 4. Rails console で確認
docker-compose exec app bundle exec rails console

irb> Spree::Store.count    # ストア数
irb> Spree::User.count     # ユーザ数
```

**ログ確認:**

```bash
# Rails ログを確認
docker-compose logs app | tail -50
```

---

### T-7: ストア別設定（STORE_NAME）が管理画面に反映されない

**症状:**

```
http://localhost:3000/admin
→ ストア名が「radica」のはずなのに「Spree」のままになっている
```

**原因:**
- config/initializers/store_config.rb が正しく読み込まれていない
- キャッシュが古い

**対策:**

```bash
# キャッシュ削除
docker-compose exec app bundle exec rails cache:clear

# コンテナ再起動
docker-compose restart app

# Rails console で確認
docker-compose exec app bundle exec rails console

irb> STORE_NAME          # 定義されている？
irb> STORE_CONFIG        # ストア設定が見える？
```

**config/initializers/store_config.rb の確認:**

```ruby
# 以下のように定義されているか確認
STORE_NAME = ENV.fetch('STORE_NAME', 'radica').to_sym

STORE_CONFIG = {
  radica: {
    name: 'ラディカ',
    color: '#FF6600'
  },
  # ...
}.freeze
```

---

## トラブルシューティング（デプロイ・本番）

### T-8: Kamal デプロイで「SSH 接続できない」

**症状:**

```
ERROR: Failed to connect to YOUR_SAKURA_VPS_IP: No route to host
```

**原因:**
- SSH キーが設定されていない
- ファイアウォール（UFW）が SSH ポート 22 をブロックしている
- VPS の IP アドレスが間違っている

**対策:**

```bash
# 1. SSH キー確認
ssh -i ~/.ssh/id_rsa deploy@YOUR_SAKURA_VPS_IP

# 接続できないと言われたら、公開鍵をコピー
cat ~/.ssh/id_rsa.pub | ssh root@YOUR_SAKURA_VPS_IP 'cat >> /home/deploy/.ssh/authorized_keys'

# 2. VPS 側のファイアウォール確認
ssh root@YOUR_SAKURA_VPS_IP
ufw status

# 22 が開いているか確認（ステータスが "ALLOW" か）
# なければ追加
ufw allow 22/tcp

# 3. Kamal config 確認
cat config/deploy.yml | grep -A 5 "servers:"
```

**config/deploy.yml の確認:**

```yaml
servers:
  web:
    hosts:
      - YOUR_SAKURA_VPS_IP    # 実際の IP に置き換えた？
    user: deploy               # deploy ユーザか？
    options:
      ssh_options:
        - "-o ConnectTimeout=5"
```

---

### T-9: Kamal デプロイで「Docker イメージが見つからない」

**症状:**

```
ERROR: image not found: your-username/realize-ec:latest
```

**原因:**
- Docker イメージを Docker Hub に push していない
- Docker Hub のユーザ名が間違っている

**対策:**

```bash
# 1. Docker Hub に push
docker login
docker build -t your-actual-username/realize-ec:latest .
docker push your-actual-username/realize-ec:latest

# 2. config/deploy.yml で正しいユーザ名を設定
cat config/deploy.yml | grep "image:"

# もし間違っていれば修正
# image: your-actual-username/realize-ec
```

---

### T-10: Let's Encrypt 証明書が取得できない

**症状:**

```
ERROR: ACME challenge failed
```

Traefik のログで:

```
challenge failed: dns-01: error resolving fqdn
```

**原因:**
- DNS が正しく設定されていない
- ドメイン propagation に時間がかかっている
- Traefik が HTTP チャレンジを受けられない

**対策:**

```bash
# 1. DNS が正しく反映されているか確認（ローカルから）
nslookup radica.example.com

# もし見つからなければ DNS が反映されていない（待つ）

# 2. Traefik ログ確認
kamal app exec 'docker logs traefik'

# 3. Let's Encrypt ファイル確認
kamal app exec 'cat /letsencrypt/acme.json'

# 4. HTTP (80) と HTTPS (443) が開いているか確認（VPS 側）
ssh deploy@YOUR_SAKURA_VPS_IP
ufw status
# HTTP (80) と HTTPS (443) が ALLOW か確認
```

**VPS 側のファイアウォール設定:**

```bash
ufw allow 80/tcp
ufw allow 443/tcp
```

---

## Sonnet へのエスカレーションテンプレ（トラブルシューティング版）

上のプレイブックで解決できなかった場合、以下のテンプレで Sonnet に相談します。

```
【トラブルシューティング相談】

【現象】
実際にどう壊れているか（エラーメッセージ、画面キャプチャ）

【期待動作】
本来どう動いてほしいか

【環境】
- ローカル / VPS
- STORE_NAME: radica / shrimpshells / huhfreg
- Docker container か物理 VM か

【再現手順】
1. ...
2. ...
3. → 現象が発生

【実行済みのトラブルシューティング】
- これまでどんなコマンドを実行したか
- 「T-1」「T-5」みたいなプレイブック項目は該当するか

【ログ / エラーメッセージ（上位 20-30 行）】
```
docker-compose logs app | tail -30
```
または
```
kamal logs -f | head -30
```

【質問】
- 原因候補は何か
- 次に何をテストすべきか
- 修正方法は
```

---

## 本番運用で出やすいトラブル

### T-11: メモリ不足で Rails が落ちる

**症状:**

```
Bus error
or
Killed (out of memory)
```

**原因:**
- メモリ 2GB なのに worker が多い、キャッシュが詰まっている
- Solid Queue のジョブが溜まっている

**対策:**

```bash
# VPS 側で確認
kamal app exec 'free -h'

# メモリ使用状況
kamal app exec 'ps aux --sort=-%mem | head -10'

# Puma ワーカー数確認
kamal app exec 'bundle exec puma -c config/puma.rb --status'

# workers 1, threads 2,4 に設定（config/puma.rb）
threads 2, 4
workers 1
```

### T-12: Stripe webhook タイムアウト

**症状:**

```
stripe.payment_intent.succeeded イベントが反映されない
または
Webhook delivery failed
```

**原因:**
- Rails アプリの応答が遅い
- Solid Queue ジョブが詰まっている

**対策:**

```bash
# ログ確認
kamal logs -f | grep -i stripe

# Solid Queue のジョブ確認
kamal app exec 'bundle exec rails console'

irb> SolidQueue::Job.count
irb> SolidQueue::FailedExecution.count

# ジョブをクリア（最終手段）
# irb> SolidQueue::Job.delete_all
```

### T-13: PostgreSQL ディスク容量不足

**症状:**

```
no space left on device
or
disk full
```

**原因:**
- Docker ログが肥大化
- DB ダンプが蓄積
- アップロードファイルが溜まっている

**対策:**

```bash
# VPS 側でディスク確認
kamal app exec 'df -h'

# 大きいファイル探す
kamal app exec 'du -sh /var/lib/docker/*'

# ログローテーション設定
# /etc/docker/daemon.json に以下を追加
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}

# Docker デーモン再起動
sudo systemctl restart docker
```

---

## まとめ：プレイブック利用フロー

```
エラー が出た
    ↓
「症状」から T-1 ~ T-13 のどれに該当するか探す
    ↓
見つかった → プレイブック通りに対策実行
    ↓
解決！
    ↓
見つからない → Sonnet にエスカレーション（テンプレ使用）
```

**プレイブック活用で、開発効率 30% 向上が見込めます。**

---

## 参考リンク（各技術の公式ドキュメント）

- [Rails 8 ガイド](https://guides.rubyonrails.org)
- [Solidus ドキュメント](https://guides.solidus.io)
- [Kamal GitHub](https://github.com/basecamp/kamal)
- [Docker Compose リファレンス](https://docs.docker.com/compose/)
- [PostgreSQL 公式ドキュメント](https://www.postgresql.org/docs/)
- [Stripe API リファレンス](https://stripe.com/docs/api)

---

それでは、トラブルが出ても大丈夫。このプレイブックを活用してください！💪
