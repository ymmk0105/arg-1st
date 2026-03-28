# Cloudflare Pages Monorepo Plan

最終更新: 2026-03-27

## 目的

Cloudflare Pages を前提に、短編ARGを量産・運用しやすい monorepo 構成を整理する。

この文書の前提:

- 公開基盤は Cloudflare Pages
- 収益化のため、広告やアフィリエイト掲載を想定する
- 公開物は静的サイトとして配信する
- 将来的に CMS や管理画面を追加する
- 複数作品を継続的に増やしていく

---

## 基本方針

### 1. `Story` と `Puzzle` の正本は DB

管理ツールから登録・編集する `Story` と `Puzzle` は DB に保存する。  
変更履歴も DB に残し、公開時には DB のスナップショットから静的生成する。

理由:

- 管理画面と相性が良い
- 入力途中の保存がしやすい
- 検索や一覧管理がしやすい
- 履歴をDBで一元管理できる

### 2. 公開物は静的生成

プレイヤーに見せるサイトは、構造化データから生成した静的HTML/CSS/JSとする。

理由:

- Cloudflare Pages と相性が良い
- 作品数が増えても配信が軽い
- ブラウザだけで完結するARGの要件と合う

### 3. 公開時は snapshot を固定する

プレイヤーが見る内容は、常に「公開済み snapshot」から生成する。  
編集中データをそのまま本番表示に使わない。

理由:

- 公開事故を防ぎやすい
- どの版が公開中か追いやすい
- 差し戻しや再公開がしやすい

---

## 推奨 monorepo 構成

```text
repo/
├─ apps/
│  ├─ public-site/
│  └─ admin-cms/
├─ packages/
│  ├─ db-schema/
│  ├─ site-generator/
│  ├─ puzzle-engine/
│  └─ shared-utils/
├─ generated/
│  ├─ archive-of-missing-log/
│  └─ another-title/
├─ docs/
│  ├─ HOSTING-STRATEGY.md
│  └─ CLOUDFLARE-MONOREPO-PLAN.md
├─ workers/
│  └─ admin-api/
├─ d1/
│  └─ migrations/
└─ scripts/
```

---

## ディレクトリごとの役割

## `apps/public-site/`

Cloudflare Pages にデプロイする公開サイトの入口。

役割:

- 作品一覧ページ
- 各ARGへの導線
- 生成済み静的ファイルの公開用ルート
- 広告枠や共通導線の管理

このディレクトリには「プレイヤーに見せるもの」だけを置く。

---

## `apps/admin-cms/`

制作者向けの管理画面。

役割:

- 新規ARGの作成
- ストーリー入力
- 謎入力
- ヒント入力
- プレビュー
- 公開操作

最初は未実装でもよい。  
将来的に Cloudflare Pages + Workers + D1 で動かす候補。

---

## `packages/db-schema/`

DB構造とルールをまとめる場所。

役割:

- `stories` テーブル設計
- `puzzles` テーブル設計
- `story_revisions` テーブル設計
- `puzzle_revisions` テーブル設計
- `published_snapshots` テーブル設計
- バリデーション
- 必須項目チェック

ここを先に固めることで、CMS と generator の両方が安定する。

---

## `packages/site-generator/`

DB の公開スナップショットから静的ファイルを生成する中核。

役割:

- 作品ごとのHTML生成
- 共通テンプレート適用
- CSS/JSの共通化
- 作品一覧の自動生成
- Cloudflare Pages 公開用ディレクトリの出力

量産性の中心はここにある。

---

## `packages/puzzle-engine/`

謎解きUIの共通処理をまとめる場所。

役割:

- 入力判定
- 段階ヒント
- localStorage進行補助
- クリック探索
- 共通UI部品

各作品で毎回JSを作り直さないための共通基盤。

---

## `packages/shared-utils/`

共通関数置き場。

役割:

- slug 生成
- 文字列正規化
- 日付整形
- データ変換

---

## `generated/`

生成結果の出力先。

役割:

- 各作品の静的HTML
- 作品固有アセットのコピー
- 公開用最終成果物

この内容を Cloudflare Pages の公開対象として扱う。

---

## `workers/admin-api/`

将来 CMS を付ける場合の API 層。

役割:

