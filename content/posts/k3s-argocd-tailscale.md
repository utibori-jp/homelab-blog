---
title: "k3s + ArgoCD + Tailscaleで自宅k8s環境を整えた"
subtitle: ""
date: 2026-05-08T00:00:00+09:00
draft: true
author:
  name: ""
  link: ""
description: "クラスタを組んだ後、ArgoCDでGitOps、TailscaleでVPNレスなアクセスを実現するまでの話"
keywords: ["k3s", "argocd", "tailscale", "gitops", "homelab"]
license: ""
comment: false
weight: 0
tags:
  - k3s
  - argocd
  - tailscale
  - gitops
categories:
  - インフラ
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

## 全体構成

<!-- 構成図や箇条書きで：どのコンポーネントがどう繋がっているか -->

- K3s（3ノード）
- ArgoCD：App-of-Appsパターンで管理
- Tailscale Operator：Ingressをtailnet経由で公開
- Longhorn：永続ストレージ

## なぜGitOps（ArgoCD）？

<!-- Q: GitOpsをやろうと決めた理由は？以前はどう管理していた？どこかで見て良さそうだったとか、kubectl applyが嫌になったとか -->

## なぜTailscale？

<!-- Q: Tailscaleを選んだ経緯は？公開はしたくない、WireGuardは面倒、など。Tailscale Operatorを使おうと思ったのは？ -->

## 「動いた」瞬間

<!-- Q: この構成が意図通りに動いたと感じた瞬間や、一番気持ちよかった場面の話 -->

## 今でも残っている課題・もやり

<!-- 完璧じゃない部分や、まだ解決していないことがあれば正直に -->
