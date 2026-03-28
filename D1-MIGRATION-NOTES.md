# D1 Migration Notes

最終更新: 2026-03-27

## 追加したもの

- `d1/migrations/0001_initial_schema.sql`

この SQL は、ARG 管理ツール向け D1 の初期マイグレーション草案です。

---

## 含めたテーブル

- `users`
- `args`
- `stories`
- `story_revisions`
- `puzzles`
- `puzzle_revisions`
- `published_snapshots`
- `publish_jobs`
- `audit_logs`
- `assets`

---

## この草案の意図

### 1. DB 正本を前提にする

`Story` と `Puzzle` は DB に保存し、revision で履歴を持つ構成です。

### 2. 公開は snapshot 単位に固定する

公開時点の `story_revision` と `puzzle_revision` 群を `published_snapshots` に束ねます。

### 3. プレイヤー向け公開物は静的生成を想定する

この SQL 自体は公開処理を持ちませんが、`published_snapshots` と `publish_jobs` を通じて、  
「どの内容を静的生成して公開したか」を追跡できるようにしています。

---

## 実装時の注意

- D1 は SQLite ベースなので、JSON は `TEXT` として保存しています
- `current_story_revision_id` や `current_published_snapshot_id` には、初回作成時は NULL が入ります
- 相互参照を厳密な外部キーで閉じると migration 順序が重くなるため、初期草案では一部を論理参照にしています
- puzzle ごとの公開版は `puzzle_revision_map_json` で保持しています

---

## 次にやるとよいこと

1. seed 用のサンプルデータ SQL を作る
2. Cloudflare D1 用の投入コマンド前提で手順書を書く
3. この schema に合わせた CMS の入力項目定義を作る
4. snapshot を読む generator 側 I/O を決める

---

## 将来の追加候補

- `tags`
- `arg_tags`
- `preview_tokens`
- `review_comments`
- `seo_meta`
- `ad_slots`

---

## まとめ

この初期マイグレーション草案で、次の運用に入れる状態を想定しています。

- 作品作成
- story / puzzle の revision 管理
- snapshot 作成
- 公開ジョブ管理
- 監査ログ記録
