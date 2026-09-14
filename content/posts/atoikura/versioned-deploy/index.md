---
title: "自作家計簿アプリ atoikura v0.2.0 をリリースした ― タグを変えるだけでデプロイが終わる話"
subtitle: ""
date: 2026-06-07T00:00:00+09:00
draft: true
author:
  name: ""
  link: ""
description: "atoikura v0.2.0 のリリースを機に、latest タグ運用を脱してバージョンタグ + ArgoCD GitOps によるデプロイフローを整備した話"
keywords: ["kubernetes", "argocd", "gitops", "homelab", "docker", "ghcr", "自作アプリ", "家計簿"]
license: ""
comment: false
weight: 0
tags:
  - kubernetes
  - argocd
  - gitops
  - docker
  - 自作アプリ
categories:
  - アプリ
hiddenFromHomePage: false
hiddenFromSearch: false
hiddenFromRss: false
hiddenFromRelated: false
summary: ""
resources:
featuredImage: ""
featuredImagePreview: ""
toc:
  enable: true
math:
  enable: false
lightgallery: false
password: ""
message: ""
repost:
  enable: false
  url: ""
---

## はじめに

<!-- フック: "latest のままでいいや" が崩れた瞬間 -->
<!-- 4〜5文。latest タグ運用の何気ない不安 → v2 リリースを機に整備することにした → この記事で話すこと -->

## latest タグの何が問題だったか

<!-- 問題提示 -->
<!-- - いつ何がデプロイされているか分からない
     - ロールバックしたくても "どのイメージに戻るか" が特定できない
     - ArgoCD が "変化なし" と判断して自動 sync が走らないケースがある（image digest が変わらない限り） -->

## v0.2.0 で何を変えたか

<!-- 実験・実装 -->
<!-- GitHub Actions で build & push するときに v0.x.x タグを付ける設定を追加した流れ -->
<!-- GHCR のパッケージページに v0.2.0 が並んだログを素材に -->

## values.yaml を 1 行変えてデプロイ

<!-- 観察 -->
<!-- 実際のログ素材:
     - values.yaml の before/after (latest → v0.2.0 × 2)
     - git commit "chore(charts/atoikura): bump images to v0.2.0"
     - git push → ArgoCD が次の sync cycle（デフォルト 3 分）で検知 → Synced / Healthy
     コード例もここに埋め込む予定 -->

## タグを変えたら反映まで行ける

<!-- 結論・まとめ -->
<!-- GitOps のうれしさを実感した話。values.yaml が "今何が動いているか" の単一の真実になった
     ロールバックも古いタグに戻して push するだけ -->

## さいごに

<!-- 学びの振り返り + 今後の展望 -->
<!-- atoikura 自体の機能追加の話に触れてもいい。v0.3.0 に向けて何をしたいか -->
