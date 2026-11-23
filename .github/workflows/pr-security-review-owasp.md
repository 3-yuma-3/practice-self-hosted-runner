---
on:
  pull_request:
    types: [opened, synchronize]

runs-on: ubuntu-latest
engine:
  id: copilot
  model: gpt-6-luna
  args: ["--reasoning-effort", "max"]

permissions:
  contents: read
  pull-requests: read
  issues: read

checkout:
  ref: ${{ github.event.pull_request.base.sha }}

steps:
  - name: Install apm by mise
    uses: jdx/mise-action@v5.2.10
    with:
      install_args: "apm"

  - name: Install skills by apm
    run: apm install --frozen

  - name: Verify apm lockfile and deployed files
    run: apm audit --ci
    env:
      GITHUB_APM_PAT: ${{ github.token }}

# TODO: mainへ未マージの状態で動作確認するために追加。次のPRで削除する
inlined-imports: true
tools:
  # find は -exec で別コマンドも実行できるため、含めていない。
  # git も許可しないので、差分は GitHub MCP から取得する。
  bash: ["cat", "ls", "grep", "head", "tail", "wc"]
  github:
    # 信頼度がnoneに分類されるpr差分を読むため、最低信頼度をデフォルトのapprovedからnoneに緩和
    min-integrity: none
    # GitHub MCPの対象をこのrepoに限定、したいがpublic repoではgh awの内部実装により上書きされるため効かない
    allowed-repos:
      - "3-yuma-3/practice-self-hosted-runner"

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

# PR Security Review by owasp code-security-skills

以下の Skill を使用してください。

- /code-review-security
- /secrets-scan
- /securability-engineering-review

次の Skill は、PR の変更または関連コードに対象がある場合に使用してください。

- /iac-security-review : IaC
- /api-security-review : API
- /web-security-review : Web アプリケーション
- /mobile-code-review : モバイルアプリ
- /prd-securability-enhancement : PRD・仕様書

次の Skill は、主にコード生成・実装向けでありレビュー向けではないので呼び出し不要です。

- /security-guidance
- /securability-engineering

次の Skill は、指定されたスキャナーが現在の bash 許可リストでは実行できないため呼び出し不要です。

- /sca-audit

依存関係がレビュー対象の場合は、SCA が未実施であることとその理由を報告してください。

各 Skill の参照先は `.agents/plugins/code-security-skills/` 内を確認してください。
使用した Skill、非該当の Skill、使用できなかった Skill とその理由を報告してください。
非該当は未完了として扱わないでください。

利用できないツールはインストールせず、未実施として報告してください。
秘密情報の値はレビュー結果に記載しないでください。
ASVS 番号は参照先の内容と照合し、確認できなければ番号を省略してください。

この PR の変更について、リポジトリ全体の構成と既存の動作を踏まえて
具体的なセキュリティ上の問題をレビューしてください。

まず変更ファイル一覧をページ単位で取得し、各ファイルの差分を確認してください。
そのうえで、変更に関連する呼び出し元・呼び出し先、設定、権限、
データの流れ、信頼境界などをリポジトリ全体から調べ、
変更による影響と指摘の根拠を検証してください。
変更と無関係な全ファイルを網羅的に監査する必要はありません。

生成ファイルは、権限、実行ステップ、依存先などの重要な変更を確認してください。
巨大な生成ファイルの全文確認を強制せず、確認した範囲と未確認範囲を報告してください。

作業ツリーはマージ後の状態とは限りません。
必要に応じて PR の head と base の内容を確認し、
マージ後の挙動を判断できない場合は、その制約を報告してください。

指摘には、該当箇所、影響、問題が発生する条件を含めてください。
PR の差分上で指摘できる問題は、自然な日本語でインラインコメントを投稿してください。
差分外の関連箇所に関する指摘は、レビュー本文に記載してください。

Skill を使用できない場合や、必要な差分・関連コードを確認できない場合は、
未確認の範囲と理由を report_incomplete で報告し、
レビュー完了や問題なしと判断しないでください。

確認できた範囲、指摘の有無、未確認範囲を
submit_pull_request_review の COMMENT で報告してください。
コードの変更やプルリクエストの承認は行わないでください。
