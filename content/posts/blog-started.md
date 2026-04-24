---
title: "ブログ立ち上げました"
subtitle: ""
date: 2026-04-24T12:00:00+09:00
draft: false
author:
  name: ""
  link: ""
description: "自宅サーバ運用の記録を残すためにブログを始めた"
keywords: ["hugo", "fixit", "homelab"]
license: ""
comment: false
weight: 0
tags:
  - メタ
categories:
  - お知らせ
hiddenFromHomePage: false
hiddenFromSearch: false
hiddenFromRss: false
hiddenFromRelated: false
summary: "自宅サーバ運用の記録を残すためにブログを始めた。Hugo と FixIt テーマ、GitHub Pages で構築。"
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
# 自宅サーバ運用記録

## 環境

Proxmox 上に k3s クラスタを組み、ArgoCD による GitOps でアプリを管理している。Tailscale 経由で外からアクセスしている。

- k3s v1.34.3、3 ノード構成
- ArgoCD v3.3.0 で App-of-Apps パターン
- Tailscale Operator で Ingress を tailnet 公開
- Longhorn で永続ストレージ

## このブログの構成

- Hugo v0.160.1 extended
- テーマは FixIt を Hugo Modules 経由で取得
- GitHub Pages でホスティング、GitHub Actions で自動デプロイ

## 書く予定のもの

- 構築で詰まった点について
- 構築及び運用での学び
