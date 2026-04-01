set -o errexit
set -o pipefail
set -o nounset

NAMESPACE_CONTROLLER="arc-systems"
NAMESPACE_RUNNERS="arc-runners"
RUNNER_IMAGE="azuradara/guarc:latest"

setup_kubeconfig() {
    mkdir -p ~/.kube
    sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
    sudo chown "$(id -u):$(id -g)" ~/.kube/config
    export KUBECONFIG=~/.kube/config
}

install_k3s() {
    if command -v k3s &>/dev/null; then
        echo "k3s already installed, skipping"
    else
        echo "Installing k3s..."
        curl -sfL https://get.k3s.io | sh -
    fi
    setup_kubeconfig
}

install_helm() {
    if command -v helm &>/dev/null; then
        echo "Helm already installed, skipping"
        return
    fi
    echo "Installing Helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
}

build_image() {
    echo "Building runner image..."
    docker build -t "$RUNNER_IMAGE" .
    echo "Importing image into k3s containerd store..."
    docker save "$RUNNER_IMAGE" | sudo k3s ctr images import -
}

setup_cache_dirs() {
    sudo mkdir -p \
        /var/cache/arc/composer \
        /var/cache/arc/npm \
        /var/cache/arc/pnpm \
        /var/cache/arc/hostedtoolcache \
        /var/cache/arc/registry
    sudo chown -R 1001:123 /var/cache/arc
}

setup_registry_mirror() {
    if docker ps -q -f name=registry-mirror | grep -q .; then
        echo "Registry mirror already running, skipping"
        return
    fi
    echo "Starting Docker registry mirror..."
    docker run -d \
        --restart=always \
        --name registry-mirror \
        -p 5000:5000 \
        -e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
        -v /var/cache/arc/registry:/var/lib/registry \
        registry:2
}

install_arc_controller() {
    echo "Installing ARC controller..."
    helm upgrade --install arc \
        --namespace "$NAMESPACE_CONTROLLER" \
        --create-namespace \
        -f helm/controller-values.yaml \
        oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller \
        --wait
}

create_docker_secret() {
    if [[ -z "${DOCKER_USER:-}" || -z "${DOCKER_TOKEN:-}" ]]; then
        echo "DOCKER_USER/DOCKER_TOKEN not set, skipping Docker Hub auth"
        return
    fi

    echo "Creating Docker Hub credentials secret..."
    local auth
    auth=$(echo -n "${DOCKER_USER}:${DOCKER_TOKEN}" | base64 -w 0)
    local config="{\"auths\":{\"https://index.docker.io/v1/\":{\"auth\":\"${auth}\"}}}"

    kubectl create secret generic arc-docker-config \
        --namespace "$NAMESPACE_RUNNERS" \
        --from-literal=config.json="$config" \
        --dry-run=client -o yaml | kubectl apply -f -
}

create_secret() {
    local org=$1
    local pat=$2

    kubectl create namespace "$NAMESPACE_RUNNERS" --dry-run=client -o yaml | kubectl apply -f -

    kubectl create secret generic arc-github-secret \
        --namespace "$NAMESPACE_RUNNERS" \
        --from-literal=github_token="$pat" \
        --dry-run=client -o yaml | kubectl apply -f -
}

install_runners() {
    local org=$1
    local max_runners=$2

    echo "Installing runner scale set for org: $org (max: $max_runners)"
    helm upgrade --install arc-runners \
        --namespace "$NAMESPACE_RUNNERS" \
        --create-namespace \
        --set "githubConfigUrl=https://github.com/${org}" \
        --set "minRunners=1" \
        --set "maxRunners=${max_runners}" \
        -f helm/runners-values.yaml \
        oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set \
        --wait
}

main() {
    if [[ $# -lt 2 || $# -gt 3 ]]; then
        printf "\nUsage: ./setup.sh <org> <pat> [max-runners]\n\n"
        exit 2
    fi

    local org=$1
    local pat=$2
    local max_runners=${3:-10}

    install_k3s
    install_helm
    build_image
    kubectl create namespace "$NAMESPACE_RUNNERS" --dry-run=client -o yaml | kubectl apply -f -
    setup_cache_dirs
    setup_registry_mirror
    install_arc_controller
    create_docker_secret
    create_secret "$org" "$pat"
    install_runners "$org" "$max_runners"

    echo ""
    echo "Done. Runners will scale 1 → $max_runners as jobs are queued."
    echo "Watch: kubectl get pods -n $NAMESPACE_RUNNERS -w"
}

main "$@"
