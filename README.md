# practice-self-hosted-runner

## 目次

- [practice-self-hosted-runner](#practice-self-hosted-runner)
  - [目次](#目次)
  - [目的](#目的)
  - [ディレクトリ構成](#ディレクトリ構成)

## 目的

- autoscaling, ephemeral な self-hosted runnerの構築の練習。

## ディレクトリ構成

- [step01](./step01/)
  - local-pc で 単一の docker container を使用し、この repo 専用の self-hosted runner を構築する
- [step2](./step02/)
  - local-pc で minikube, helm, arc(actions runner controller) を使用し、この repo 専用で autoscaling, ephemeral な self-hosted runner を構築する
- [step3](./step03/)
  - local-pc で minikube, kustomize, arc, argocd, buildx bake を使用し、 この repo 専用で複数種類 (ubuntu, debian, RHEL系, buildx/buildkit など) の runner を提供し、継続的に runner image や scale set 設定を更新したり種類を増やせる構成を構築する
