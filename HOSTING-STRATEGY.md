# Hosting Strategy Memo

最終更新: 2026-03-27

## 目的

短編ARGを量産・公開するにあたり、ホスティング選定の判断軸を整理する。

最優先要件:

- 広告掲載やアフィリエイト導線を置けること
- 静的サイトを安定して公開できること
- 将来的にCMSや管理画面と連携しやすいこと
- 複数作品の運用や差し替えがしやすいこと

---

## 現時点の結論

### 第一候補

- Cloudflare Pages
- Netlify

どちらも静的サイト運用に向いており、将来のCMS化にもつなげやすい。

### 条件付き候補

- Firebase Hosting
- AWS Amplify Hosting

商用運用との相性は悪くないが、個人〜小規模で始めるにはやや運用コストが高め。

### 非推奨または優先度低

- GitHub Pages
- Vercel Hobby

GitHub Pages は商用サイト用途との相性が弱い。  
Vercel Hobby は非商用前提で、広告掲載を行うなら不向き。

---

## サービス別メモ

## 1. Cloudflare Pages

### 判断

- 有力候補

### 理由

- Cloudflare の Self-Serve Subscription Agreement では、違法行為や権利侵害、スパム、フィッシングなどは禁止されているが、通常の広告掲載やアフィリエイト自体を禁止する記述は確認できなかった
- 静的配信に強い
- Workers / D1 と将来的に統合しやすい
- Git連携、Direct Upload の両方がある

### 注意

- Git integration と Direct Upload は後から相互に切り替えられないため、最初に方針を固定した方がよい

### 現時点の推奨

- 広告付きARG量産の本命候補

---

## 2. Netlify

### 判断

- 有力候補

### 理由

- Netlify の Acceptable Use Policy では違法行為、スパム、過剰負荷などは禁止されているが、通常の広告掲載やアフィリエイト自体を禁止する記述は確認できなかった
- 静的サイト、プレビュー、ロールバック運用がしやすい
- 編集と公開フローが分かりやすい

### 注意

- CMSやDBを強く自前拡張するなら Cloudflare よりは一体感が弱い

### 現時点の推奨

- コンテンツ量産と運用のしやすさ重視なら非常に有力

---

## 3. Firebase Hosting

### 判断

- 条件付き候補

### 理由

- Google Cloud の AUP では違法行為、詐欺、スパムなどは禁止されているが、通常の広告掲載やアフィリエイト自体を禁じる記述は確認できなかった
- Hosting は商用サイト向けの価格体系と運用を前提にしていると考えられる
- APIや管理画面からの公開導線を作りやすい

### 注意

- Blaze課金やGoogle Cloud側の管理を含めると、個人開発の初期運用は少し重くなる

### 現時点の推奨

- 将来「公開ボタンでAPIデプロイ」を強くやりたいなら候補

---

## 4. AWS Amplify Hosting

### 判断

- 条件付き候補

### 理由

- AWS Amplify Hosting は明確に商用不可とはされておらず、商用サイトの運用自体は可能と考えられる
- AWS基盤と一体で管理しやすい
- カスタムヘッダ、リダイレクト、monorepo対応がある

### 注意

- 小規模スタートでは学習コストと運用コストが高め

### 現時点の推奨

- AWS寄りのチームでない限り優先度は下げてよい

---

## 5. GitHub Pages

### 判断

- 広告前提なら非推奨

### 理由

- GitHub Docs の GitHub Pages limits では、GitHub Pages は無料の商用ホスティングとして使うことを intended でも allowed でもないとしている
- 原文では、オンラインビジネスや商取引を主目的とするサイトには向かないことが明示されている

### 補足

- 単に広告タグを1つ置いただけで即違反と断定できるとは限らない
- ただし、収益化を前提に使う基盤としては安全側ではない

### 現時点の推奨

- 収益化前提の本番基盤には使わない

---

## 6. Vercel

### 判断

- Hobby は不適
- Pro 以上なら候補にはなる

### 理由

- Vercel Terms of Service と Fair Use Guidelines では Hobby plan は personal or non-commercial use only
- Fair Use Guidelines では、広告掲載やアフィリエイト中心サイトは commercial usage に含まれると明記されている

### 現時点の推奨

- 広告やアフィリエイトを入れるなら Hobby は避ける
- 使うなら Pro 以上を前提に判断する

---

## 推奨方針

### 現実的な第一案

- Cloudflare Pages を本命にする
- `Story` と `Puzzle` の正本は D1 に置く
- revision / snapshot を前提に CMS を組む
- 公開時は静的生成して Pages に載せる

### 現実的な第二案

- Netlify を本命にする
- DB 正本 + 外付けCMSにする
- 公開時は静的生成して Netlify に載せる

---

## リポジトリ運用メモ

広告付きARG量産前提では、公開基盤は Cloudflare Pages としつつ、  
`Story` と `Puzzle` の正本を DB に置く構成も十分に成立する。

ただし条件がある:

- 履歴テーブルを別に持つ
- 公開時のスナップショットを保存する
- 公開中バージョンを明示的に管理する
- プレイヤー向け公開物は静的生成を維持する

推奨:

- CMS は DB に下書き保存
- 変更のたびに revision を記録
- 公開時に snapshot を確定
- snapshot から静的サイトを生成
- 生成結果を Cloudflare Pages にデプロイ

理由:

- 管理画面との相性が良い
- 下書き保存や途中編集がしやすい
- 履歴を DB で一元管理できる
- 公開物自体は静的に保てる

---

## 今後の進め方

1. まずホスティングを Cloudflare Pages か Netlify に絞る
2. `Story` と `Puzzle` の DB schema を定義する
3. revision と publish snapshot の仕組みを作る
4. snapshot から静的サイトを生成する仕組みを作る
5. 2作品以上を同じ仕組みで公開できることを確認する

---

## 参考ソース

- Cloudflare Self-Serve Subscription Agreement  
  https://www.cloudflare.com/terms/
- Cloudflare Pages docs  
  https://developers.cloudflare.com/pages/
- Netlify Acceptable Use Policy  
  https://www.netlify.com/legal/acceptable-use-policy/
- Netlify docs  
  https://docs.netlify.com/
- GitHub Pages limits  
  https://docs.github.com/en/pages/getting-started-with-github-pages/github-pages-limits
- Firebase Hosting docs  
  https://firebase.google.com/docs/hosting
- Google Cloud Acceptable Use Policy  
  https://cloud.google.com/terms/aup
- AWS Amplify Hosting docs  
  https://docs.aws.amazon.com/amplify/latest/userguide/welcome.html
- Vercel Terms of Service  
  https://vercel.com/legal/terms/
- Vercel Fair Use Guidelines  
  https://vercel.com/docs/limits/fair-use-guidelines
