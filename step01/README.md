# practice-self-hosted-runner - step01

## 目次

- [practice-self-hosted-runner - step01](#practice-self-hosted-runner---step01)
  - [目次](#目次)
  - [参考](#参考)
  - [手順](#手順)
  - [memo](#memo)

## 参考

- [自己ホストランナーの追加](https://docs.github.com/ja/actions/how-tos/manage-runners/self-hosted-runners/add-runners)

## 手順

- repo の `Settings > Actions > Runners` から self-hosted runner の追加手順を閲覧する
- Dockerfile を実装する
  - 必要に応じて `entrypoint.sh`, `compose.yml`, `.env` も実装する
    - この repo の実装内容はあくまで参考程度
- docker container を起動する
- repo の `Settings > Actions > Runners` から起動した docker container が self-hosted runner として登録されたことを確認する
- runner に付与した label を、 actions の `runs-on` で指定する
- actions を実行するのに足りない package は dockerfile に追加して通るようにする
  - 強すぎる権限を避けるため、 dockerfile 内で sudo は installしない。
  - そのため actions 内で sudo も使えない。

## memo

- volume を作成している。
  - 再度 up すれば元の runner として使い続けられる。
  - ただし新しい runner として登録したい場合は以下が必要
    - volume の削除
    - github 上で古い runner の削除
    - `.env` の token の更新
    - `docker compose up -d --build --force-recreate` での再buildが必要
  - down したまま14日間経過するとGitHub側で自動削除されるため、新しい runner としての再登録手順に従う
  - Dockerfile の修正だけなら `docker compose up -d --build --force-recreate` で済む
- runner 登録用 token の期限は1時間
