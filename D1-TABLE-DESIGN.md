# D1 Table Design

最終更新: 2026-03-27

## 目的

Cloudflare D1 を使って、ARG 制作管理ツールのデータを保存するためのテーブル設計案を整理する。

この設計の前提:

- `Story` と `Puzzle` は DB を正本とする
- プレイヤー向け公開物は静的生成して Cloudflare Pages に載せる
- 変更履歴は DB に残す
- 公開時は snapshot を固定する
- 1つのサイトで複数ARGを管理する

---

## 設計方針

### 1. 編集中データと公開中データを分ける

編集中の最新状態をそのまま本番に使わない。  
公開時に snapshot を切り、その snapshot から静的生成する。

### 2. 履歴は revision テーブルで持つ

`Story` と `Puzzle` の本文更新履歴を revision として保存する。  
最新状態だけでなく、過去版も復元できるようにする。

### 3. 作品の単位は `arg`

1作品 = 1 `arg` とする。  
`story` や `puzzle` は必ず `arg` に属する。

### 4. 構造化データは JSON で保持する

長い本文やページ構成は JSON 文字列で持つ。  
完全な正規化より、管理画面と generator の扱いやすさを優先する。

---

## 推奨テーブル一覧

```text
args
stories
story_revisions
puzzles
puzzle_revisions
published_snapshots
publish_jobs
audit_logs
assets
users
```

最小構成で始めるなら、まずは以下でもよい。

```text
args
stories
story_revisions
puzzles
puzzle_revisions
published_snapshots
audit_logs
```

---

## 1. args

作品の基本情報を管理するテーブル。

### 役割

- 作品の親レコード
- slug 管理
- 公開状態の管理
- 一覧表示用の基本メタ情報

### カラム案

| column | type | required | note |
|---|---|---:|---|
| id | text | yes | UUID 推奨 |
| slug | text | yes | 一意。URL 用 |
| title | text | yes | 作品タイトル |
| subtitle | text | no | 英字副題など |
| summary | text | no | 一覧用短文 |
| status | text | yes | `draft` / `review` / `published` / `archived` |
| genre | text | no | 調査、記録、違和感 など |
| difficulty | integer | no | 1〜5 など |
| estimated_minutes | integer | no | 想定プレイ時間 |
| cover_asset_id | text | no | assets.id 参照 |
| current_story_revision_id | text | no | 現在編集中 story revision |
| current_published_snapshot_id | text | no | 現在公開中 snapshot |
| first_published_at | text | no | ISO8601 |
| last_published_at | text | no | ISO8601 |
| created_by | text | no | users.id |
| updated_by | text | no | users.id |
| created_at | text | yes | ISO8601 |
| updated_at | text | yes | ISO8601 |

### インデックス案

- unique index on `slug`
- index on `status`
- index on `last_published_at`

---

## 2. stories

各作品のストーリー本体を管理するテーブル。

### 役割

- 作品に属するストーリーの親レコード
- 現在の編集中リビジョンを指す

### カラム案

| column | type | required | note |
|---|---|---:|---|
| id | text | yes | UUID |
| arg_id | text | yes | args.id |
| current_revision_id | text | no | story_revisions.id |
| latest_revision_number | integer | yes | 連番管理 |
| created_by | text | no | users.id |
| updated_by | text | no | users.id |
| created_at | text | yes | ISO8601 |
| updated_at | text | yes | ISO8601 |

### 制約

- `arg_id` は unique にして、1作品に対して1 story を基本にする

---

## 3. story_revisions

ストーリーの版管理テーブル。

### 役割

- 編集履歴保存
- 差し戻し
- 公開候補の管理

### カラム案

| column | type | required | note |
|---|---|---:|---|
| id | text | yes | UUID |
| story_id | text | yes | stories.id |
| revision_number | integer | yes | 1, 2, 3... |
| title | text | yes | story タイトル |
| world_overview_json | text | no | 世界観 JSON |
| player_role_json | text | no | プレイヤー立場 JSON |
| characters_json | text | no | 登場人物 JSON |
| progression_json | text | no | 進行 JSON |
| endings_json | text | no | エンディング JSON |
| atmosphere_json | text | no | 雰囲気 JSON |
| author_note | text | no | 制作メモ |
| change_summary | text | no | この版で何を変えたか |
| is_published_source | integer | yes | 0 or 1 |
| created_by | text | no | users.id |
| created_at | text | yes | ISO8601 |

### JSON の想定

- `characters_json`: 配列
- `progression_json`: 配列
- `endings_json`: 配列

### インデックス案

- unique index on `(story_id, revision_number)`
- index on `created_at`

---

## 4. puzzles

作品に属する謎の親レコード。

### 役割

