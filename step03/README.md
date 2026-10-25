# practice-self-hosted-runner - step03

## 目次

- [practice-self-hosted-runner - step03](#practice-self-hosted-runner---step03)
  - [目次](#目次)
  - [参考](#参考)
  - [前提](#前提)
  - [手順](#手順)

## 参考

- [Actions Runner Controller を使用して Runner Scale Set を deploy する > runner image を構成する](https://docs.github.com/ja/actions/how-tos/manage-runners/use-actions-runner-controller/deploy-runner-scale-sets#configuring-the-runner-image)
- [Docker イメージの発行](https://docs.github.com/ja/actions/tutorials/publish-packages/publish-docker-images#publishing-images-to-github-packages)
- [コンテナレジストリの利用 > container image の label 付け](https://docs.github.com/ja/packages/working-with-a-github-packages-registry/working-with-the-container-registry#labelling-container-images)
- [コンテナレジストリの利用 > container registry への認証](https://docs.github.com/ja/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-to-the-container-registry)

## 前提

- [step02](../step02/) の minikube が起動済みで、github上で `arc-runner-set` が runner scale set として登録済みであること

## 手順

- `mdlint` を通すための arc のカスタムイメージを実装する
- github-hosted runner で build して GHCR (GitHub Container Registry) に push する actions を実装する
- github packages から ghcr で publish されたことを確認する
- `values.yml` で publish した image を指定する
- github上で `settings > Developer settings > Personal access tokens > Tokens (classic) > Generate new token > Generate new token (classic)` から `PAT (classic)` を作成する
  - minikube から GHCR へのアクセスは `PAT (classic)` でしか行えない
- `arc-runners` の namespace に secret を登録する

  ```sh
  kubectl create secret docker-registry ghcr-pull-secret \
    --namespace=arc-runners \
    --docker-server=ghcr.io \
    --docker-username=3-yuma-3 \
    --docker-password="$GHCR_READ_PACKAGES_TOKEN"
  ```

  > secret/ghcr-pull-secret created

- `values.yml` で 以下のように指定する

  ```yml
  template:
    spec:
      imagePullSecrets:
        - name: ghcr-pull-secret
  ```

- `helm list -n arc-runners` で今の chart version を確認する。
  - `CHART=gha-runner-scale-set-x.y.z`
- `helm upgrade` の様子を見るために `kubectl get pods -n arc-runners -w` を打っておく
- `helm upgrade` を実行して、 `arc-runner-set` を更新する

  ```sh
  helm upgrade arc-runner-set \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
    --namespace arc-runners \
    --version <現在のチャートバージョンのx.y.z部分> \
    --values step03/helm/arc-runner-set-values.yml
  ```

  > Release "arc-runner-set" has been upgraded. Happy Helming!  
  > NAME: arc-runner-set  
  > NAMESPACE: arc-runners  
  > STATUS: deployed  
  > REVISION: 2  
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
  arc-runner-set-runner-qs4d8   1/1     Running   0          64m
  arc-runner-set-runner-qs4d8   1/1     Terminating   0          69m
  arc-runner-set-runner-qs4d8   1/1     Terminating   0          69m
  arc-runner-set-runner-fvxks   0/1     Pending       0          0s
  arc-runner-set-runner-fvxks   0/1     Pending       0          0s
  arc-runner-set-runner-fvxks   0/1     ContainerCreating   0          0s
  arc-runner-set-runner-qs4d8   0/1     Error               0          69m
  arc-runner-set-runner-fvxks   0/1     ContainerCreating   0          0s
  arc-runner-set-runner-qs4d8   0/1     Error               0          69m
  arc-runner-set-runner-qs4d8   0/1     Error               0          69m
  arc-runner-set-runner-fvxks   1/1     Running             0          8s
  ```

  </details>

- upgrade後のimageがvalues.ymlでの指定と一致していることを確認する

  ```sh
  kubectl get pods -n arc-runners \
    -o custom-columns='POD:.metadata.name,STATUS:.status.phase,IMAGE:.spec.containers[*].image'
  ```

- ciで `mdlint` が通ることを確認する
