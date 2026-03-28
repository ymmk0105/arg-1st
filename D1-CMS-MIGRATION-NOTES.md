# D1 CMS Migration Notes

最終更新: 2026-03-27

## 追加したもの

- `d1/migrations/0002_cms_auth_and_flags.sql`

これは CMS 初期要件に対応するための追加マイグレーション草案。

---

## この migration で追加した内容

### 1. users テーブルに認証用カラムを追加

追加カラム:

- `password_hash`
- `password_updated_at`
- `last_login_at`
- `failed_login_count`

目的:

- メールアドレス + パスワードでログインできるようにする
- パスワード更新日時を持つ
- 最終ログインを記録する
- ログイン失敗回数を持つ

注意:

- `password_hash` は初期 migration では NULL 許容
- 既存レコードがある状態でも migration が通るようにしている
- 実運用では初期 admin ユーザに必ず hash を投入する

---

## 2. sessions テーブルを追加

目的:

- CMS のログインセッション管理
- ログアウトや失効の管理

保存方針:

- トークンそのものではなく `session_token_hash` を保存する

---

## 3. puzzles に `is_enabled` を追加

目的:

- 公開条件の判定をしやすくする
- 一時的に外したい puzzle を無効化できるようにする

初期値:

- `1`

---

## 4. published_snapshots に `validation_result_json` を追加

目的:

- 公開確認画面でチェックした内容を snapshot 側にも記録する
- 後から「何を満たして公開したか」を追いやすくする

---

## 運用メモ

### パスワードについて

- 平文保存は禁止
- `password_hash` にはハッシュ済み文字列のみ保存する
- 実装時は Worker 側でハッシュ生成・検証する

### セッションについて

- 期限付きにする
- 失効済み `revoked_at` を見て無効化する
- 定期的なクリーンアップは後から追加可能

---

## 適用順

1. `0001_initial_schema.sql`
2. `0002_cms_auth_and_flags.sql`

---

## 適用例

ローカル:

```powershell
wrangler d1 execute arg-admin-db --local --file .\d1\migrations\0002_cms_auth_and_flags.sql
```

リモート:

```powershell
wrangler d1 execute arg-admin-db --remote --file .\d1\migrations\0002_cms_auth_and_flags.sql
```

---

## 次にやるとよいこと

1. 初期 admin ユーザの seed SQL を作る
2. パスワードハッシュ方式を決める
3. sessions を使う認証フローを設計する
4. Puzzle の公開可否判定ロジックを CMS 側に実装する

---

## まとめ

この migration で、CMS 初期実装に必要な最低限の追加要素が揃う。

- メールアドレス + パスワードログイン
- セッション管理
- Puzzle 有効化フラグ
- 公開確認結果の保存