- 各 puzzle の管理単位
- 表示順や種別の管理

### カラム案

| column | type | required | note |
|---|---|---:|---|
| id | text | yes | UUID |
| arg_id | text | yes | args.id |
| puzzle_key | text | yes | `puzzle-1` など |
| display_order | integer | yes | 表示順 |
| puzzle_type | text | yes | `acrostic` / `sort` / `hidden-link` / `input-code` など |
| current_revision_id | text | no | puzzle_revisions.id |
| latest_revision_number | integer | yes | 連番 |
| created_by | text | no | users.id |
| updated_by | text | no | users.id |
| created_at | text | yes | ISO8601 |
| updated_at | text | yes | ISO8601 |

### 制約

- unique index on `(arg_id, puzzle_key)`
- unique index on `(arg_id, display_order)`

---

## 5. puzzle_revisions

謎の版管理テーブル。

### 役割

- 謎仕様の変更履歴
- ヒントや答えの差し替え
- 公開候補の追跡

### カラム案

| column | type | required | note |
|---|---|---:|---|
| id | text | yes | UUID |
| puzzle_id | text | yes | puzzles.id |
| revision_number | integer | yes | 連番 |
| title | text | yes | 謎タイトル |
| objective | text | no | この謎の目的 |
| location_page_key | text | no | `intro` など |
| problem_text | text | no | 問題文 |
| display_content_json | text | no | プレイヤーに見せる本文や素材 |
| hints_json | text | no | 段階ヒント配列 |
| answer_mode | text | yes | `single` / `multiple` / `link-only` |
| accepted_answers_json | text | no | 許容解配列 |
| solution_text | text | no | 解説 |
| next_action_json | text | no | 正解後導線 |
| ui_config_json | text | no | input placeholder など |
| validation_rule_json | text | no | 正規化や採点ルール |
| author_note | text | no | 制作メモ |
| change_summary | text | no | この版で何を変えたか |
| is_required | integer | yes | 0 or 1 |
| is_published_source | integer | yes | 0 or 1 |
| created_by | text | no | users.id |
| created_at | text | yes | ISO8601 |

### インデックス案

- unique index on `(puzzle_id, revision_number)`
- index on `location_page_key`

---

## 6. published_snapshots

公開単位を固定するためのテーブル。

### 役割

- どの story revision / puzzle revision 群で公開したかを保存
- 差し戻しや再公開の起点にする

### カラム案

| column | type | required | note |
|---|---|---:|---|
| id | text | yes | UUID |
| arg_id | text | yes | args.id |
| snapshot_version | integer | yes | 1, 2, 3... |
| story_revision_id | text | yes | story_revisions.id |
| puzzle_revision_map_json | text | yes | puzzle_id -> revision_id の JSON |
| page_config_json | text | no | ページ構成 JSON |
| output_config_json | text | no | 生成設定 |
| content_hash | text | no | 同一内容判定用 |
| publish_status | text | yes | `pending` / `building` / `published` / `failed` / `rolled_back` |
| deployed_url | text | no | デプロイ先URL |
| build_log | text | no | 簡易ログ |
| published_by | text | no | users.id |
| published_at | text | no | ISO8601 |
| created_at | text | yes | ISO8601 |

### インデックス案

- unique index on `(arg_id, snapshot_version)`
- index on `(arg_id, publish_status)`
- index on `published_at`

---

## 7. publish_jobs

公開処理のジョブ管理テーブル。

### 役割

- 公開ボタン押下後の処理状況を管理
- 再実行や失敗調査をしやすくする

### カラム案

| column | type | required | note |
|---|---|---:|---|
| id | text | yes | UUID |
| arg_id | text | yes | args.id |
| snapshot_id | text | yes | published_snapshots.id |
| job_type | text | yes | `publish` / `rollback` / `rebuild` |
| status | text | yes | `queued` / `running` / `succeeded` / `failed` |
| requested_by | text | no | users.id |
| started_at | text | no | ISO8601 |
| finished_at | text | no | ISO8601 |
| error_message | text | no | 失敗時 |
| log_json | text | no | 詳細ログ |
| created_at | text | yes | ISO8601 |

---

## 8. audit_logs

監査ログテーブル。

### 役割

- 誰が何を変更したか残す
- 履歴確認をしやすくする
- revision 作成とは別に操作履歴を持つ

### カラム案

| column | type | required | note |
|---|---|---:|---|
| id | text | yes | UUID |
| actor_user_id | text | no | users.id |
| action_type | text | yes | `create_arg` / `update_story` / `publish_snapshot` など |
| target_type | text | yes | `arg` / `story_revision` / `puzzle_revision` / `snapshot` |
| target_id | text | yes | 対象ID |
| arg_id | text | no | args.id |
| metadata_json | text | no | 差分要約など |
| created_at | text | yes | ISO8601 |

