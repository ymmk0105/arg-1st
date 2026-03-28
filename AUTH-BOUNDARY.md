# Auth Boundary Memo

最終更新: 2026-03-27

## 目的

Cloudflare D1 を使うときの認証と、CMS 利用者の認証の違いを整理する。

混同しやすいポイント:

- Cloudflare に対する認証
- D1 へアクセスするための設定
- CMS を使う編集者のログイン

この3つは役割が異なる。

---

## 結論

### 1. D1 データベース自体は作成が必要

必要。

例:

```powershell
wrangler d1 create arg-admin-db
```

これは Cloudflare 上に D1 データベースを作る操作。

### 2. D1 にログインする DB ユーザ作成は通常不要

不要。

PostgreSQL や MySQL のように、

- DBユーザを作る
- パスワードを作る
- host / port / user / password で接続する

という形ではない。

### 3. CMS 利用者のユーザ管理は別途必要

必要。

ただしこれは D1 接続用ユーザではなく、  
「管理画面を誰が使えるか」を制御するためのアプリ側ユーザである。

---

## それぞれの役割

## A. Cloudflare 認証

### 何のための認証か

- D1 を作る
- migration を適用する
- Workers / Pages をデプロイする
- Cloudflare のリソースを操作する

### 誰が使うか

- 開発者
- デプロイ環境
- CI/CD

### 代表例

- `wrangler login`
- API Token
- Cloudflare Dashboard へのログイン

### ここで管理するもの

- Cloudflare アカウント権限
- D1 作成権限
- Workers / Pages 操作権限

---

## B. D1 binding

### 何のための設定か

- Worker や Pages Functions から D1 を参照する

### どうやって使うか

`wrangler.jsonc` や `wrangler.toml` に設定する。

例:

```json
{
  "d1_databases": [
    {
      "binding": "DB",
      "database_name": "arg-admin-db",
      "database_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    }
  ]
}
```

Worker 側:

```js
env.DB
```

### 注意

これは「接続設定」であって、  
DBユーザの作成ではない。

---

## C. CMS 利用者認証

### 何のための認証か

- 管理画面にログインする
- 誰が編集できるか制御する
- 誰が公開できるか制御する
- 監査ログに操作主体を残す

### 誰が使うか

- あなた
- 編集担当者
- レビュー担当者

### ここで管理するもの

- `users` テーブル
- ロール
- セッション
- ログイン状態

### 代表的なロール例

- `admin`
- `editor`
- `reviewer`

---

## 図で整理すると

```text
[あなた / 開発者]
   ↓ Cloudflare 認証
[Cloudflare アカウント]
   ↓ wrangler / dashboard / api token
[D1 / Workers / Pages]

[CMS 利用者]
   ↓ CMS ログイン
[admin-cms]
   ↓ binding 経由
[Workers API]
   ↓ env.DB
[D1]
```

重要なのは:

- D1 に直接ユーザがログインするわけではない
- CMS 利用者は Worker / API を経由して D1 を使う

---

## 今回の `users` テーブルの意味

`users` テーブルは D1 接続用ではない。

役割:

- 編集者の識別
- 権限制御
- 公開者の記録
- 監査ログとの紐付け

つまり、これは「アプリケーションの利用者管理」である。

---

## 普通の RDBMS との違い

## PostgreSQL / MySQL の場合

一般的には次が必要になる。

- DBサーバ
- DB名
- DBユーザ
- DBパスワード
- 接続先 host / port

## Cloudflare D1 の場合

通常は次になる。

- Cloudflare 上で D1 データベースを作る
- binding を設定する
- Worker / Pages Functions から `env.DB` で使う

したがって、  
**D1 は「DBログインユーザをアプリが握る」型ではない**。

---

## 実装時に必要なものと不要なもの

## 必要

- D1 データベース作成
- `wrangler login`
- `database_id` の控え
- `wrangler.jsonc` / `wrangler.toml` の binding 設定
- CMS 利用者向けの認証設計

## 不要

- D1 用 SQL ログインユーザ作成
- D1 パスワード管理
- DB接続文字列の配布

---

## 今後の実装で考えるべき認証

次に本当に設計すべきなのは D1 ログインではなく、CMS ログイン。

例:

- 管理者だけ公開できるようにするか
- 編集者は story / puzzle 更新までにするか
- reviewer は公開承認だけにするか

この設計は `users` とセッション管理の話であり、D1 の接続認証とは別問題である。

---

## まとめ

Cloudflare D1 では:

- DB自体の作成は必要
- DBログイン用ユーザ作成は通常不要
- Cloudflare 認証で D1 を操作する
- Worker / Pages は binding で D1 を使う
- CMS 利用者のログインは別途アプリ側で設計する

この切り分けで考えると、実装の責務がかなり整理しやすくなる。
