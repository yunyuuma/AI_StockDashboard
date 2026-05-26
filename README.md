# 株式ダッシュボードアプリ

Spring Boot (Backend) + Flutter (Frontend) で構成された日本株疑似売買学習アプリです。

---

## 機能一覧

### 認証
- ユーザー登録・ログイン（JWT認証）
- 二要素認証（メールOTP）
- パスワードポリシー（8〜16文字、英数字記号2種類以上）

### 株式検索・一覧
- J-Quants API連携による日本株一覧（キャッシュ付き）
- 銘柄コード・銘柄名・業種・市場での絞り込み検索
- お気に入り銘柄登録・削除

### 銘柄詳細
- 株価サマリー（現在値・前日比・高値・安値・始値・出来高）
- ローソク足・折れ線グラフ（1M/3M/6M/1Y/ALL切替）
- 出来高グラフ
- 移動平均線（MA5・MA25）
- RSI（14日）
- 決算サマリー・業績予想
- ニュース一覧（既読管理）
- 企業情報（概要・Webサイト・Googleマップ・Google Trends）

### 疑似売買
- 成行・指値・逆指値注文
- アルゴ注文（IFD・OCO・IFDOCO）
- 仮想残高管理（初期100万円）
- 注文板（フル板）表示
- 注文一覧（未約定・約定済み・取消済み）
- 保有銘柄一覧（含み損益表示）
- 売買履歴

### ポートフォリオ
- 総資産・現金・保有評価額
- 総損益・日次損益・最大ドローダウン
- 資産推移グラフ
- セクター配分円グラフ

### AIアドバイザー（Ollama連携）
- ポートフォリオ分析レポート
- 銘柄個別アドバイス
- 売買レビュー
- AIチャット（銘柄コンテキスト付き）

### 管理者機能（ADMINロール）
- ダッシュボード（ユーザー数・株式数など）
- ユーザー管理（ロール変更）
- 株式マスタ管理
- 企業プロフィール管理（概要・URL・マップクエリなど）

---

## 技術スタック

### Backend
- **Spring Boot 3.5.0** (Java 17)
- **Spring Security** + **JWT** (jjwt 0.12.5)
- **Spring Data JPA** + **MySQL**
- **Spring Mail**（メールOTP）
- **J-Quants API**（株価データ）
- **Ollama** (qwen2.5:1.5b)（AIチャット）
- **Jsoup**（ニューススクレイピング）
- **Lombok**

### Frontend
- **Flutter 3.x** (Dart)
- **go_router**（ルーティング）
- **http**（API通信）
- **fl_chart**（チャート描画）
- **shared_preferences**（セッション保存）
- **url_launcher**（外部URLオープン）

---

## セットアップ

### 前提条件
- Java 17+
- Maven 3.x
- MySQL 8.x
- Flutter SDK 3.x
- Ollama（AIチャット機能を使う場合）

### Backend起動手順

```bash
cd backend

# 1. MySQLでデータベース作成
mysql -u root -p
CREATE DATABASE stock_app;

# 2. application.ymlの設定を編集
#    - spring.datasource.username / password
#    - spring.mail.username / password (Gmailアプリパスワード)
#    - jquants.api-key (J-Quants APIキー)
#    - app.jwt.secret (32文字以上のランダム文字列)

# 3. ビルド・起動
./mvnw spring-boot:run
```

### Frontend起動手順

```bash
cd frontend

# 依存関係インストール
flutter pub get

# 起動（iOS/Android/Web）
flutter run

# Webブラウザで起動
flutter run -d chrome
```

### Ollama（AI機能）セットアップ

```bash
# Ollamaインストール後
ollama pull qwen2.5:1.5b
ollama serve
```

---

## API エンドポイント一覧

