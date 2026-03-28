# CMS API Design

最終更新: 2026-03-27

## 目的

ARG 管理 CMS の API 設計を整理する。

この設計の前提:

- 認証は `メールアドレス + パスワード`
- Cloudflare Workers 上で API を提供する
- データ保存先は Cloudflare D1
- `Story` と `Puzzle` は DB 正本
- 公開時は snapshot を切って静的生成し、Cloudflare Pages に反映する

---

## 基本方針

### 1. CMS API と公開サイトを分ける

CMS API は管理用途のみ。

- ログイン
- 作品作成
- Story / Puzzle 編集
- 公開確認
- 公開実行
- ユーザー管理

プレイヤー向け本編の API とは分離する。

### 2. 認証必須

CMS API は原則すべて認証必須。  
例外はログイン API のみ。

### 3. revision と snapshot を意識した API にする

Story / Puzzle は単純上書きではなく、revision を作る前提で扱う。

### 4. 初期は REST 風でよい

初期実装では REST 風のエンドポイントにする。

---

## API 一覧

## 認証系

- `POST /api/auth/login`
- `POST /api/auth/logout`
- `GET /api/auth/me`

## 作品管理

- `GET /api/args`
- `POST /api/args`
- `GET /api/args/:argId`
- `PATCH /api/args/:argId`
- `GET /api/args/:argId/publish-check`
- `POST /api/args/:argId/publish`
- `GET /api/args/:argId/publish-history`

## ストーリー管理

- `GET /api/args/:argId/story`
- `POST /api/args/:argId/story/revisions`
- `GET /api/args/:argId/story/revisions`
- `GET /api/args/:argId/story/revisions/:revisionId`

## パズル管理

- `GET /api/args/:argId/puzzles`
- `POST /api/args/:argId/puzzles`
- `GET /api/args/:argId/puzzles/:puzzleId`
- `PATCH /api/args/:argId/puzzles/:puzzleId`
- `POST /api/args/:argId/puzzles/:puzzleId/revisions`
- `GET /api/args/:argId/puzzles/:puzzleId/revisions`
- `GET /api/args/:argId/puzzles/:puzzleId/revisions/:revisionId`

## ユーザー管理

- `GET /api/users`
- `POST /api/users`
- `PATCH /api/users/:userId`
- `PATCH /api/users/:userId/password`

## テンプレ管理

- `GET /api/templates/story`
- `GET /api/templates/puzzles`

---

## 共通レスポンス方針

### 成功時

```json
{
  "ok": true,
  "data": {}
}
```

### 失敗時

```json
{
  "ok": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "title is required"
  }
}
```

---

## 認証系 API

## `POST /api/auth/login`

### 目的

- メールアドレス + パスワードでログインする

### request

```json
{
  "email": "admin@example.com",
  "password": "plain-password"
}
```

### response

```json
{
  "ok": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "admin@example.com",
      "displayName": "Initial Admin",
      "role": "admin"
    }
  }
}
```

### 処理概要

- `users` を取得
- `password_hash` を照合
- `sessions` 作成
- `last_login_at` 更新

---

## `POST /api/auth/logout`

### 目的

- 現在のセッションを失効させる

### response

```json
{
  "ok": true,
  "data": {
    "loggedOut": true
  }
}
```

---

## `GET /api/auth/me`

### 目的

- 現在ログイン中ユーザを返す

### response

```json
{
  "ok": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "admin@example.com",
      "displayName": "Initial Admin",
      "role": "admin"
    }
  }
}
```

---

## 作品管理 API

## `GET /api/args`

### 目的

- 作品一覧を返す

### query 例

- `status`
- `q`

### response

```json
{
  "ok": true,
  "data": {
    "items": [
      {
        "id": "uuid",
        "title": "失踪記録保管庫",
        "slug": "archive-of-missing-log",
        "status": "draft",
        "storyReady": true,
        "puzzleCount": 4,
        "lastPublishedAt": null
      }
    ]
  }
}
```

---

## `POST /api/args`

### 目的

- 新規作品を作成する

### request

```json
{
  "title": "失踪記録保管庫",
  "subtitle": "Archive of Missing Log",
  "summary": "記録保管庫を調べる短編ARG",
  "slug": "archive-of-missing-log",
  "genre": "investigation",
  "difficulty": 2,
  "estimatedMinutes": 30
}
```

### response

```json
{
  "ok": true,
  "data": {
    "arg": {
      "id": "uuid",
      "status": "draft"
    }
  }
}
```

---

## `GET /api/args/:argId`

### 目的

- 作品詳細を返す

### response に含めたいもの

- 基本情報
- Story の有無
- Puzzle 数
- 公開状態
- 現在公開中 snapshot

---

## `PATCH /api/args/:argId`

### 目的

- 作品情報を更新する

### 更新対象

- title
- subtitle
- summary
- slug
- genre
- difficulty
- estimatedMinutes
- status

---

## `GET /api/args/:argId/publish-check`

### 目的

- 公開可能かどうか確認する

### response

```json
{
  "ok": true,
  "data": {
    "canPublish": true,
    "checks": [
      {
        "key": "story_exists",
        "status": "ok",
        "message": "Story is ready"
      },
      {
        "key": "puzzles_ready",
        "status": "ok",
        "message": "Required puzzles are enabled"
      }
    ],
    "storyRevisionId": "uuid",
    "puzzleRevisionIds": [
      "uuid-1",
      "uuid-2"
    ]
  }
}
```

---

## `POST /api/args/:argId/publish`

### 目的

- snapshot を作成して公開ジョブを開始する

### request

```json
{
  "confirm": true
}
```

### response

```json
{
  "ok": true,
  "data": {
    "snapshotId": "uuid",
    "publishJobId": "uuid",
    "status": "queued"
  }
}
```

