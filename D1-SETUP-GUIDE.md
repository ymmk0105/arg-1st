# D1 Setup Guide

最終更新: 2026-03-27

## 目的

Cloudflare D1 に ARG 管理用スキーマを適用するための手順を整理する。

この文書では、以下を対象にする。

- D1 データベースの作成
- `0001_initial_schema.sql` の適用
- ローカル確認
- 本番反映時の注意

---

## 前提

必要なもの:

- Cloudflare アカウント
- `wrangler` CLI
- Cloudflare へログイン済みのローカル環境
- このリポジトリの `d1/migrations/0001_initial_schema.sql`

参考:

- Cloudflare D1 docs  
  https://developers.cloudflare.com/d1/
- Wrangler docs  
  https://developers.cloudflare.com/workers/wrangler/

---

## 全体の流れ

1. `wrangler` を使える状態にする
2. D1 データベースを作成する
3. `wrangler.jsonc` または `wrangler.toml` に D1 binding を追加する
4. ローカルで SQL を適用する
5. テーブルが作成されたか確認する
6. リモートの D1 に SQL を適用する
7. 管理ツールや Workers から参照できるようにする

---

## 1. Wrangler を使える状態にする

Cloudflare CLI が未導入の場合は、公式手順に沿って `wrangler` を導入する。

ログイン:

```powershell
wrangler login
```

これでブラウザ認証が始まる。

バージョン確認:

```powershell
wrangler --version
```

---

## 2. D1 データベースを作成する

例として、`arg-admin-db` という名前で作る。

```powershell
wrangler d1 create arg-admin-db
```

実行すると、次のような情報が返る。

- database name
- database id
- binding 名の例
- `wrangler.jsonc` または `wrangler.toml` に追記する設定例

この時に出る `database_id` は控えておく。

---

## 3. Wrangler 設定に D1 binding を追加する

Cloudflare Workers や Pages Functions から D1 を使うには binding 設定が必要。

`wrangler.jsonc` を使う例:

```json
{
  "name": "arg-admin",
  "main": "workers/admin-api/index.js",
  "compatibility_date": "2026-03-27",
  "d1_databases": [
    {
      "binding": "DB",
      "database_name": "arg-admin-db",
      "database_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    }
  ]
}
```

`binding` は Worker 側で使う変数名。

例:

```js
env.DB
```

---

## 4. ローカルで SQL を適用する

まずはローカルDB相当で試す。

```powershell
wrangler d1 execute arg-admin-db --local --file .\d1\migrations\0001_initial_schema.sql
```

この手順の目的:

- SQL 構文エラーの早期発見
- テーブル作成の確認
- 本番反映前の安全確認

---

## 5. ローカルでテーブルを確認する

テーブル一覧確認:

```powershell
wrangler d1 execute arg-admin-db --local --command "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;"
```

例として `args` を確認:

```powershell
wrangler d1 execute arg-admin-db --local --command "PRAGMA table_info(args);"
```

`published_snapshots` を確認:

```powershell
wrangler d1 execute arg-admin-db --local --command "PRAGMA table_info(published_snapshots);"
```

---

## 6. リモートの D1 に適用する

ローカルで問題がなければ、本番側へ適用する。

```powershell
wrangler d1 execute arg-admin-db --remote --file .\d1\migrations\0001_initial_schema.sql
```

適用後に確認:

```powershell
wrangler d1 execute arg-admin-db --remote --command "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;"
```

---

## 7. 運用時の基本ルール

### 1. いきなり本番へ流さない

推奨順:

1. ローカルで SQL を確認
2. ステージング相当の D1 へ適用
3. 問題なければ本番適用

### 2. 既存テーブル変更は新しい migration に分ける

初回以降は `0002_*.sql`, `0003_*.sql` とファイルを増やす。

例:

```text
d1/migrations/
  0001_initial_schema.sql
  0002_add_tags.sql
  0003_add_preview_tokens.sql
```

### 3. 既存本番データ前提では DROP を避ける

本番にデータが入った後は、安易に `DROP TABLE` や破壊的変更をしない。

---

## 推奨 migration 命名規則

```text
0001_initial_schema.sql
0002_add_assets_table.sql
0003_add_tags_tables.sql
0004_add_preview_tokens.sql
```

ポイント:

- 先頭は4桁連番
- 何を追加したかファイル名でわかる

---

## D1 でよく使う確認コマンド

## テーブル一覧

```powershell
wrangler d1 execute arg-admin-db --remote --command "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;"
```

## インデックス一覧

```powershell
wrangler d1 execute arg-admin-db --remote --command "SELECT name, tbl_name FROM sqlite_master WHERE type='index' ORDER BY tbl_name, name;"
```

## カラム確認

```powershell
wrangler d1 execute arg-admin-db --remote --command "PRAGMA table_info(puzzle_revisions);"
```

## 外部キー確認

```powershell
wrangler d1 execute arg-admin-db --remote --command "PRAGMA foreign_key_list(published_snapshots);"
```

---

## 初回投入後に確認したいこと

- `args` テーブルが作成されている
- `stories` と `puzzles` が作成されている
- `story_revisions` と `puzzle_revisions` が作成されている
- `published_snapshots` が作成されている
- `audit_logs` が作成されている
- 主要 index が作成されている

---

## Workers / Pages Functions からの利用イメージ

Cloudflare Worker 側では、たとえば次のように binding から DB を参照する。

```js
export default {
  async fetch(request, env) {
    const result = await env.DB
      .prepare("SELECT id, slug, title, status FROM args ORDER BY created_at DESC")
      .all();

    return Response.json(result);
  }
};
```

---

## トラブル時の切り分け

## SQL エラーが出る場合

- まず `--local` で実行して再現する
- SQL ファイルの文末セミコロンを確認する
- `CHECK` 制約や `FOREIGN KEY` の参照先を確認する

## テーブルが見えない場合

- `--local` と `--remote` を取り違えていないか確認する
- 作成した DB 名が一致しているか確認する

## Worker から参照できない場合

- `wrangler` の binding 名が正しいか確認する
- `wrangler.jsonc` / `wrangler.toml` の `database_id` を確認する
- Worker 側コードで `env.DB` を使っているか確認する

---

## 今後のおすすめ作業

1. `seed` 用 SQL を作る
2. `args` / `stories` / `puzzles` の CRUD API 設計をする
3. CMS 入力項目と DB カラムを対応づける
4. `published_snapshots` を読む generator を作る
5. 公開処理のジョブフローを固める

---

## まとめ

Cloudflare D1 への適用は、次の順で進めるのが安全。

1. `wrangler login`
2. `wrangler d1 create`
3. D1 binding 設定
4. `--local` で migration 適用
5. 動作確認
6. `--remote` で本番適用

この流れにしておけば、CMS や公開処理の実装に進む前の土台を安定させやすい。
