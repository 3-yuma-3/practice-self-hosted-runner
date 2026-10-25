# practice-self-hosted-runner - step04

## 目次

- [practice-self-hosted-runner - step04](#practice-self-hosted-runner---step04)
  - [目次](#目次)
  - [参考](#参考)
  - [前提](#前提)
  - [手順](#手順)

## 参考

- [Kubernetes driver](https://docs.docker.com/build/builders/drivers/kubernetes/)
- [Podにサービスアカウントを設定する](https://kubernetes.io/ja/docs/tasks/configure-pod-container/configure-service-account/)
- [RBAC認可を使用する](https://kubernetes.io/ja/docs/reference/access-authn-authz/rbac/)
- [actions/actions-runner-controller/runner/actions-runner.ubuntu-24.04.dockerfile](https://github.com/actions/actions-runner-controller/blob/23159a8e2d70ca4cece740fe43a8d9eb0c2818de/runner/actions-runner.ubuntu-24.04.dockerfile)
- [Bake](https://docs.docker.com/build/bake/)
- [Add image annotations with GitHub Actions](https://docs.docker.com/build/ci/github-actions/annotations/)

## 前提

- [step03](../step03/) の `mdlint` を通すための ghcr の custom runner image を minikube で使用できていること

## 手順

- namespace, serviceaccount, role, rolebinding の manifest を実装する
- `kubectl apply -f step04/k8s/buildkit-rbac.yml` で buildkit 向けの manifest を適用

  > serviceaccount/buildx-client configured  
  > namespace/buildkit configured  
  > role.rbac.authorization.k8s.io/buildx-driver created  
  > rolebinding.rbac.authorization.k8s.io/buildx-driver created

- `kubectl auth can-i` で `buildx-client` の権限が全部 yes なことを確認

  ```sh
  kubectl auth can-i get deployments -n buildkit \
    --as=system:serviceaccount:arc-runners:buildx-client
  kubectl auth can-i create deployments -n buildkit \
    --as=system:serviceaccount:arc-runners:buildx-client
  kubectl auth can-i delete deployments -n buildkit \
    --as=system:serviceaccount:arc-runners:buildx-client
  kubectl auth can-i list pods -n buildkit \
    --as=system:serviceaccount:arc-runners:buildx-client
  kubectl auth can-i create pods --subresource=exec \
    -n buildkit \
    --as=system:serviceaccount:arc-runners:buildx-client
  ```

- `values.yml` に manifest で適用した `serviceAccountName` の指定を追加
- `helm list -n arc-runners` で今の chart version を確認する。
  - `CHART=gha-runner-scale-set-x.y.z`
- `helm upgrade` の様子を見るために `kubectl get pods -n arc-runners -w` を打っておく
- `helm upgrade` を実行して、 `arc-runner-set` を更新する

  ```sh
  helm upgrade arc-runner-set \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
    --namespace arc-runners \
    --version <現在のチャートバージョンのx.y.z部分> \
    --values step04/helm/arc-runner-set-values.yml
  ```

  > Release "arc-runner-set" has been upgraded. Happy Helming!  
  > NAME: arc-runner-set  
  > NAMESPACE: arc-runners  
  > STATUS: deployed  
  > REVISION: 3  
  > DESCRIPTION: Upgrade complete  
  > TEST SUITE: None  
  > NOTES:  
  > Thank you for installing gha-runner-scale-set.  
  >
  > Your release is named arc-runner-set.

  <details><summary>折りたたみ</summary>

  ```sh
  # 仕込んでいた別sessionの様子
  ❯ kubectl get pods -n arc-runners -w
  NAME                          READY   STATUS    RESTARTS   AGE
  arc-runner-set-runner-rzbwx   1/1     Running   0          102m
  arc-runner-set-runner-rzbwx   1/1     Terminating   0          103m
  arc-runner-set-runner-rzbwx   1/1     Terminating   0          103m
  arc-runner-set-runner-ttsdq   0/1     Pending       0          0s
  arc-runner-set-runner-ttsdq   0/1     Pending       0          0s
  arc-runner-set-runner-ttsdq   0/1     ContainerCreating   0          0s
  arc-runner-set-runner-rzbwx   0/1     Error               0          103m
  arc-runner-set-runner-ttsdq   0/1     ContainerCreating   0          1s
  arc-runner-set-runner-ttsdq   1/1     Running             0          1s
  arc-runner-set-runner-rzbwx   0/1     Error               0          103m
  arc-runner-set-runner-rzbwx   0/1     Error               0          103m
  ```

  </details>

- runner pod に新しい ServiceAccount が反映されたことを確認

  ```sh
  kubectl get pods -n arc-runners \
    -o custom-columns='POD:.metadata.name,STATUS:.status.phase,SA:.spec.serviceAccountName'
  ```

  > POD                           STATUS    SA  
  > arc-runner-set-runner-ttsdq   Running   buildx-client

- local-pc に立てた minikube の arc runner で docker image の build が成功するか確認するための actions を追加し、 pr で成功を確認する
- bake で build する用の custom runner image の Dockerfile を実装する
- 複数の Dockerfile を一括で build するための `docker-bake.hcl` を実装する
- bake で build するための actions を実装する
- bake での build が通ったら、 bake で build & publish するための actions を実装する
