# 失踪記録保管庫

ブラウザのみで遊べる短編ARGです。  
GitHub Pages でそのまま公開できる、HTML / CSS / JavaScript だけの静的サイトとして構成しています。

## 公開手順

### GitHub Actions で GitHub Pages に公開する場合

1. このリポジトリを GitHub に push します。
2. GitHub の `Settings` → `Pages` を開きます。
3. `Build and deployment` の `Source` で `GitHub Actions` を選びます。
4. `main` ブランチに push すると [`.github/workflows/deploy-pages.yml`](./.github/workflows/deploy-pages.yml) が実行されます。
5. Actions が成功すると、GitHub Pages に最新内容が反映されます。
6. 公開URLは `Settings` → `Pages` に表示されます。

### 補足

- このワークフローは静的ファイル一式をそのまま Pages 用 artifact としてデプロイします。
- ビルド工程はありません。
- 公開対象はリポジトリ直下全体です。`.git` は Actions の artifact 対象に含まれません。

## ローカル確認方法

`index.html` をブラウザで直接開くだけでも確認できます。  
相対パスのみで構成しているため、簡易確認であればローカルでもそのまま動作します。

## ディレクトリ構成

```text
.
├─ index.html
├─ intro.html
├─ case-file.html
├─ archive.html
├─ hidden-log.html
├─ ending.html
├─ .github/
│  └─ workflows/
│     └─ deploy-pages.yml
├─ css/
│  └─ style.css
├─ js/
│  └─ main.js
├─ STORY.md
├─ PUZZLES.md
├─ SPEC.md
└─ README.md
```

## ページ概要

- `index.html`: トップページ
- `intro.html`: 導入とアクロスティックの謎
- `case-file.html`: 日付並び替えの謎
- `archive.html`: 隠しリンク探索
- `hidden-log.html`: 最終パスコード入力
- `ending.html`: 真相の回収と隠し要素

## 実装メモ

- すべて相対パスでリンクしています。
- 共通スタイルは `css/style.css`、共通スクリプトは `js/main.js` にまとめています。
- ヒントは段階表示です。
- `localStorage` は進行表示の補助に使っていますが、使えない環境でもページを順番に進めればクリアできます。
- 外部API、ビルドツール、依存ライブラリは使用していません。

## 更新時の注意

- GitHub Pages 前提のため、絶対パスやビルド前提の構成は追加しないでください。
- 謎を変更する場合は、`STORY.md` と `PUZZLES.md` の整合も合わせて確認してください。
- プレイヤーが作中情報だけで解けること、ヒント導線があることを維持してください。
