# CMS Flow Design

最終更新: 2026-03-27

## 目的

ARG 管理 CMS の操作フローと公開フローを整理する。

---

## 基本フロー

1. 管理者がログインする
2. 作品管理で作品を新規作成する
3. 作品 UUID が発行される
4. ストーリー管理でその UUID に紐づく Story を作成する
5. パズル管理でその UUID に紐づく複数 Puzzle を作成する
6. 必要条件を満たすと作品管理で `公開確認` が有効になる
7. `公開確認` で対象 revision と出力内容を確認する
8. `公開実行` で snapshot を確定する
9. generator が静的ファイルを生成する
10. Cloudflare Pages にデプロイする

---

## 詳細フロー

## 1. ログインフロー

```text
ログイン画面
  ↓ メールアドレス + パスワード入力
認証成功
  ↓
作品管理画面
```

失敗時:

- エラーメッセージ表示
- ログイン画面に留まる

---

## 2. 作品作成フロー

```text
作品管理
  ↓ 新規作成
タイトル、slug などを入力
  ↓ 保存
作品 UUID 発行
  ↓
作品詳細表示
```

結果:

- `args` レコード作成
- ステータスは `draft`

---

## 3. ストーリー作成フロー

```text
作品管理
  ↓ ストーリー管理へ移動
Story 編集
  ↓ 下書き保存
story revision 作成
```

ポイント:

- 1作品につき Story は1件
- 変更は revision として増える

---

## 4. パズル作成フロー

```text
作品管理
  ↓ パズル管理へ移動
Puzzle を追加
  ↓ 下書き保存
puzzle revision 作成
  ↓ 必要数だけ繰り返す
```

ポイント:

- 1作品に複数 Puzzle を持てる
- Puzzle は個別に revision を持つ
- 並び順とページ配置を持つ

---

## 5. 公開可否判定フロー

`作品管理` で、次を満たしたら `公開確認` を有効にする。

- 作品タイトルあり
- slug あり
- Story あり
- Puzzle が1件以上ある
- 必須 Puzzle がすべて有効
- 作品ステータスが `review` または `published`

---

## 6. 公開確認フロー

```text
作品管理
  ↓ 公開確認
公開確認モーダル表示
  ↓
使用する revision 群を確認
  ↓
不足項目チェック
  ↓ 問題なし
公開実行へ
```

表示したい項目:

- 作品 UUID
- タイトル
- Story revision 番号
- Puzzle revision 一覧
- 生成されるページ一覧
- 画像・アセットの有無
- 公開予定URL

---

## 7. 公開実行フロー

```text
公開実行
  ↓
published_snapshot 作成
  ↓
publish_job 作成
  ↓
generator 実行
  ↓
HTML / CSS / JS / assets 出力
  ↓
Cloudflare Pages へデプロイ
  ↓
公開成功
```

結果:

- `published_snapshots` に対象版を固定
- `publish_jobs` にジョブ記録
- `args.current_published_snapshot_id` を更新
- `args.last_published_at` を更新

---

## 8. 再公開フロー

```text
既存作品を編集
  ↓
新 revision 作成
  ↓
公開確認
  ↓
公開実行
  ↓
新 snapshot 作成
```

ポイント:

- 既存公開物を直接上書きせず、新 snapshot として管理

---

## 9. ユーザ追加フロー

```text
admin がログイン
  ↓
ユーザー管理
  ↓
ユーザ追加
  ↓
メールアドレス、表示名、初期パスワード、ロール設定
  ↓
保存
```

結果:

- `users` テーブルに追加

---

## 10. テンプレ利用フロー

### ストーリー管理

```text
テンプレ表示を見る
  ↓
必要なテンプレを選ぶ
  ↓
テンプレ挿入
  ↓
編集して保存
```

### パズル管理

```text
パズル種類を選ぶ
  ↓
該当テンプレを表示
  ↓
テンプレ挿入
  ↓
内容を調整して保存
```

---

## ステータス遷移案

## 作品ステータス

```text
draft
  ↓
review
  ↓
published
  ↓
archived
```

### 意味

- `draft`: 制作中
- `review`: 公開候補
- `published`: 公開中
- `archived`: 公開終了

---

## エラー時の扱い

## 公開失敗

- `publish_jobs.status = failed`
- `published_snapshots.publish_status = failed`
- 直前の公開中 snapshot は維持する

## 不足項目あり

- 公開確認画面で不足一覧を表示
- 公開実行ボタンは無効

---

## まとめ

この CMS の基本フローは、

- 作品を作る
- Story を作る
- Puzzle を複数作る
- 公開確認する
- snapshot を切って公開する

という流れで統一する。
