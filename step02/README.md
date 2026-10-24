# practice-self-hosted-runner - step02

## 目次

- [practice-self-hosted-runner - step02](#practice-self-hosted-runner---step02)
  - [目次](#目次)
  - [参考](#参考)
  - [手順](#手順)

## 参考

- [Actions Runner Controller](https://docs.github.com/ja/actions/tutorials/use-actions-runner-controller)
- [Actions Runner Controller を使用する](https://docs.github.com/ja/actions/how-tos/manage-runners/use-actions-runner-controller)

## 手順

- `minikube start` で minikube を起動
- `minikube dashboard` で dashboard を起動
- `kubectl config current-context` で context を確認

  > minikube

- `kubectl get nodes -o wide` で node が1台起動状態であることを確認
- helm chart を install

  ```sh
  helm install arc \
   --namespace arc-systems \
   --create-namespace \
   oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller
  ```

- `helm status arc -n arc-systems` で install 状態を確認

  > NAMESPACE: arc-systems
  > STATUS: deployed
  > REVISION: 1
  > DESCRIPTION: Install complete

- `kubectl get deployments,pods -n arc-systems` で pod の deploy 状態を確認
- `kubectl get crd | grep 'actions.github.com'` で CRD (Custom Resource Definition) の登録状態を確認
- github上で `settings > Developer settins > Personal access tokens > Fine-grained tokens` から fine-grained PAT を作成する
  - GHEC などエンプラ向けは GitHub App が推奨
- `kubectl create namespace arc-runners` で `arc-runners` の namespace を作成

  > namespace/arc-runners created

- `arc-runners` の namespace に secret を登録

  ```sh
  kubectl create secret generic pre-defined-secret \
   --namespace=arc-runners \
   --from-literal=github_token='YOUR-PAT'
  ```

  > secret/pre-defined-secret created

- runner scale set 用の values.yml を実装する
- runner scale set を helm で deploy する

  ```sh
  cd step02

  helm install arc-runner-set \
    --namespace arc-runners \
    --values arc-runner-set-values.yml \
    oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
  ```

  > NAME: arc-runner-set  
  > LAST DEPLOYED: Sat Oct 24 18:28:54 2026  
  > NAMESPACE: arc-runners  
  > STATUS: deployed  
  > REVISION: 1  
  > DESCRIPTION: Install complete  
  > TEST SUITE: None  
  > NOTES:  
  > Thank you for installing gha-runner-scale-set.  
  > 
  > Your release is named arc-runner-set.

- `helm list -A` で install できたか確認
- `kubectl get pods -n arc-systems` で pod の状態を確認
- github上で `Settings > Actions > Runners` に `arc-runner-set` が表示されていることを確認
- pod の autoscale を確認するため、 `kubectl get pods -n arc-runners -w` を打っておいて、actions を複数同時に動かす
  - 例えば、複数actionsを定義しているrepoでpushするなど
