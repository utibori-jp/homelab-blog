# CLAUDE.md

### General
- Comments in English

## Git / Commit Conventions

- Use Conventional Commits. Scope format: `(directory/component-name)`
  - e.g. `feat(00_Baseline/cloudtrail)`, `refactor(01_Identity_and_Access_Management/iam-permissions-boundary)`
- Commit messages in **English**, title line only (no body or bullet points)
- Do not add `Co-Authored-By:`

## 記事の書きっぷりについて

### 文体・トーン
- **だ・である調**で書く。カジュアルで親しみやすい語り口は保つ
- 一人称は「**私**」。ただし調査記事など硬めの内容では「筆者」を使う（e-Estonia連載など）
  - 「自分の」「自分で」は所有・再帰の用法なので、一人称の選択とは無関係にそのまま使う

### 構成・構造
- 基本アーク: 問題・疑問の提示 → 仮説 → 実験・検証 → 観察 → 結論
- オープニングの見出しは「はじめに」。フック＋背景＋記事の意図を示す
- 締めの見出しは「**さいごに**」で統一する。「おわりに」「まとめ」「次回予告」は使わない
  - 内容は学びの振り返り＋今後の展望、またはユーモアを添えて締める
  - 連載記事では、このセクションの末尾で次回への繋ぎを書く（独立した見出しは立てない）

### 出典（調査記事のみ）
- e-Estonia連載のような硬めの調査記事に限り、記事末尾に「出典メモ」セクションを置く。手を動かした系の記事には不要
- 数字と、解釈の分かれうる論点には一次資料（公的機関の統計・公式発表）を充てる
- Wikipediaは争いの少ない通史部分に限って使い、閲覧日を添える
- 自分で計算した値は「概算」と明記する

### 日本語・英語の使い分け
- 地の文・説明・感情表現はすべて日本語
- 技術用語（Pod, Scheduler, TCP, RPS, API Server, Static Pod 等）は英語のまま使う
- コードブロック・コマンド出力は英語（実際のターミナル出力をそのまま）

### 箇条書き vs 散文
- 散文を優先する。bullet points は最小限に抑える
- リストが必要なら番号付きにして、前置き文の後に自然に流し込む（「2つあります。①〜 ②〜」）

### 参考
- https://future-architect.github.io/articles/20260427a/                                                                                                                     
- https://future-architect.github.io/articles/20260325a/                                                                                                                     
- https://future-architect.github.io/articles/20251104a/                                                                                                                     
- https://qiita.com/utibori-jp/items/8d0436d03b8aa6ede62d  
