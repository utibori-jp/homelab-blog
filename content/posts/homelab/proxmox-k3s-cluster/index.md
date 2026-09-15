---
title: "Proxmox + K3sで作った自宅Homelabを紹介する"
subtitle: ""
date: 2026-05-01T00:00:00+09:00
draft: false
aliases:
  - "/posts/proxmox-k3s-cluster/"
author:
  name: ""
  link: ""
description: "自宅にk8s環境を作りたくてProxmox上にVM3台を立て、K3sクラスタを構築するまでの話"
keywords: ["proxmox", "k3s", "kubernetes", "homelab"]
license: ""
comment: false
weight: 0
tags:
  - proxmox
  - k3s
  - kubernetes
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

## Homelabのはじまりは唐突に

Homelabを構築し始めたきっかけは、結構しょうもないものだった。

安くなっていたという理由で衝動買いしたMiniPCを、ちょっと遊んでしばらく放置してたら、パスワードを忘れてしまい初期化するしかなくなってしまった。そこで、どうせ初期化するならもうOSごと入れ替えようと思い立ったのが、事の始まりである。

この記事では、「具体的にどんなコマンドを叩いたか」という手順の話はしない。私が普段遊んでるHomelabがどんな感じなのか、そのあたりを書けたらと思っている。
Homelabって興味はあるけど色々ありすぎて手が出ない、といった人の参考になれば嬉しい。

まずは、うちのHomelabの全体像をざっくり眺めてみてほしい。

## まずは全体像から

MiniPC上ではProxmoxがOSとして動いていて、その上にUbuntu ServerのVMが3台乗っかっている。このVM3台で、K3sクラスタを構成している。

{{< mermaid >}}
graph TD
    subgraph home["🏠 自宅ネットワーク 192.168.0.0/24"]
        Router["ルータ"]
        subgraph laptop["ノートPC"]
            TF["Terraform<br/>(bpg/proxmox)"]
        end
        subgraph minipc["MiniPC (RAM 32GB)"]
            PVE["Proxmox VE 9.x<br/>192.168.0.100"]
            subgraph sdn["Proxmox SDN: k8sVnet (10.10.0.0/24, SNAT)"]
                M["home-lab-1 (master)<br/>10.10.0.11<br/>4core / 6GB / 64GB"]
                W1["home-lab-2 (worker)<br/>10.10.0.12"]
                W2["home-lab-3 (worker)<br/>10.10.0.13"]
            end
        end
    end
    Router --- laptop
    Router --- PVE
    PVE -. "SDN gateway 10.10.0.1" .- M
    M --- W1
    M --- W2
    TF -.->|VM作成 / cloud-init| sdn

    classDef hw fill:#fde2c4,stroke:#e08a3c,color:#333
    classDef net fill:#d6e8fb,stroke:#4a90d9,color:#333
    class laptop,minipc hw
    class home,sdn net
{{< /mermaid >}}

図にすると入れ子が多くて少しごちゃっとしているが、外側から順に見ていくとシンプルだ。いちばん外が家のネットワーク(192.168.0.0/24)で、そこにノートPCとMiniPCがぶら下がっている。MiniPCの中ではProxmoxが動いていて、さらにその内側に、Proxmox SDNで切った隔離ネットワーク(10.10.0.0/24)がある。K3sの3ノードはこの隔離ネットの中にいて、外とはSDNのgateway(10.10.0.1)経由でやりとりする、という構造だ。

個人的なこだわりポイントは2つある。
1. VMはTemplate + TerraformでIaC化する
2. VMはProxmox上のプライベートサブネット(10.10.0.0/24)に配置する

一つずつ話していく。

### VMはTemplate + TerraformでIaC化する

