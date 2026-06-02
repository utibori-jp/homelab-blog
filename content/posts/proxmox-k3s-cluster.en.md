---
title: "A Tour of My Home Lab Built with Proxmox + K3s"
subtitle: ""
date: 2026-05-01T00:00:00+09:00
draft: false
author:
  name: ""
  link: ""
description: "How I ended up wanting a k8s environment at home, spun up three VMs on Proxmox, and built a K3s cluster on top of them"
keywords: ["proxmox", "k3s", "kubernetes", "homelab"]
license: ""
comment: false
weight: 0
tags:
  - proxmox
  - k3s
  - kubernetes
categories:
  - Infrastructure
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

## The home lab started out of nowhere

The reason I started building a home lab was honestly pretty silly.

I impulse-bought a MiniPC just because it was on sale, played with it for a bit, then left it alone for a while—long enough that I forgot the password and had no choice but to wipe it. And since I was going to reset it anyway, I figured I might as well swap out the whole OS. That was how the whole thing began.

In this article I'm not going to walk through "exactly which commands I ran." Instead, I want to share what the home lab I play with day to day actually looks like. I hope it's useful to anyone who's curious about home labs but finds there's just too much to wrap their head around to get started.

So first, let me give you a rough overview of my setup.

## Starting with the big picture

The MiniPC runs Proxmox as its OS, and on top of that sit three Ubuntu Server VMs. Those three VMs together form a K3s cluster.

{{< mermaid >}}
``` mermaid
graph TD
    subgraph home["🏠 Home network 192.168.0.0/24"]
        Router["Router"]
        PC["Laptop"]
        subgraph minipc["MiniPC (RAM 32GB / ¥40k)"]
            PVE["Proxmox VE 9.x<br/>192.168.0.100"]
            subgraph sdn["Proxmox SDN: k8sVnet (10.10.0.0/24, SNAT)"]
                M["home-lab-1 (master)<br/>10.10.0.11<br/>4core / 6GB / 64GB"]
                W1["home-lab-2 (worker)<br/>10.10.0.12"]
                W2["home-lab-3 (worker)<br/>10.10.0.13"]
            end
        end
    end
    Router --- PC
    Router --- PVE
    PVE -. "SDN gateway 10.10.0.1" .- M
    M --- W1
    M --- W2
    TF["Terraform<br/>(bpg/proxmox)"] -.->|create VMs / cloud-init| sdn
```
{{< /mermaid >}}

The diagram looks a bit busy because of all the nesting, but it's simple once you read it from the outside in. The outermost layer is my home network (192.168.0.0/24), with the laptop and the MiniPC hanging off it. Inside the MiniPC, Proxmox is running, and inside that there's an isolated network (10.10.0.0/24) carved out with Proxmox SDN. The three K3s nodes live inside this isolated network and talk to the outside world through the SDN gateway (10.10.0.1).

There are two things I personally cared about:
1. Manage VMs as IaC with Template + Terraform
2. Place the VMs on a private subnet (10.10.0.0/24) on Proxmox

Let me go through them one at a time.

### Manage VMs as IaC with Template + Terraform

