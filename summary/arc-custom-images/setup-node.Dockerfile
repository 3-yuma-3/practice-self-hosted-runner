# syntax=docker/dockerfile:1
FROM ghcr.io/actions/actions-runner:2.338.1@sha256:e275409999c37162649aa050ca573f03eab2eabcb3a1e7fcc47548de6b4f9690

USER root

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
    libatomic1 \
    && apt-get clean

USER runner

# GHCRに公開するイメージのソースリポジトリを示すOCIメタデータ（ARCの必須要件ではない）
LABEL org.opencontainers.image.source="https://github.com/3-yuma-3/practice-self-hosted-runner"
