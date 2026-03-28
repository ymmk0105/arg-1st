# CMS Auth Design

最終更新: 2026-03-27

## 目的

ARG 管理 CMS の認証方式を整理する。

この設計の前提:

- ログイン方式は `メールアドレス + パスワード`
- 初期状態では管理者は1人
- 追加ユーザは CMS のユーザー管理画面から admin が登録する
- Cloudflare D1 をユーザ情報保存先にする
- Cloudflare Workers を認証処理の実行場所とする

---

## 基本方針

### 1. 認証は CMS 専用

プレイヤー向け本編にはログイン不要。  
認証が必要なのは CMS のみ。

### 2. ログイン情報は D1 に保存する

`users` テーブルにメールアドレスとパスワードハッシュを保存する。

### 3. セッションでログイン状態を管理する

ログイン成功後は `sessions` テーブルにセッション情報を保存し、  
以後はセッショントークンで認証する。

### 4. パスワードはハッシュ化して保存する

平文保存は禁止。  
DB に入れるのは `password_hash` のみ。

---

## 対象テーブル

## users

使う主なカラム:

- `id`
- `email`
- `display_name`
- `role`
- `status`
- `password_hash`
- `password_updated_at`
- `last_login_at`
- `failed_login_count`

## sessions

使う主なカラム:

- `id`
- `user_id`
- `session_token_hash`
- `expires_at`
- `created_at`
- `revoked_at`

---

## ロール設計

初期案:

- `admin`
- `editor`
- `reviewer`

### `admin`

- ユーザー管理可能
- 作品管理可能
- ストーリー管理可能
- パズル管理可能
- 公開可能

### `editor`

- 作品管理可能
- ストーリー管理可能
- パズル管理可能
- 公開不可
- ユーザー管理不可

### `reviewer`

- 閲覧中心
- 公開確認可能
- 必要に応じて公開承認のみ
- ユーザー管理不可

---

## ログインフロー

```text
ログイン画面
  ↓
メールアドレス入力
パスワード入力
  ↓
Workers API に送信
  ↓
users から対象取得
  ↓
password_hash を検証
  ↓ 成功
sessions 作成
  ↓
セッショントークン返却
  ↓
CMS ログイン完了
```

---

## ログイン失敗時の扱い

失敗時:

- エラーメッセージを返す
- `failed_login_count` を増やす
- セッションは作らない

成功時:

- `failed_login_count` を 0 に戻す
- `last_login_at` を更新する

---

## セッション管理

### 保存方針

- セッショントークン平文は DB に保存しない
- `session_token_hash` のみ保存する

### 推奨ルール

- セッションは期限付き
- ログアウト時は `revoked_at` を埋める
- 期限切れセッションは無効

### セッション期限

初期案:

- 7日

必要に応じて短縮可能。

---

## 初期管理者の扱い

初期状態では admin を1件だけ登録する。

この admin は seed SQL で投入する。

運用:

1. D1 schema 適用
2. admin seed 適用
3. 初期 admin でログイン
4. ユーザー管理画面から追加ユーザを作成

---

## ユーザ追加フロー

```text
admin ログイン
  ↓
ユーザー管理画面
  ↓
メールアドレス、表示名、初期パスワード、ロールを入力
  ↓
Workers API で password を hash 化
  ↓
users に保存
```

---

## パスワード再設定フロー

初期案:

- admin がユーザー管理画面から初期パスワードを再発行
- 発行時に `password_hash` を更新
- `password_updated_at` を更新

将来的に追加できるもの:

- 本人によるパスワード変更
- メール認証付き再設定

---

## ログアウトフロー

```text
ログアウト操作
  ↓
対象 session を revoke
  ↓
クライアントの認証情報を破棄
  ↓
ログイン画面へ戻る
```

---

## API の責務

Workers 側の認証 API は少なくとも次を持つ。

- `POST /auth/login`
- `POST /auth/logout`
- `GET /auth/me`
- `POST /users`
- `PATCH /users/:id/password`

---

## バリデーション

## ログイン時

- メールアドレス必須
- パスワード必須
- `status = active` のユーザのみログイン可

## ユーザ追加時

- メールアドレス一意
- ロール必須
- 初期パスワード必須

---

## セキュリティ上の注意

- パスワード平文を D1 に保存しない
- セッショントークン平文を D1 に保存しない
- ログイン失敗回数を記録する
- エラーメッセージは出しすぎない
- 公開 API と CMS API を分離する

---

## 初期実装でやる範囲

やる:

- メールアドレス + パスワードログイン
- admin seed
- sessions 管理
- admin によるユーザー追加

まだやらない:

- パスワードリセットメール
- 2段階認証
- OAuth ログイン

---

## まとめ

この CMS 認証は次の形で進める。

- D1 の `users` と `sessions` を使う
- パスワードはハッシュ保存
- ログイン後はセッションで管理
- 初期 admin は seed で投入
- 追加ユーザは admin が CMS から登録する
