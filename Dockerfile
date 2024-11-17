#
# image: azuradara/guar
# 
# A github actions runner based on ubuntu jammy
#

FROM ubuntu:jammy

LABEL maintainer="dara-@outlook.jp"

RUN apt-get update && apt-get install --no-install-recommends -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg-agent \
  software-properties-common

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

RUN apt-key fingerprint 0EBFCD88

RUN add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"

RUN apt-get update && apt-get install --no-install-recommends -y docker-ce docker-ce-cli containerd.io

ENV AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache

RUN mkdir -p /opt/hostedtoolcache

ARG GH_RUNNER_VERSION="2.309.0"

ARG TARGETPLATFORM

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends dumb-init jq \
  && groupadd -g 121 runner \
  && useradd -mr -d /home/runner -u 1001 -g 121 runner \
  && usermod -aG sudo runner \
  && usermod -aG docker runner \
  && echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

WORKDIR /actions-runner

COPY scripts/install_actions.sh /actions-runner

RUN chmod +x /actions-runner/install_actions.sh \
  && /actions-runner/install_actions.sh ${GH_RUNNER_VERSION} ${TARGETPLATFORM} \
  && rm /actions-runner/install_actions.sh \
  && chown runner /_work /actions-runner /opt/hostedtoolcache

COPY scripts/token.sh scripts/main.sh scripts/app_token.sh /

RUN chmod +x /token.sh /main.sh /app_token.sh

ENTRYPOINT ["/main.sh"]

CMD ["./bin/Runner.Listener", "run", "--startuptype", "service"]
