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
- [step02](./step02/)
  - local-pc で minikube, helm, arc(actions runner controller) を使用し、この repo 専用で autoscaling, ephemeral な self-hosted runner を構築する
- [step03](./step03/)
  - local-pc で minikube, arc を使用し、 この repo 専用で custom runner image を提供する self-hosted runner を構築する
- [step04](./step04/)
  - local-pc の minikube の runner で buildx bake を実行し、 この repo 専用で複数種類 (ubuntu, debian, RHEL系, buildx/buildkit など) の custom runner image を build して ghcr へ publish し、 用途別の ARC scale set を用意し、 actions から使い分ける
- [step05](./step05/)
  - argocd を使用し、 この repo 専用の複数種類の custom runner image を、継続的に minikube に自動反映する構成を構築する
