# Rails 8 + Solidus + さくら VPS（Kamal 2）
## 年内リリース向け完全実装ガイド

---

## 目次

1. [プロジェクト構成](#プロジェクト構成)
2. [技術スタック](#技術スタック)
3. [Git ブランチ戦略](#git-ブランチ戦略)
4. [ローカル開発環境](#ローカル開発環境)
5. [さくら VPS セットアップ](#さくら-vps-セットアップ)
6. [本番デプロイ（Kamal 2）](#本番デプロイkamal-2)
7. [年内リリースロードマップ](#年内リリースロードマップ)

---

## プロジェクト構成

1つの **realize_EC** リポジトリで、Git のブランチ・タグで3つのストア（ラディカ、シュリンプシェルズ、フフフレグ）を管理します。

```
GitHub リポジトリ: realize_EC
https://github.com/yourname/realize_ec

realize_EC/
├── Dockerfile                      # Rails 8 + Kamal 用
├── docker-compose.yml              # ローカル開発専用
├── Gemfile                         # Rails 8
├── Gemfile.lock
│
├── app/
│   ├── controllers/
│   │   ├── home_controller.rb
│   │   └── products_controller.rb
│   ├── views/
│   │   ├── home/
│   │   │   └── index.html.erb
│   │   └── products/
│   │       └── index.html.erb
│   ├── models/
│   │   ├── spree/
│   │   └── ...（Solidus モデル）
│   └── assets/
│       └── stylesheets/
│           ├── common.css
│           ├── radica.css
│           ├── shrimpshells.css
│           └── huhfreg.css
│
├── config/
│   ├── database.yml
│   ├── routes.rb
│   ├── puma.rb
│   ├── solid_queue.yml
│   ├── solid_cache.yml
│   ├── solid_cable.yml
│   └── initializers/
│       ├── stripe_config.rb
│       ├── store_config.rb
│       └── solidus.rb
│
├── config/deploy.yml               # Kamal 2 設定
├── .env.example
├── .env.radica
├── .env.shrimpshells
├── .env.huhfreg
│
├── .github/
│   └── workflows/
│       └── ci.yml
│
├── db/
│   ├── migrate/
│   ├── seeds.rb
│   └── schema.rb
│
├── docs/
│   └── ...
│
└── README.md
```

---

## 技術スタック

| 項目 | 選択 | 理由 |
|------|------|------|
| **Ruby** | 3.3.0+ | Rails 8 推奨 |
| **Rails** | 8.x | Kamal 2 統合、Solid Queue 対応 |
| **Solidus** | 最新（Rails 8 対応版） | EC 機能 |
| **DB** | PostgreSQL 14+ | さくら VPS で推奨 |
| **Web サーバ** | Puma | Rails 標準 |
| **ジョブキュー** | Solid Queue | Redis なし |
| **キャッシュ** | Solid Cache | Redis なし |
| **WebSocket** | Solid Cable | Redis なし |
| **決済** | Stripe | ストア別 API キー |
| **デプロイ** | Kamal 2 | ワンコマンドデプロイ |
| **本番環境** | さくら VPS（Ubuntu 22.04） | 日本国内、低コスト |

### さくら VPS 推奨スペック

```
【最小（ラディカのみ本番化）】
- プラン: 2GB メモリ
- CPU: 2コア
- SSD: 100GB
- 月額: ¥1,738

【推奨（複数ストア同時運用）】
- プラン: 4GB メモリ
- CPU: 4コア
- SSD: 200GB
- 月額: ¥3,960
```

---

## Git ブランチ戦略

```
main ブランチ（本番用）
├── radica-v1.0.0 [タグ]        → ラディカ本番運用中
├── shrimpshells-v1.0.0 [タグ]  → シュリンプシェルズ本番待機
└── huhfreg-v1.0.0 [タグ]       → フフフレグ本番待機

develop ブランチ（開発統合用）
├── feature/radica/add-discount
├── feature/shrimpshells/improve-cart
└── feature/huhfreg/add-recipes

bugfix/ ブランチ（バグ修正用）
├── bugfix/radica/fix-payment
├── bugfix/shrimpshells/fix-inventory
└── bugfix/huhfreg/fix-checkout

hotfix/ ブランチ（本番緊急修正）
└── hotfix/radica/urgent-security
```

---

## ローカル開発環境

### セットアップ（初回のみ）

```bash
# リポジトリをクローン
git clone https://github.com/yourname/realize_ec.git
cd realize_ec

# Ruby 3.3 + Rails 8 がインストール済みか確認
ruby --version   # ruby 3.3.0+
rails --version  # Rails 8.x

# Gem をインストール
bundle install

# Solidus をインストール
bundle exec rails generate solidus:install --auto-accept

# Solidus 管理画面用ユーザー作成
bundle exec rails db:seed
```

### Docker Compose（3つのストアを並行開発）

```yaml
# docker-compose.yml

version: '3.9'

services:
  app:
    build: .
    command: bundle exec puma -C config/puma.rb
    volumes:
      - .:/rails
      - gem_cache:/usr/local/bundle
    ports:
      - "${APP_PORT:-3000}:3000"
    depends_on:
      - db
    environment:
      RAILS_ENV: development
      STORE_NAME: ${STORE_NAME:-radica}
      DATABASE_HOST: db
      DATABASE_PASSWORD: password
    env_file:
      - .env.${STORE_NAME:-radica}

  db:
    image: postgres:14
    volumes:
      - postgres_data_${STORE_NAME:-radica}:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
      POSTGRES_DB: realize_ec_${STORE_NAME:-radica}_development
    ports:
      - "${DB_PORT:-5432}:5432"

volumes:
  postgres_data_radica:
  postgres_data_shrimpshells:
  postgres_data_huhfreg:
  gem_cache:
```

### ローカルで3つのストアを同時実行

```bash
# ターミナル1: ラディカ
cd ~/projects/realize_ec
export STORE_NAME=radica APP_PORT=3000 DB_PORT=5432
docker-compose up

---

# ターミナル2: シュリンプシェルズ
cd ~/projects/realize_ec
export STORE_NAME=shrimpshells APP_PORT=3001 DB_PORT=5433
docker-compose up

---

# ターミナル3: フフフレグ
cd ~/projects/realize_ec
export STORE_NAME=huhfreg APP_PORT=3002 DB_PORT=5434
docker-compose up
```

### 簡単化スクリプト

```bash
# bin/start_store.sh

#!/bin/bash

STORE_NAME=${1:-radica}

case $STORE_NAME in
  radica)
    export APP_PORT=3000 DB_PORT=5432
    echo "Starting Radica on http://localhost:3000"
    ;;
  shrimpshells)
    export APP_PORT=3001 DB_PORT=5433
    echo "Starting ShrimpShells on http://localhost:3001"
    ;;
  huhfreg)
    export APP_PORT=3002 DB_PORT=5434
    echo "Starting HuhFreg on http://localhost:3002"
    ;;
  *)
    echo "Unknown store: $STORE_NAME"
    exit 1
    ;;
esac

export STORE_NAME=$STORE_NAME
docker-compose up
```

使用方法:

```bash
chmod +x bin/start_store.sh
./bin/start_store.sh radica
```

---

## さくら VPS セットアップ

### Step 1: SSH ログイン＆基本設定

```bash
# SSH でログイン
ssh root@YOUR_SAKURA_VPS_IP

# システムアップデート
apt update && apt upgrade -y

# 必要なパッケージインストール
apt install -y curl git wget build-essential libssl-dev libreadline-dev zlib1g-dev

# タイムゾーン設定
timedatectl set-timezone Asia/Tokyo

# ホスト名設定
hostnamectl set-hostname realize-ec

# システム情報確認
uname -a
```

### Step 2: Docker インストール

```bash
# Docker リポジトリ追加
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Docker インストール
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Docker 起動
systemctl start docker
systemctl enable docker

# 確認
docker --version
docker run hello-world
```

### Step 3: デプロイユーザー作成

```bash
# deploy ユーザー作成
useradd -m -s /bin/bash deploy
usermod -aG docker deploy
usermod -aG sudo deploy

# SSH キー設定（セキュリティ強化）
su - deploy
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# ローカル側で実行：公開鍵をコピー
# scp ~/.ssh/id_rsa.pub deploy@YOUR_SAKURA_VPS_IP:~/.ssh/authorized_keys

# VPS 側で実行：パーミッション設定
chmod 600 ~/.ssh/authorized_keys

# ユーザ確認
id

# 終了
exit
```

### Step 4: ファイアウォール設定

```bash
# UFW インストール＆設定
apt install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp      # SSH
ufw allow 80/tcp      # HTTP
ufw allow 443/tcp     # HTTPS
ufw enable

# 確認
ufw status
```

### Step 5: スワップ設定（メモリ 2GB 用、重要）

```bash
# スワップ領域を 2GB 作成
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# 永続化
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab

# 確認
free -h
```

### Step 6: PostgreSQL インストール

```bash
# PostgreSQL インストール
apt install -y postgresql postgresql-contrib

# PostgreSQL 起動
systemctl start postgresql
systemctl enable postgresql

# DB ユーザー作成
sudo -u postgres createuser --createdb realize_ec

# パスワード設定
sudo -u postgres psql -c "ALTER USER realize_ec WITH PASSWORD 'your_secure_password';"

# 確認
sudo -u postgres psql -l
```

### Step 7: Kamal インストール

```bash
# ruby がない場合はインストール
apt install -y ruby-full

# Kamal インストール
gem install kamal

# 確認
kamal version
```

---

## 本番デプロイ（Kamal 2）

### ローカル側：Kamal 初期化

```bash
cd ~/projects/realize_ec

# Kamal 設定ファイルを生成
kamal init

# config/deploy.yml が生成される（編集が必要）
```

### config/deploy.yml（さくら VPS 対応版）

```yaml
# config/deploy.yml

service: realize-ec
image: your-dockerhub-username/realize-ec

servers:
  web:
    hosts:
      - YOUR_SAKURA_VPS_IP       # さくら VPS から付与された IP
    user: deploy
    options:
      ssh_options:
        - "-o ConnectTimeout=5"
        - "-o StrictHostKeyChecking=no"
    labels:
      traefik.http.routers.realize-ec-radica.rule: Host(`radica.example.com`)
      traefik.http.routers.realize-ec-radica.entrypoints: websecure
      traefik.http.routers.realize-ec-radica.tls.certresolver: letsencrypt

registry:
  server: registry.hub.docker.com
  username: <%= ENV['REGISTRY_USER'] %>
  password: <%= ENV['REGISTRY_PASSWORD'] %>

env:
  clear:
    RAILS_ENV: production
    RAILS_LOG_TO_STDOUT: true
    STORE_NAME: radica
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_URL
    - STRIPE_SECRET_KEY
    - STRIPE_PUBLISHABLE_KEY

volumes:
  - data:/rails/storage

processes:
  web: bundle exec puma -C config/puma.rb
  worker: bundle exec solid_queue:start

# Traefik + Let's Encrypt（HTTP/HTTPS ルーティング）
traefik:
  image: traefik:v2.10
  options:
    publish:
      - 80:80
      - 443:443
    volume:
      - letsencrypt:/letsencrypt
  args:
    certificatesresolvers.letsencrypt.acme.email: your-email@example.com
    certificatesresolvers.letsencrypt.acme.storage: /letsencrypt/acme.json
    certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint: web
```

### Dockerfile（Rails 8 + Kamal 用）

```dockerfile
FROM ruby:3.3.0

WORKDIR /rails

# 依存ツール
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Bundler
COPY Gemfile Gemfile.lock ./
RUN bundle install

# アプリケーション
COPY . .

# アセットプリコンパイル（Propshaft）
RUN bundle exec rails assets:precompile

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```

### Puma 設定（2GB メモリ用）

```ruby
# config/puma.rb

# メモリ 2GB 用の設定
threads 2, 4              # min_threads, max_threads
workers 1                 # 2GB メモリでは worker 1 が安全
worker_timeout 60
worker_boot_timeout 60

bind "tcp://0.0.0.0:3000"
environment ENV.fetch('RAILS_ENV') { 'development' }
```

### デプロイ実行手順

```bash
cd ~/projects/realize_ec

# 1. Docker イメージをビルド → Docker Hub にプッシュ
docker build -t your-username/realize-ec:latest .
docker push your-username/realize-ec:latest

# 2. Kamal でデプロイ
kamal deploy

# 3. DB マイグレーション
kamal app exec --interactive 'bundle exec rails db:migrate'

# 4. DB シード
kamal app exec --interactive 'bundle exec rails db:seed'

# 5. ブラウザで確認
curl https://radica.example.com
```

### 環境変数設定

```bash
# ローカルに .env.production.local を作成（リポジトリには含めない）
REGISTRY_USER=your-dockerhub-username
REGISTRY_PASSWORD=your-dockerhub-token

# Kamal 経由で さくら VPS に設定
RAILS_MASTER_KEY=xxxxx              # rails secret
DATABASE_URL=postgresql://realize_ec:password@localhost/realize_ec_radica
STRIPE_SECRET_KEY=sk_live_radica_xxxxx
STRIPE_PUBLISHABLE_KEY=pk_live_radica_xxxxx
```

### DNS 設定

さくら のコントロールパネルで DNS を設定:

```
radica.example.com        A YOUR_SAKURA_VPS_IP
shrimpshells.example.com  A YOUR_SAKURA_VPS_IP
huhfreg.example.com       A YOUR_SAKURA_VPS_IP
```

### シュリンプシェルズ・フフフレグもデプロイ

```bash
# config/deploy.yml の STORE_NAME を変更
STORE_NAME: shrimpshells

# デプロイ
kamal deploy

# DB マイグレーション
kamal app exec 'bundle exec rails db:migrate'

# https://shrimpshells.example.com
```

### 本番環境での操作

```bash
# ログ確認
kamal logs -f

# コンソール起動
kamal app exec --interactive 'bundle exec rails console'

# 再起動
kamal reboot

# デプロイ確認
kamal status

# ロールバック
kamal rollback

# リソース監視
kamal app exec 'free -h'
kamal app exec 'df -h'
```

---

## ストア別設定ファイル

### config/initializers/store_config.rb

```ruby
STORE_NAME = ENV.fetch('STORE_NAME', 'radica').to_sym

STORE_CONFIG = {
  radica: {
    name: 'ラディカ',
    color: '#FF6600',
    description: '本格インドカレーをご家庭で'
  },
  shrimpshells: {
    name: 'シュリンプシェルズ',
    color: '#0066FF',
    description: 'ハワイの味を冷凍でお届け'
  },
  huhfreg: {
    name: 'フフフレグ',
    color: '#00AA00',
    description: 'モンゴルの伝統料理'
  }
}.freeze
```

### config/initializers/stripe_config.rb

```ruby
case ENV['STORE_NAME']&.to_sym
when :radica
  Stripe.api_key = Rails.application.credentials.radica_stripe_secret_key
when :shrimpshells
  Stripe.api_key = Rails.application.credentials.shrimpshells_stripe_secret_key
when :huhfreg
  Stripe.api_key = Rails.application.credentials.huhfreg_stripe_secret_key
else
  Stripe.api_key = Rails.application.credentials.radica_stripe_secret_key
end
```

---

## 年内リリースロードマップ

```
Day 1-2: 基盤セットアップ
  ✅ Rails 8 プロジェクト生成
  ✅ Solidus インストール
  ✅ Docker セットアップ
  ✅ ストア別設定ファイル作成
  ✅ GitHub リポジトリ初期化

Day 3-5: 機能実装
  ✅ feature/radica/* で ラディカ開発
  ✅ feature/shrimpshells/* でシュリンプシェルズ開発
  ✅ feature/huhfreg/* でフフフレグ開発
  ✅ develop へマージ
  ✅ ローカルで3ストア並行開発確認

Day 6-8: 本番準備
  ✅ さくら VPS セットアップ
  ✅ Kamal 2 設定
  ✅ Docker Hub アカウント準備
  ✅ DNS 設定
  ✅ Stripe API キー取得（ストア別）
  ✅ ステージングデプロイ

Day 9: Go Live
  ✅ ラディカを本番デプロイ
  ✅ https://radica.example.com で運用開始

以降: シュリンプシェルズ / フフフレグも順次本番化
```

---

## トラブルシューティング（さくら VPS よくある問題）

### メモリ不足

```bash
# メモリ使用状況確認
free -h

# スワップ使用状況確認
swapon --show

# 解決策：スワップ設定（Step 5 参照）
```

### ディスク容量不足

```bash
# ディスク使用状況確認
df -h

# Docker イメージクリーンアップ
docker system prune -a

# ログローテーション設定
# /etc/logrotate.d/ 内に設定
```

### Docker コンテナが起動しない

```bash
# ログ確認
kamal logs -f

# SSH 接続確認
ssh -v deploy@YOUR_SAKURA_VPS_IP

# Docker デーモン再起動
sudo systemctl restart docker
```

### Let's Encrypt 証明書取得失敗

```bash
# DNS が正しく設定されているか確認
nslookup radica.example.com

# Traefik ログ確認
kamal app exec 'cat /letsencrypt/acme.json'
```

---

## まとめ

### メリット

- ✅ 1つのリポジトリで統一管理
- ✅ Rails 8 の最新機能を活用（Kamal 2, Solid Queue）
- ✅ Redis なし（Postgres で完結）
- ✅ さくら VPS で低コスト運用（¥1,738/月）
- ✅ 年内リリース確実化

### 技術スタック確定

| 層 | 選択 |
|----|------|
| Language | Ruby 3.3.0+ |
| Framework | Rails 8.x |
| EC Engine | Solidus |
| Database | PostgreSQL 14+ |
| Web Server | Puma（workers 1） |
| Job Queue | Solid Queue |
| Cache | Solid Cache |
| WebSocket | Solid Cable |
| Assets | Propshaft + Thruster |
| Deployment | Kamal 2 |
| Server | さくら VPS（Ubuntu 22.04） |
| Payment | Stripe（ストア別） |
| DNS/SSL | さくら DNS / Let's Encrypt |

---

次のステップ：

1. このガイドをコピペしながら実装開始
2. sonnet_pairing_guide.md でペアプロ開始
3. sonnet_feature_workflow.md で Day 1-9 進める
4. エラーが出たら sonnet_debug_playbook.md で対策

では、年内ラディカ本番化、頑張ってください！🚀
