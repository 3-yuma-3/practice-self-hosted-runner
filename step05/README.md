# practice-self-hosted-runner - step05

## 目次

- [practice-self-hosted-runner - step05](#practice-self-hosted-runner---step05)
  - [目次](#目次)
  - [参考](#参考)
  - [前提](#前提)
  - [手順](#手順)

## 参考

## 前提

- [step04](../step04/) にて minikube で bake を使用した複数の Dockerfile の build & publish が実装済みであること

## 手順

- argocd 用の namespace を作成する manifest を実装する
- argocd の Application resource 向けの manifest を実装する
- helm の values.yml を実装する
- `kubectl apply -f step05/k8s/namespace-argocd.yml` で argocd 用の namespace を作成する

  > namespace/argocd created

- argocd の helm repo を使えるようにする

  ```sh
  helm repo add argo https://argoproj.github.io/argo-helm
  helm repo update
  helm search repo argo/argo-cd --versions
  ```

- argocd を minikube に install する

  ```sh
  helm upgrade --install argocd argo/argo-cd \
    --namespace argocd \
    --version <選択肢た chart version (x.y.z の形式)> \
    --wait
  ```

<details><summary>折りたたみ</summary>

  ```sh
  ❯   helm upgrade --install argocd argo/argo-cd \
      --namespace argocd \
      --version 10.11.1 \
      --wait
  Release "argocd" does not exist. Installing it now.
  NAME: argocd
  NAMESPACE: argocd
  STATUS: deployed
  REVISION: 1
  DESCRIPTION: Install complete
  TEST SUITE: None
  NOTES:
  In order to access the server UI you have the following options:

  1. kubectl port-forward service/argocd-server -n argocd 8080:443

      and then open the browser on http://localhost:8080 and accept the certificate

  2. enable ingress in the values file `server.ingress.enabled` and either
        - Add the annotation for ssl passthrough: https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#option-1-ssl-passthrough
        - Set the `configs.params."server.insecure"` in the values file and terminate SSL at your ingress: https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#option-2-multiple-ingress-objects-and-hosts


  After reaching the UI the first time you can login with username: admin and the random password generated during the installation. You can find the password by running:

  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

  (You should delete the initial secret afterwards as suggested by the Getting Started Guide: https://argo-cd.readthedocs.io/en/stable/getting_started/#4-login-using-the-cli)
  ```

</details>

- `kubectl get pods -n argocd` で argocd の pod が起動されたことを確認する

  ```sh
  ❯ kubectl get pods -n argocd
  NAME                                                READY   STATUS    RESTARTS   AGE
  argocd-application-controller-0                     1/1     Running   0          3m
  argocd-applicationset-controller-7b8b48768f-t9chk   1/1     Running   0          3m
  argocd-dex-server-648d989f85-l8rmf                  1/1     Running   0          3m
  argocd-notifications-controller-66c8f6ccd4-cltbk    1/1     Running   0          3m
  argocd-redis-6494ddbdd-95jwj                        1/1     Running   0          3m
  argocd-repo-server-5778fb6d75-hs4sp                 1/1     Running   0          3m
  argocd-server-7cffbb85cf-qqxrw                      1/1     Running   0          3m
  ```

- Argo CD が private GitHub repository から values file を取得できるように、Fine-grained personal access token (PAT) を発行して Repository Secret を登録する
  - GitHub の avatar から `Settings` → `Developer settings` → `Personal access tokens` → `Fine-grained tokens` → `Generate new token` を選択する
  - Token name を入力し、Resource owner に `3-yuma-3` を選択する
  - Repository access は `Only select repositories` にして、`practice-self-hosted-runner` を選択する
  - Repository permissions の `Contents` を `Read-only` に設定して token を発行する
  - `step05/k8s/argocd-repository-secret.yml` の `stringData.password` には `${GH_READ_TOKEN}` を指定しておく
  - `.env` など別ファイルに token を記述しておき、shell に読み込んでから argocd-repository-secret.yml を apply する

    ```sh
    . ./.env
    envsubst < step05/k8s/argocd-repository-secret.yml | kubectl apply -f -
    ```

    > secret/practice-self-hosted-runner-repo created

- `kubectl port-forward svc/argocd-server -n argocd 8080:443` で argocd-server service の 443 port を、 local の 8080 port に forwarding する。
  - `https://localhost:8080` にアクセスすると argocd の ui が見れる
  - `admin` の password は `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d` で取得する
- argocd の application resource 向けの manifest を適用する
  - argocd の ui に application resource が表示されるようになる
  - この repo の arc runner の values.yml をまだコミットしていなければ argocd が参照するファイルが存在しないので、解消するまではエラーになる

  ```sh
  kubectl apply -f step05/argocd/applications/
  kubectl get applications -n argocd
  kubectl get pods -n arc-runners
  ```

- custom runner image を build, publish する actions の契機を修正して、 step05 配下の Dockerfile に差分が生じた時だけ実行されるようにする
- step05 配下の arc runner の values.yml を追加した pr をマージする。
  - argocd が application resouce 向け manifest で指定している main の path を参照できるようになるので、エラーは解消する。
- マージ時に publish された sha で arc runner の values.yml を更新する。
- `runs-on: arc-runner-set` を `runs-on: arc-runner-buildkit` へ更新する。
- 再度 pr をマージすれば、 gitops は完成する。
  - 少し何かの Dockerfile に変更を加えて pr をマージして、その際の sha に更新して pr をマージすると、 argocd が検知して、minikube の pod に自動反映してくれる
- step04 まで使用していた `arc-runner-set` は `arc-runner-buildkit` に置き換えるので uninstall する

  ```sh
  helm list --all-namespaces
  helm uninstall arc-runner-set --namespace arc-runners
  kubectl get pods -n arc-runners --watch
  helm list --all-namespaces
  ```
