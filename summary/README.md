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
    - [App of Apps で runner-scale-set を deploy する](#app-of-apps-で-runner-scale-set-を-deploy-する)

## 参考

## 前提

- [step01](../step01/) ~ [step05](../step05/) までのリソースが全て削除されていること
  - `minikube delete --all`
  - github上のtoken

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
    │       │   ├── runner-scale-set/         # runner scale set ごとの Applications
    │       │   └── another-app/              # 将来用 placeholder
    │       └── prd/                          # production 用 placeholder
    ├── helm/                                 # runner scale set の Helm values
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
minikube start

minikube addons enable metrics-server

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

# argocd ui で arc-controller, cluster-resources が healthy になることを確認する
```

### App of Apps で runner-scale-set を deploy する

- runner-scale-set を main に merge する
  - App of Apps が argocd/applications/minikube の変更を検知して自動 deploy してくれる
  - argocd ui で runner Applications の状態が healthy になることを確認する
