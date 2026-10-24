#!/bin/sh

# config.sh に失敗した際に止める
set -eu

# 登録済みかどうかは .runner の有無で判定する。登録済みであれば登録処理は行わない。
if [ ! -f .runner ]; then
  ./config.sh --unattended \
    --url "$GITHUB_REPO_URL" \
    --token "$RUNNER_TOKEN" \
    --name "$RUNNER_NAME" \
    --labels "$RUNNER_NAME"
fi

# runner process へ token を引き継がないよう、登録後に unset
unset RUNNER_TOKEN

# Last step, run it!
exec ./run.sh
