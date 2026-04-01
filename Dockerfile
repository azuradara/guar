#
# image: azuradara/guar-arc
#
# GitHub Actions runner for use with ARC (actions-runner-controller).
# Docker is provided by the DinD sidecar — do not install it here.
#

FROM ghcr.io/actions/actions-runner:latest

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    jq \
    && rm -rf /var/lib/apt/lists/*

COPY scripts/cleanup.sh /home/runner/cleanup.sh
RUN chmod +x /home/runner/cleanup.sh && \
    echo "ACTIONS_RUNNER_HOOK_JOB_COMPLETED=/home/runner/cleanup.sh" >> /home/runner/.env

USER runner