### インデックス案

- index on `arg_id`
- index on `actor_user_id`
- index on `created_at`

---

## 9. assets

作品に紐づく画像や添付情報の管理。

### 役割

- アップロードファイルの管理
- story / puzzle から参照する素材の台帳

### カラム案

| column | type | required | note |
|---|---|---:|---|
| id | text | yes | UUID |
| arg_id | text | yes | args.id |
| file_name | text | yes | 元ファイル名 |
| storage_key | text | yes | R2 等の保存先キー |
| mime_type | text | no | `image/png` など |
| file_size | integer | no | bytes |
| width | integer | no | 画像用 |
| height | integer | no | 画像用 |
| alt_text | text | no | 代替文 |
| uploaded_by | text | no | users.id |
| created_at | text | yes | ISO8601 |

---

## 10. users

管理ツール利用者。

### 役割

- 編集者識別
- 公開者記録
- 監査ログ紐付け

### カラム案

| column | type | required | note |
|---|---|---:|---|
| id | text | yes | UUID |
| email | text | yes | 一意 |
| display_name | text | yes | 表示名 |
| role | text | yes | `admin` / `editor` / `reviewer` |
| status | text | yes | `active` / `invited` / `disabled` |
| created_at | text | yes | ISO8601 |
| updated_at | text | yes | ISO8601 |

---

## リレーション概要

```text
args 1 - 1 stories
args 1 - n puzzles
stories 1 - n story_revisions
puzzles 1 - n puzzle_revisions
args 1 - n published_snapshots
published_snapshots 1 - n publish_jobs
args 1 - n assets
users 1 - n audit_logs
```

---

## JSON カラムの中身の例

## `characters_json`

```json
[
  {
    "name": "橘ユウ",
    "ruby": "たちばな ゆう",
    "role": "失踪した人物",
    "description": "自ら記録を残していた可能性がある"
  }
]
```

## `hints_json`

```json
[
  {
    "step": 1,
    "text": "文章の最初に注目してください"
  },
  {
    "step": 2,
    "text": "各行の先頭文字を順番に読んでください"
  }
]
```

## `next_action_json`

```json
{
  "type": "link",
  "target_page_key": "case-file",
  "label": "調査ログへ進む"
}
```

## `puzzle_revision_map_json`

```json
{
  "puzzle-1": "rev_uuid_1",
  "puzzle-2": "rev_uuid_9",
  "puzzle-3": "rev_uuid_15"
}
```

---

## 状態管理の考え方

## `args.status`

- `draft`: 制作中
- `review`: 確認待ち
- `published`: 公開中
- `archived`: 公開終了

## `published_snapshots.publish_status`

- `pending`: snapshot 作成済み
- `building`: 生成中
- `published`: 公開成功
- `failed`: 公開失敗
- `rolled_back`: 差し戻し済み

---

## 履歴管理の考え方

DB 正本で重要なのは、単に上書き保存しないこと。

### 推奨ルール

1. `stories` と `puzzles` は親テーブル
2. 本文や仕様変更は必ず revision を新規追加
3. 公開時は revision 群を束ねて snapshot を切る
4. 監査用途は audit_logs にも残す

これで以下が可能になる。

- いつ何を変えたか確認できる
- どの版が公開されていたか追える
- 過去の状態に差し戻せる
- 誤編集時の影響範囲を絞れる

---

## 最小実装で必要な SQL 対象

初期実装では次の順で作るとよい。

1. `args`
2. `stories`
3. `story_revisions`
4. `puzzles`
5. `puzzle_revisions`
6. `published_snapshots`
7. `audit_logs`

`publish_jobs`, `assets`, `users` は後から追加でもよい。

---

## 初期実装時の注意

- D1 は SQLite ベースなので、巨大 JSON を多用しすぎない
- 厳密な差分は DB ではなく `change_summary` と `audit_logs` で補助する
- answer や hint は管理画面で編集しやすい形で JSON 化する
- 公開物生成時は DB の live データではなく snapshot だけを読む
- URL slug は公開後に変更しない方針が安全

---

## 将来追加しやすい拡張

- `tags` テーブル
- `arg_tags` 中間テーブル
- `preview_tokens`
- `ad_slots`
- `analytics_settings`
- `seo_meta`
- `collaborators`
- `review_comments`

---

## まとめ

この設計では:

- `Story` と `Puzzle` は D1 を正本にする
- revision で履歴を持つ
- snapshot で公開単位を固定する
- Cloudflare Pages には静的生成結果を出す

これにより、管理ツール中心の運用と、静的サイトとしての安定公開を両立しやすくなる。
