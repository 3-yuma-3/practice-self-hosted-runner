FROM debian:trixie-20261020@sha256:4c25275446ca371766b8b093c696782eabce06263fccacb8d5d813b3dc44b308

ARG RUNNER_VERSION
ARG RUNNER_SHA256_AMD64
ARG RUNNER_SHA256_ARM64
ARG TARGETARCH

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    jq \
    unzip \
    zip \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home runner

RUN case "${TARGETARCH}" in \
      amd64) runner_arch=x64 ;; \
      arm64) runner_arch=arm64 ;; \
    esac \
    && curl --fail --show-error --location --retry 3 \
      --output /tmp/actions-runner.tar.gz \
      "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${runner_arch}-${RUNNER_VERSION}.tar.gz"

RUN case "${TARGETARCH}" in \
      amd64) runner_sha256=${RUNNER_SHA256_AMD64} ;; \
      arm64) runner_sha256=${RUNNER_SHA256_ARM64} ;; \
    esac \
    && echo "${runner_sha256}  /tmp/actions-runner.tar.gz" | sha256sum -c -

RUN tar -xzf /tmp/actions-runner.tar.gz -C /home/runner \
    && /home/runner/bin/installdependencies.sh \
    && chown -R runner:runner /home/runner \
    && rm -f /tmp/actions-runner.tar.gz;

ENV HOME=/home/runner
WORKDIR /home/runner
USER runner
