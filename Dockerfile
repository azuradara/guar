#
# image: azuradara/guarc
#
# GitHub Actions runner for use with ARC (actions-runner-controller).
# Docker is provided by the DinD sidecar — do not install it here.
#

FROM ghcr.io/actions/actions-runner:latest

USER root

RUN curl -fsSL https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash \
    && apt-get install -y --no-install-recommends \
        git-lfs \
        libmagickwand-dev \
        libmemcached-dev \
        libzstd-dev \
        default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

USER runner
