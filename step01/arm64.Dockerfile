FROM ubuntu:26.04@sha256:c098726dd9b9733f3e885f8de0ef375206a311b0a317eadc40d347b1115fb944

ARG RUNNER_VERSION
ARG RUNNER_SHA256

ENV RUNNER_HOME=/home/runner/actions-runner

RUN apt-get -y update && apt-get upgrade -y 

# Dockerfile 内でも sudo は install しないし、 runner 自体も 非root なので、
#  actions 内で必要になる package は Dockerfile 内で install しておく必要がある。
# libatomic1 は setup-node に必要。
# ca-certificates は actionlint の binary 取得に必要
# git は actionlint のrepo自動検出用に必要
RUN apt-get install -y curl \
    libatomic1 \
    ca-certificates \
    git

RUN useradd --create-home runner

WORKDIR ${RUNNER_HOME}

# Download the runner package
RUN curl -o actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz

# Optional: Validate the hash
RUN echo "${RUNNER_SHA256}  actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz" | sha256sum -c -

# Extract the installer
# https://github.com/actions/runner/blob/e78522a9a7b01c3bcd7ac0da6e3a9bb6cd513a76/docs/start/envlinux.md
RUN tar xzf ./actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz \
    && ./bin/installdependencies.sh \
    && chown -R runner:runner ${RUNNER_HOME}

COPY --chown=runner:runner --chmod=755 entrypoint.sh .

USER runner

CMD ["./entrypoint.sh"]