はじめProxmoxを入れて遊んでいた時は、[Proxmox VE Scripts](https://community-scripts.org/scripts)を使ってみたり、手動でぽちぽちサーバを増やしていた。
何となく動かしてみる分には全くそれで問題なかったのだが、後述するK3sクラスタを組もうってなったタイミングで、まったく同じ作業を何回もやることになるのはしんどいなと。また、今回MiniPCで動かしている以上、このMiniPCが逝ったら全て終わる状況なわけで、もしそうなったら、また一から手順を調べてやるのは流石にめんどくさい。
というわけでできるだけ自動化したいよねってことでIaC化してみることにした。

ちなみに、私が採用した方法はちょっと変わっている。Proxmoxの機能でVMテンプレートを作成し、そのテンプレートをTerraformで任意の数だけ立てる、という方法だ。

教科書的にきれいなのは、TerraformでプレーンなVMを立てて、Ansibleでノードを設定していくやり方だと思う。ただ私の場合、初期設定をのぞくとAnsibleの出番がほとんど無さそうだった。そのためだけに新しく環境を用意するのは、~~めんどくさい~~リターンが大きくないなと判断して、今回はAnsibleを見送ってこの方法に落ち着いた。（ただ、実は結局なんやかんやあって後からAnsibleを入れている。）

なお、VM自体は他の用途でも使うかもしれないので、K3s周りのソフトウェアは意図的にテンプレートへ入れていない。こっちは手動で入れた。

VMテンプレートはドライブに保存して誰でも見られるように公開しているので、このVMをダウンロードして`terraform apply`すれば、いくつでもだれでも好きなだけUbuntu Serverを立ち上げられる。興味ある方はぜひ試してみてほしい。

https://drive.google.com/file/d/1z05zYFzUdcxgIKeMsQYp466R9HO4JMul/view?usp=sharing


### VMはProxmox上のプライベートサブネット(10.10.0.0/24)に配置する

手動ポチポチ時代は、各サーバを直接家のルーターと同じネットワークに参加させていた。これをK3s導入のタイミングで、Proxmox上のプライベートサブネットにまとめて引っ越した。あわせて、個々のサービスをLXCやVMとして立てるのをやめ、全てK3s上のアプリケーションとして動かす方針に変えている。この「ネットワークを分ける」と「アプリをK3sに寄せる」は、私の中ではセットの判断だった。

ネットワークを分けたのは、家のルータから見た構成をすっきりさせたかったからだ。homelabの通信は全てProxmoxの内側で完結するので、家のネットワークにhomelab由来のトラフィックが混ざらない。IPアドレスも、家のルータのDHCP任せではなく自分の管理下に置ける（VM自体のIPはTerraformで固定、各アプリのIPはK3s内で払い出し）。

アプリをK3sに寄せたのは、IaC化のしやすさが大きい。LXCやVMで個別に建てていた頃と違って、各アプリをマニフェストとして宣言的に管理できるようになった。

ただ、ネットワークを分けたことで、今度は手元のノートPCからノードへ直接アクセスしづらくなる、という副作用も出てきた。このあたりにどう対処したかは、後半の「詰まったところ」で触れる。

## なぜVM3台のK3sにしたか

なぜわざわざK3sクラスタを組んでいるのか、その動機についても少し触れておく。

そもそもの発端は、Proxmoxで遊んでいるうちに、だんだん「この上でKubernetesを動かしてみたい」という欲が出てきたことだった。とはいえ当時の私のKubernetesの理解は、「複数のコンテナをまとめて管理してくれるらしい」くらいのもの。実際どうやってコンテナを管理しているのかの知識も、クラスタを組んだ経験もなかった。

そこでProxmox上でKubernetesを動かしてみることにしたのだが、ただ動かしてみるだけであれば、VM1台だけ立ててMinikubeやKindを使うのが手軽だ。それでも私がVMを3台立てる構成を選んだ理由はシンプルで、せっかくProxmoxがあるのだから、ノード同士が通信するマルチノード構成を組んでみたかったからである。
台数はmaster×1 + worker×2にした。複数ノードに処理が分散する様子を眺められて、かつMiniPC1台のリソースにも収まる、私にとっての最小構成がこれだった。

ディストリビューションにK8sそのものではなくK3sを選んだのも、同じ発想だ。MiniPC1台に全部を詰め込む以上、リソースは軽いに越したことはない。それに、はじめから全機能を使いこなせるわけでもないので、まずは軽量なK3sで十分だと判断した。

では、この構成を実際どう組んでいるのか、もう少しだけ中身を覗いてみる。

## 構成を少し細かく

「なぜこの構成か」はここまでで触れたので、細かいところは早見表でまとめておく。どんな部品でできているのか、興味のある方向けに。

| 項目 | 値 |
|------|-----|
| ノード | 3台（home-lab-1〜3 / master×1, worker×2） |
| CPU / MEM / Disk | 4 core / 6GB / 64GB（各ノード） |
| ノードIP | 10.10.0.11 〜 .13 |
| ネットワーク | Proxmox SDN で 10.10.0.0/24 を分離（gateway 10.10.0.1 / SNAT有効） |
| VM作成 | Terraform（Provider: bpg/proxmox）+ cloud-init でテンプレートからclone |
| 詳細 | homelab-infra リポジトリ参照 |

コードの中身まで気になる方は、[homelab-infra](https://github.com/utibori-jp/homelab-infra) リポジトリを覗いてみてほしい。

## 詰まったところ

ここまでサラッと書いてきたが、もちろんすんなり組めたわけではない。実際には、初めて触るツールや不慣れなネットワーク構成に、いくつも壁にぶつかった。特に印象に残っている詰まりどころを2つ挙げておく。

1つ目は、Terraformのプロバイダ問題だ。最初はAIに勧められるまま、昔から定番の `telmate/proxmox` というProviderでコードを書いていた。ところが、当時の私の環境（Proxmox 9.x）ではどうにもうまく動かせず、しばらくハマる羽目に。あれこれ調べた末に、 `bpg/proxmox` という別のProviderに乗り換えることで解決した。しかし、AIが出してくるコードはどうしても `telmate` に引っ張られており、`bpg` の書き方になっていなかったため、最終的には公式のサンプルやドキュメントを横に置きながら、自分で書き直した。今のAIに同じことを聞けば、最初から `bpg` 版を提示してもらえるかもしれないが、当時は自分でコードを書くことが多く、それはそれでかえって良い勉強になった。

2つ目は、ノードにSSHが繋がらない問題だ。これには構成と設定、2つの段階でつまずきがあった。

まずは構成上の躓きである。Proxmoxは家のネットワークにいる一方で、K3sのノードは隔離ネットワークの中にいるので、手元のノートPCからは直接手が届かない。最初はProxmoxを踏み台にした多段SSHでしのいでいたが、その後Tailscaleを入れて各ノードを同じtailnetに放り込んだことで、踏み台なしに直接SSHできるようになった。

ところが、Tailscaleを入れたのに、なぜか外出先から繋がらない、という謎現象に直面した。原因は拍子抜けするほど単純で、`.ssh/config` に書いていたIPアドレスの設定ミスだった。Tailscaleを入れる前、ローカルで開発していた頃の名残で、自宅ルータが払い出したIPをそのまま指定していたのだ。つまり、家の中で「踏み台なしで繋がった！」と喜んでいた時、実はTailscaleを一切経由しておらず、ただ単に家のWi-Fiで直接繋がっていただけだったのである。

家の中にいれば届くが、当然外からは繋がらない。ここをTailscale側のIPに書き直し、ようやく「本当の意味で」場所を問わずアクセスできる環境が完成した。

## さいごに

Homelab構築を通して、普段あまり意識しない家のネットワークと正面から向き合えたのは、非常に良い勉強になった。

試行錯誤の末にノードを構築し、無事にSSHが通った瞬間は結構感動した。社会人最初のプロジェクトで、初めてSSH接続したとき以来、久しく忘れていた感覚を思い出した気がする。

この記事ではProxmoxとVM、ネットワークまわりの構築が中心だったが、肝心の「この上で何を動かしているのか」――ArgoCDによるGitOpsや、Tailscaleの設定まわり――については、また別の記事で書いていく予定だ。よければ次回もお付き合いいただけると嬉しい。
