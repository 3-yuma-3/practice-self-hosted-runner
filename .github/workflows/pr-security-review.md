---
on:
  pull_request:
    types: [opened, synchronize]

runs-on: ubuntu-latest
engine: copilot

permissions:
  contents: read
  pull-requests: read

# TODO: mainへ未マージの状態で動作確認するために追加。次のPRで削除する
inlined-imports: true

safe-outputs:
  create-pull-request-review-comment:
    max: 10
  submit-pull-request-review:
    allowed-events: [COMMENT]
  create-issue: false
  report-failure-as-issue: false
  report-failed-jobs: false
  report-incomplete:
    create-issue: false
  report-missing-tool:
    create-issue: false
  report-missing-data:
    create-issue: false
  threat-detection:
    report-as-issue: false
---

# PR Security Review

このプルリクエストの差分を対象に、具体的なセキュリティ上の問題をレビューしてください。
必要に応じて周辺のコードも確認し、指摘の根拠を検証してください。

指摘には、該当箇所、影響、問題が発生する条件を含めてください。
対応が必要な問題に限って、自然な日本語でインラインコメントを投稿してください。

コードの変更やプルリクエストの承認は行わないでください。
