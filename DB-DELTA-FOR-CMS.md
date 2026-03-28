# DB Delta For CMS

最終更新: 2026-03-27

## 目的

CMS 画面要件を踏まえて、既存の D1 テーブル設計に対して必要な追加・修正候補を整理する。

---

## 結論

現状の D1 設計で CMS の初期構成には概ね対応できる。  
ただし、次の差分は検討した方がよい。

---

## 1. users にパスワード関連カラムが必要

現状の `users` はプロフィール管理寄りなので、  
メールアドレス + パスワードログインを使うなら認証用カラムが必要。

### 追加候補

| column | type | required | note |
|---|---|---:|---|
| password_hash | text | yes | 平文保存しない |
| password_updated_at | text | no | 変更日時 |
| last_login_at | text | no | 最終ログイン |
| failed_login_count | integer | yes | 初期値0 |

---

## 2. sessions テーブル追加を推奨

ログイン状態を管理するため、セッションテーブルを追加した方がよい。

### 追加候補テーブル

`sessions`

### カラム案

| column | type | required | note |
|---|---|---:|---|
| id | text | yes | UUID |
| user_id | text | yes | users.id |
| session_token_hash | text | yes | トークン平文は持たない |
| expires_at | text | yes | ISO8601 |
| created_at | text | yes | ISO8601 |
| revoked_at | text | no | 失効時刻 |

---

## 3. args に公開可否判定用の補助カラムがあると便利

公開可否を毎回重い集計で出すより、補助状態を持つ選択肢がある。

### 候補

| column | type | required | note |
|---|---|---:|---|
| has_story_ready | integer | no | 0 / 1 |
| ready_puzzle_count | integer | no | 公開可能 puzzle 数 |
| publish_check_status | text | no | `ok` / `warning` / `error` |

ただし初期段階では、アプリ側計算でもよい。

---

## 4. puzzles に有効状態カラムがあると扱いやすい

公開条件に「必須 Puzzle がすべて有効」があるため、  
Puzzle 単位の有効状態を持つと分かりやすい。

### 追加候補

| column | type | required | note |
|---|---|---:|---|
| is_enabled | integer | yes | 0 / 1 |

---

## 5. published_snapshots に確認情報を残すと便利

公開確認画面の結果を snapshot 側にも残すと後で追いやすい。

### 追加候補

| column | type | required | note |
|---|---|---:|---|
| validation_result_json | text | no | 公開前チェック結果 |

---

## 6. template 管理は別テーブル化するか検討余地あり

ストーリーとパズルのテンプレ表示 + 挿入を行うなら、  
テンプレ自体を DB 管理する選択肢もある。

### 初期段階

- アプリ内の固定JSONでもよい

### 将来的な追加候補

`templates`

| column | type | required | note |
|---|---|---:|---|
| id | text | yes | UUID |
| template_type | text | yes | `story` / `puzzle` |
| template_key | text | yes | 一意キー |
| title | text | yes | 表示名 |
| body_json | text | yes | テンプレ内容 |
| created_at | text | yes | ISO8601 |
| updated_at | text | yes | ISO8601 |

---

## 7. 初期管理者投入方法を決める必要がある

要件上、最初はあなたのアカウントだけログイン可能にする。  
そのため、初期管理者の作成方法を決める必要がある。

### 方法案

1. seed SQL で `users` に admin を1件投入する
2. 初回起動時だけ管理者作成画面を出す

### 推奨

- 初期は seed SQL で投入

---

## 8. Cloudflare Pages への公開方法に関する補足

要件上の理解は次でよい。

- 公開確認
- 公開実行
- HTML / CSS / JS / 画像など必要ファイル生成
- push または deploy トリガー
- Cloudflare Pages に反映

ただし実装方式としては2案ある。

### 案A

- generator が成果物を作る
- Git に反映
- Git push をトリガーに Pages デプロイ

### 案B

- generator が成果物を作る
- Direct Upload 系で Pages へデプロイ

### 注意

- Cloudflare Pages は Git integration と Direct Upload を後から切り替えられない

---

## 初期CMS向けの推奨差分

最初に足すなら次を優先する。

1. `users.password_hash`
2. `users.last_login_at`
3. `users.failed_login_count`
4. `sessions` テーブル
5. `puzzles.is_enabled`

---

## まとめ

CMS 初期実装に向けては、既存 DB 設計を大きく壊す必要はない。  
必要なのは主に次の追加である。

- ログイン用の認証情報
- セッション管理
- Puzzle の有効状態
- 必要ならテンプレ管理