When I first installed Proxmox and was just messing around, I tried [Proxmox VE Scripts](https://community-scripts.org/scripts) and also spun up servers manually, one click at a time. For just getting something running, that was completely fine. But when it came time to build the K3s cluster I'll describe later, the thought of repeating the exact same work over and over felt painful. And since everything runs on this one MiniPC, the moment it dies, it all dies with it—and re-researching the whole procedure from scratch would be a real pain.

So, wanting to automate as much as possible, I decided to go the IaC route.

The approach I landed on is a little unusual. I create a VM template using Proxmox's own feature, then use Terraform to spin up as many copies of that template as I want.

The textbook-clean approach would probably be to stand up plain VMs with Terraform and configure the nodes with Ansible. But in my case, aside from the initial setup, Ansible barely had anything to do. Setting up a whole new environment just for that felt like ~~too much hassle~~ not worth the return, so this time I skipped Ansible and settled on this method. (Although, as it turns out, one thing led to another and I did end up adding Ansible later.)

Since the VMs themselves might get used for other purposes too, I deliberately kept the K3s-related software out of the template. I installed that part by hand.

I've saved the VM template to a drive and made it public so anyone can grab it. Download this VM, run `terraform apply`, and you can spin up as many Ubuntu Servers as you like. If you're curious, give it a try.

https://drive.google.com/file/d/1z05zYFzUdcxgIKeMsQYp466R9HO4JMul/view?usp=sharing


### Place the VMs on a private subnet (10.10.0.0/24) on Proxmox

Back in my click-by-click days, I joined each server directly to the same network as my home router. When I introduced K3s, I moved them all over to a private subnet on Proxmox. At the same time, I stopped standing up individual services as LXC containers or VMs and switched to running everything as applications on K3s. In my head, "splitting the network" and "consolidating apps onto K3s" were a single, paired decision.

I split off the network because I wanted to keep the topology tidy from the home router's point of view. All home lab traffic now stays inside Proxmox, so no home-lab-originated traffic mixes into my home network. I can also keep IP addresses under my own control instead of leaving them to the home router's DHCP (VM IPs are fixed via Terraform, and each app's IP is handed out within K3s).

I consolidated the apps onto K3s largely because it makes IaC so much easier. Unlike the days of standing up each app individually as an LXC or VM, I can now manage every app declaratively as a manifest.

That said, splitting the network had a side effect: it became harder to SSH directly into the nodes from my laptop. I'll touch on how I dealt with that later in the "Where I got stuck" section.

## Why three VMs running K3s

Let me also say a little about why I bother running a K3s cluster at all.

It all started when, while playing around with Proxmox, I gradually developed an itch to "try running Kubernetes on top of this." That said, my understanding of Kubernetes at the time was roughly "apparently it manages a bunch of containers together." I had no real knowledge of how it actually manages containers, and no experience building a cluster.

So I decided to run Kubernetes on Proxmox. If the goal were just to get it running, the easy route would be to stand up a single VM and use Minikube or Kind. The reason I went with three VMs is simple: since I had Proxmox right there, I wanted to build a multi-node setup where nodes talk to each other. I went with one master and two workers. That let me watch work get distributed across multiple nodes while still fitting within the resources of a single MiniPC—it was the minimal setup for me.

I picked K3s over plain K8s for the same reason. Since I'm cramming everything onto one MiniPC, the lighter the resource footprint, the better. And since I wasn't going to master every feature from day one anyway, I figured lightweight K3s was plenty to start with.

So, how is this setup actually put together? Let me peek inside a little more.

## A bit more detail on the setup

I've already covered the "why" of this setup, so I'll summarize the finer details in a quick-reference table—for anyone curious about what parts it's made of.

| Item | Value |
|------|-----|
| Nodes | 3 (home-lab-1 to 3 / master×1, worker×2) |
| CPU / MEM / Disk | 4 core / 6GB / 64GB (per node) |
| Node IPs | 10.10.0.11 to .13 |
| Network | Isolated 10.10.0.0/24 via Proxmox SDN (gateway 10.10.0.1 / SNAT enabled) |
| VM creation | Terraform (Provider: bpg/proxmox) + cloud-init, cloned from a template |
| Details | See the homelab-infra repository |

If you want to dig into the actual code, take a look at the [homelab-infra](https://github.com/utibori-jp/homelab-infra) repository.

## Where I got stuck

I've written all this pretty breezily, but of course it didn't come together smoothly. In reality, I ran into plenty of walls with tools I was touching for the first time and network setups I wasn't used to. Let me call out the two that stuck with me the most.

The first was a Terraform provider problem. At first I followed the AI's recommendation and wrote my code with `telmate/proxmox`, the long-standing classic. But in my environment at the time (Proxmox 9.x) I just couldn't get it to work, and I was stuck for a while. After a lot of digging, switching to a different provider, `bpg/proxmox`, fixed it. The trouble was that the code the AI kept handing me was always pulled toward `telmate` and never came out in the `bpg` style, so in the end I rewrote it myself with the official samples and docs open beside me. If I asked today's AI the same thing, it might give me the `bpg` version from the start—but back then I had to write a lot of the code myself, and that turned out to be good practice in its own right.

The second was that I couldn't SSH into the nodes. This one tripped me up at two levels: topology and configuration.

First, the topology snag. Proxmox sits on my home network, while the K3s nodes live inside the isolated network, so my laptop can't reach them directly. At first I got by with multi-hop SSH using Proxmox as a jump host, but after I installed Tailscale and threw every node into the same tailnet, I could SSH in directly without any jump host.

But then I hit a baffling phenomenon: even after installing Tailscale, for some reason I couldn't connect from outside the house. The cause was almost anticlimactically simple—a typo in the IP address in my `.ssh/config`. It was a leftover from before Tailscale, back when I was developing locally, where I'd specified the IP handed out by my home router as-is. In other words, when I was celebrating "I connected without a jump host!" inside the house, I wasn't going through Tailscale at all—I was just connecting directly over my home Wi-Fi.

It works inside the house, but naturally it won't connect from outside. After rewriting it to the Tailscale-side IP, I finally had an environment I could "truly" reach regardless of location.

## Wrapping up

Through building this home lab, getting to face my home network head-on—something I rarely think about—was a really good learning experience.

After all that trial and error, the moment I'd built the nodes and SSH finally went through was genuinely moving. It felt like I'd rediscovered a feeling I'd long forgotten, one I hadn't felt since the first time I SSH'd into something on my first project as a working adult.

This article focused on building Proxmox, the VMs, and the networking, but the crucial question of "what am I actually running on top of this"—GitOps with ArgoCD, the Tailscale setup, and so on—I plan to write about in separate articles. I hope you'll join me next time.