### 処理概要

- publish-check 実行
- snapshot 作成
- publish_job 作成
- generator / deploy フローへ渡す

---

## `GET /api/args/:argId/publish-history`

### 目的

- 公開履歴一覧を返す

---

## ストーリー管理 API

## `GET /api/args/:argId/story`

### 目的

- 作品に紐づく現在の Story 状態を返す

### response

- story 本体
- current revision
- revision 一覧の概要

---

## `POST /api/args/:argId/story/revisions`

### 目的

- Story の新 revision を作成する

### request

```json
{
  "title": "失踪記録保管庫",
  "worldOverview": [],
  "playerRole": [],
  "characters": [],
  "progression": [],
  "endings": [],
  "atmosphere": [],
  "authorNote": "初稿",
  "changeSummary": "初回作成"
}
```

### response

```json
{
  "ok": true,
  "data": {
    "revisionId": "uuid",
    "revisionNumber": 1
  }
}
```

---

## `GET /api/args/:argId/story/revisions`

### 目的

- Story revision 一覧を返す

---

## `GET /api/args/:argId/story/revisions/:revisionId`

### 目的

- 特定 revision の詳細を返す

---

## パズル管理 API

## `GET /api/args/:argId/puzzles`

### 目的

- 作品に紐づく Puzzle 一覧を返す

### response に含めたいもの

- puzzle id
- puzzle_key
- title
- display_order
- puzzle_type
- is_enabled
- current revision

---

## `POST /api/args/:argId/puzzles`

### 目的

- 新規 Puzzle を追加する

### request

```json
{
  "puzzleKey": "puzzle-1",
  "title": "導入アクロスティック",
  "displayOrder": 1,
  "puzzleType": "acrostic"
}
```

---

## `GET /api/args/:argId/puzzles/:puzzleId`

### 目的

- Puzzle 詳細を返す

---

## `PATCH /api/args/:argId/puzzles/:puzzleId`

### 目的

- Puzzle 本体メタ情報を更新する

### 更新対象

- title
- display_order
- puzzle_type
- is_enabled

---

## `POST /api/args/:argId/puzzles/:puzzleId/revisions`

### 目的

- Puzzle の新 revision を作成する

### request

```json
{
  "title": "導入アクロスティック",
  "objective": "違和感に気づかせる",
  "locationPageKey": "intro",
  "problemText": "各行の先頭文字を読んでください",
  "displayContent": {},
  "hints": [],
  "answerMode": "multiple",
  "acceptedAnswers": ["なぞしろ", "NAZOSHIRO"],
  "solutionText": "各行の先頭を読む",
  "nextAction": {
    "type": "link",
    "targetPageKey": "case-file"
  },
  "uiConfig": {},
  "validationRule": {},
  "authorNote": "初稿",
  "changeSummary": "初回作成",
  "isRequired": true
}
```

---

## `GET /api/args/:argId/puzzles/:puzzleId/revisions`

### 目的

- Puzzle revision 一覧を返す

---

## `GET /api/args/:argId/puzzles/:puzzleId/revisions/:revisionId`

### 目的

- 特定 Puzzle revision を返す

---

## ユーザー管理 API

## `GET /api/users`

### 目的

- CMS 利用者一覧を返す

### 権限

- `admin` のみ

---

## `POST /api/users`

### 目的

- CMS 利用者を追加する

### 権限

- `admin` のみ

### request

```json
{
  "email": "editor@example.com",
  "displayName": "Editor User",
  "password": "initial-password",
  "role": "editor",
  "status": "active"
}
```

### 処理概要

- password を hash 化
- users に登録

---

## `PATCH /api/users/:userId`

### 目的

- 表示名、ロール、状態を更新する

### 権限

- `admin` のみ

---

## `PATCH /api/users/:userId/password`

### 目的

- パスワードを再設定する

### 権限

- `admin` のみ

---

## テンプレ API

## `GET /api/templates/story`

### 目的

- Story 用テンプレ一覧を返す

### 備考

- 初期は固定 JSON を返してよい

---

## `GET /api/templates/puzzles`

### 目的

- Puzzle 用テンプレ一覧を返す

### 返したい種類

- acrostic
- sort
- hidden-link
- input-code

---

## 権限制御の考え方

## admin

- 全API利用可

## editor

- 認証系
- 作品管理
- Story / Puzzle 管理
- 公開不可
- ユーザー管理不可

## reviewer

- 認証系
- 閲覧系
- publish-check は可
- publish 実行は要検討

---

## バリデーションの考え方

共通:

- UUID 形式確認
- 必須項目確認
- 文字数制限
- role / status / answer_mode などは列挙値チェック

公開前:

- Story が存在する
- Puzzle が1件以上ある
- 必須 Puzzle が有効
- slug がある
- 現行 revision が取得できる

---

## 初期実装で優先する API

優先度高:

1. `POST /api/auth/login`
2. `POST /api/auth/logout`
3. `GET /api/auth/me`
4. `GET /api/args`
5. `POST /api/args`
6. `PATCH /api/args/:argId`
7. `GET /api/args/:argId/story`
8. `POST /api/args/:argId/story/revisions`
9. `GET /api/args/:argId/puzzles`
10. `POST /api/args/:argId/puzzles`
11. `POST /api/args/:argId/puzzles/:puzzleId/revisions`
12. `GET /api/args/:argId/publish-check`
13. `POST /api/args/:argId/publish`
14. `GET /api/users`
15. `POST /api/users`

---

## まとめ

この API 設計では、

- 認証
- 作品管理
- Story revision 管理
- Puzzle revision 管理
- 公開確認 / 公開実行
- ユーザー管理

を CMS の初期機能としてカバーする。
