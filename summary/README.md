# practice-self-hosted-runner - step05

## 目次

- [practice-self-hosted-runner - step05](#practice-self-hosted-runner---step05)
  - [目次](#目次)
  - [参考](#参考)
  - [前提](#前提)
  - [ディレクトリ構成](#ディレクトリ構成)
  - [手順](#手順)
    - [secret の設定](#secret-の設定)
    - [App of Apps で cluster-resources, arc-controller を deploy する](#app-of-apps-で-cluster-resources-arc-controller-を-deploy-する)
    - [grafana で resource usage を確認する](#grafana-で-resource-usage-を確認する)
    - [App of Apps で runner-scale-set を deploy する](#app-of-apps-で-runner-scale-set-を-deploy-する)

## 参考

## 前提

- [step01](../step01/) ~ [step05](../step05/) までのリソースが全て削除されていること
  - `minikube delete --all`
  - github上のtoken
- 本実装は production ready ではない。 production で運用する際には minikube 用の簡易実装に対して適宜必要な修正を行う必要がある。
- 複数の node で使用する場合
  - 別 node 用の App of Apps としての Root Application を追加し、その Application を監視させる
  - helm の values.yml の `runnerScaleSetName` を別名にする
  - actions側では `runs-on: [buildkit]` など `scaleSetLabels` の定義を指定する

## ディレクトリ構成

```shell
.
├── .github/
│   └── workflows/
│       ├── build-arc-custom-images.yml       # custom runner image の build workflow
│       └── publish-custom-arc-images.yml     # custom runner image の GHCR publish workflow
└── summary/
    ├── README.md
    ├── arc-custom-images/                    # custom runner image の build 定義
    │   ├── buildkitd.toml                    # BuildKit の registry mirror 設定
    │   └── docker-bake.hcl                   # build target と build 設定
    ├── argocd/                               # Argo CD Application 定義
    │   ├── app-of-apps/
    │   │   └── minikube/
    │   │       └── root-application.yaml     # Minikube 用 Root Application
    │   └── applications/
    │       ├── minikube/                     # Minikube 用 Applications
    │       │   ├── arc-controller/           # ARC controller Helm chart の Application
    │       │   ├── cluster-resources/        # Minikube 用 Kubernetes resources の Application
    │       │   ├── kube-prometheus-stack/    # kube-prometheus-stack の Application
    │       │   ├── runner-scale-set/         # runner scale set ごとの Applications
    │       │   ├── another-app/              # 将来用 placeholder
    │       │   └── kustomization.yaml        # Minikube 用 Applications の一覧
    │       └── prd/                          # production 用 placeholder
    ├── helm/                                 # chart ごとの Helm values
    │   ├── kube-prometheus-stack/
    │   │   └── environments/
    │   │       ├── minikube.yaml             # kube-prometheus-stack 用 values
    │   │       └── prd.yaml                  # production 用 values placeholder
    │   ├── runner-scale-set/
    │   │   ├── environments/                 # 環境共通の values と Secret サンプル
    │   │   │   ├── minikube.yaml             # Minikube 用の共通 values
    │   │   │   └── prd.yaml                  # production 用 values placeholder
    │   │   └── runners/                      # runner 種別ごとの values
    │   └── another-app/                      # 将来用 placeholder
    └── k8s/                                  # Kustomize で管理する Kubernetes resources
        ├── base/                             # 共通 namespace と Buildx RBAC
        │   ├── buildx-k8s-driver/            # Buildx Kubernetes driver の権限
        │   │   ├── role.yaml                 # Buildx Kubernetes driver 用 RBAC
        │   │   ├── rolebinding.yaml          # Role と ServiceAccount の紐付け
        │   │   └── serviceaccount.yaml       # Buildx driver 用 ServiceAccount
        │   ├── kustomization.yaml
        │   └── namespaces.yaml               # 利用 namespace の定義
        ├── minikube/                         # Minikube 用 overlay
        │   └── registry-cache/               # GHCR pull-through cache
        │       ├── deployment.yaml           # GHCR pull-through cache
        │       ├── pvc.yaml                  # cache データの永続化
        │       └── service.yaml              # cluster 内の cache endpoint
        └── prd/                              # production 用 placeholder
```

## 手順

### secret の設定

- 4つの `xxx.secret.sample.yaml` をコピーする

  ```sh
  cp summary/argocd/applications/minikube/runner-scale-set/repository-secret.secret.sample.yaml summary/argocd/applications/minikube/runner-scale-set/repository-secret.secret.yaml
  
  cp summary/helm/runner-scale-set/environments/ghcr-pull-secret.secret.sample.yaml summary/helm/runner-scale-set/environments/ghcr-pull-secret.secret.yaml
  
  cp summary/helm/runner-scale-set/environments/pre-defined-secret.secret.sample.yaml summary/helm/runner-scale-set/environments/pre-defined-secret.secret.yaml

  cp summary/k8s/minikube/registry-cache/ghcr-cache-auth.secret.sample.yaml summary/k8s/minikube/registry-cache/ghcr-cache-auth.secret.yaml
  ```

- 4つのtokenを発行してコピーしたファイルに記述する

### App of Apps で cluster-resources, arc-controller を deploy する

```sh
# minikube default の 2 cpu, 4 GB だと足りないので引数で指定する
minikube start --driver=docker --cpus=6 --memory=8192mb

minikube addons enable metrics-server

k9s --readonly

# metrics-server が runnning になった後に打つ
kubectl top pod -A

# argocd を install する前に各種 namespace の作成を行なっておく
kubectl apply -f summary/k8s/base/namespaces.yaml

# 各 token を apply しておく
kubectl apply \
  -f summary/argocd/applications/minikube/runner-scale-set/repository-secret.secret.yaml \
  -f summary/helm/runner-scale-set/environments/pre-defined-secret.secret.yaml \
  -f summary/helm/runner-scale-set/environments/ghcr-pull-secret.secret.yaml \
  -f summary/k8s/minikube/registry-cache/ghcr-cache-auth.secret.yaml

# argocd だけは直 install する。他の application は argocd 経由で install する
helm repo add argo https://argoproj.github.io/argo-helm

helm repo update

helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --version 10.11.6 \
  --wait

# argocd ui の admin の password を取得
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# argocd-server service の 443 port を、 local の 8080 port に forwarding して https://localhost:8080 にアクセスする
kubectl port-forward svc/argocd-server -n argocd 8080:443

# まだであれば App of Apps としての root-application を main に merge しておく
# root-application を apply して k8s resource を deploy する
kubectl apply -f summary/argocd/app-of-apps/minikube/root-application.yaml

# argocd ui で arc-controller, cluster-resources, kube-prometheus-stack が healthy になることを確認する
```

### grafana で resource usage を確認する

```sh
# grafana の初期 admin-user を取得
kubectl -n monitoring get secret kube-prometheus-stack-grafana \
  -o jsonpath='{.data.admin-user}' | base64 -d; echo

# grafana の初期 admin-password を取得
kubectl -n monitoring get secret kube-prometheus-stack-grafana \
  -o jsonpath='{.data.admin-password}' | base64 -d; echo

# grafana の 80 port を、 local の 3000 port に forwarding して http://localhost:3000 にアクセスする
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80

# prometheus の 9090 port を、 local の 9090 port に forwarding して http://localhost:9090 にアクセスする
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
```

### App of Apps で runner-scale-set を deploy する

- runner-scale-set を main に merge する
  - App of Apps が argocd/applications/minikube の変更を検知して自動 deploy してくれる
  - argocd ui で runner Applications の状態が healthy になることを確認する