- 下書き保存
- revision 作成
- 認証
- 公開予約
- プレビュー発行
- D1 との接続

---

## `d1/migrations/`

Cloudflare D1 のマイグレーション管理。

役割:

- `args`
- `stories`
- `puzzles`
- `story_revisions`
- `puzzle_revisions`
- `published_snapshots`
- `publish_jobs`
- `audit_logs`

---

## 公開URLの考え方

## パターンA: 1つのサイトで複数ARGを公開

例:

```text
https://example.com/
https://example.com/args/archive-of-missing-log/
https://example.com/args/another-title/
```

### メリット

- 運用が楽
- 共通ヘッダや広告枠を管理しやすい
- Cloudflare Pages プロジェクト数が増えない

### デメリット

- 作品ごとの完全独立感はやや下がる

### 推奨度

- 最初の構成として最もおすすめ

---

## パターンB: 作品ごとに別サイト

例:

```text
https://arg-a.example.com/
https://arg-b.example.com/
```

### メリット

- 作品ごとの独立性が高い
- ブランディングしやすい

### デメリット

- 管理が煩雑
- 広告設定や分析設定の重複が増える

### 推奨度

- 作品数が少ない間は不要

---

## 推奨公開構成

最初はパターンAにする。

つまり:

- 1つの Cloudflare Pages プロジェクト
- その中に複数作品を配置
- `/args/<slug>/` 形式で各作品を公開

---

## データ管理方針

## 正本

- D1 上の `Story` / `Puzzle`

## 履歴管理

- revision テーブル
- 公開 snapshot テーブル
- audit log

## 公開フロー

1. CMS で作品データを編集
2. DB に revision を保存
3. 公開操作で snapshot を確定
4. snapshot を generator に渡す
5. `generated/` を更新
6. Cloudflare Pages にデプロイ

---

## Cloudflare Pages 前提の構成イメージ

### 初期段階

- Cloudflare Pages
- site generator
- admin-cms
- D1

この段階から DB 正本で始める。

### 中期段階

- Cloudflare Pages
- site generator
- admin-cms
- Workers API
- D1

### 発展段階

- Cloudflare Pages
- Workers
- D1
- admin-cms
- プレビュー公開
- 公開予約
- 監査ログ

---

## 運用ルール案

## 作品ごとの slug

- すべて英小文字 + ハイフン
- 例: `archive-of-missing-log`

## DB 内で持つべき主要単位

- 1作品 = 1 `arg`
- 1作品に対して 1 `story`
- 1作品に対して複数 `puzzle`
- 変更のたびに `revision`
- 公開のたびに `snapshot`

## 共通ルール

- 共通CSSやJSは generator または共通パッケージで管理
- 作品独自コードは最小限
- 謎の答え、ヒント、導線は構造化して保持
- 本番反映は必ず snapshot 経由にする

---

## 最初に作るべきもの

実装順は以下を推奨する。

1. `db-schema`
2. `site-generator`
3. `D1` の revision / snapshot テーブル
4. `admin-cms`
5. `apps/public-site/`
6. Cloudflare Pages 連携
7. `Workers`

重要なのは、先に `DB schema` と `snapshot からの generator` を完成させること。

CMS を先に作ると、入力UIだけできて公開仕様が固まらない危険がある。

---

## 技術選定の考え方

この monorepo は Cloudflare Pages 前提だが、公開物は最終的に静的ファイルであることを維持する。

理由:

- 表示は速い
- 障害点が少ない
- ARG本編をサーバー依存にしなくてよい
- コストを抑えやすい

管理系だけを動的にし、プレイヤー向け本編は静的に保つのが基本。

---

## 将来的な拡張案

- 公開予約
- 制作途中プレビュー
- 作品タグ付け
- 難易度検索
- テンプレート複製で新作作成
- 広告枠の共通管理
- 解析タグの一元管理

---

## まとめ

Cloudflare Pages 前提で量産するなら、以下の考え方が扱いやすい。

- monorepo で管理する
- `Story` と `Puzzle` の正本は DB に置く
- 履歴は revision と audit log で残す
- 公開時は snapshot を固定する
- generator で静的出力する
- Pages には静的成果物を公開する

この構成なら、管理画面中心で運用しつつ、公開物は静的で安定させられる。