| メソッド | パス | 説明 | 認証 |
|---------|------|------|------|
| POST | /api/auth/register | ユーザー登録 | 不要 |
| POST | /api/auth/login | ログイン | 不要 |
| POST | /api/auth/logout | ログアウト | 不要 |
| POST | /api/auth/2fa/verify | 2FA認証 | 不要 |
| POST | /api/auth/2fa/resend | 2FAコード再送 | 不要 |
| GET | /api/stocks | 株式一覧 | 不要 |
| GET | /api/stocks/{code} | 銘柄詳細 | 不要 |
| GET | /api/stocks/{code}/chart | チャートデータ | 不要 |
| GET | /api/stocks/{code}/metrics | 財務指標 | 不要 |
| GET | /api/stocks/{code}/company | 企業情報 | 不要 |
| GET | /api/stocks/{code}/news | ニュース | 不要 |
| GET | /api/favorites | お気に入り一覧 | 必要 |
| POST | /api/favorites | お気に入り追加 | 必要 |
| DELETE | /api/favorites/{stockCode} | お気に入り削除 | 必要 |
| GET | /api/users/me | プロフィール取得 | 必要 |
| PUT | /api/users/me | プロフィール更新 | 必要 |
| PUT | /api/users/me/password | パスワード変更 | 必要 |
| GET | /api/trading/summary | 売買サマリー | 必要 |
| GET | /api/trading/positions | 保有銘柄 | 必要 |
| GET | /api/trading/trades | 売買履歴 | 必要 |
| GET | /api/trading/orders | 注文一覧 | 必要 |
| POST | /api/trading/orders | 注文 | 必要 |
| DELETE | /api/trading/orders/{id} | 注文取消 | 必要 |
| POST | /api/trading/algo-orders | アルゴ注文 | 必要 |
| GET | /api/trading/order-book/{code} | 板情報 | 必要 |
| GET | /api/trading/portfolio | ポートフォリオ | 必要 |
| GET | /api/ai-advisor | AIアドバイス | 必要 |
| GET | /api/ai-advisor/stocks/{code} | 銘柄AIアドバイス | 必要 |
| GET | /api/ai-advisor/trading-review | 売買レビュー | 必要 |
| POST | /api/ai-advisor/chat | AIチャット | 必要 |
| GET | /api/admin/dashboard | 管理ダッシュボード | ADMIN |
| GET | /api/admin/users | ユーザー管理 | ADMIN |
| PUT | /api/admin/users/{id}/role | ロール変更 | ADMIN |
| GET | /api/admin/stocks | 株式管理 | ADMIN |
| GET | /api/admin/company-profiles | 企業プロフィール管理 | ADMIN |

---

## ディレクトリ構成

```
stock_app/
├── backend/
│   ├── pom.xml
│   └── src/main/java/com/example/stockapp/
│       ├── StockAppApplication.java
│       ├── client/
│       │   └── JQuantsClient.java          # J-Quants API クライアント
│       ├── config/
│       │   ├── JQuantsProperties.java
│       │   └── SecurityConfig.java
│       ├── controller/                      # REST APIコントローラー
│       ├── dto/                             # リクエスト/レスポンスDTO
│       ├── entity/                          # JPAエンティティ
│       ├── repository/                      # Spring Data Repositoryインターフェース
│       ├── security/                        # JWT認証フィルター
│       └── service/                         # ビジネスロジック
└── frontend/
    └── lib/
        ├── main.dart                        # ルーティング設定
        └── features/
            ├── stock/                       # 株式・認証機能
            │   ├── data/                    # APIリポジトリ
            │   ├── domain/                  # ドメインモデル
            │   └── presentation/            # UI画面
            ├── trading/                     # 疑似売買機能
            ├── ai/                          # AIアドバイザー機能
            └── admin/                       # 管理者機能
```

---

## 注意事項

- J-Quants APIは無料プランで利用可能（APIキー取得が必要）
- AIチャット機能はOllama（ローカルLLM）を使用（オプション）
- 疑似売買のため実際の資金は動かない学習用アプリ
- メール機能はGmailアプリパスワードを使用
