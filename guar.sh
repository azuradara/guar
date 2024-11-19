set -o errexit
set -o pipefail
set -o nounset

function create {
    name=$1
    org=$2
    repo=$3
    token=$4

    docker rm -f $name >/dev/null 2>&1 || true

    docker run -d --restart=always \
        --runtime=sysbox-runc \
        -e REPO_URL="https://github.com/${org}/${repo}" \
        -e RUNNER_TOKEN="$token" \
        -e RUNNER_NAME="$name" \
        -e RUNNER_GROUP="" \
        -e LABELS="" \
        --name "$name" azuradara/guar:latest
}

function main() {
    if [[ $# -ne 4 ]]; then
        printf "\nerror: Unexpected number of arguments provided\n"
        printf "\nUsage: ./guar.sh <runner-name> <org> <repo-name> <runner-token>\n\n"
        exit 2
    fi

    create "$1" "$2" "$3" "$4"
}

main "$@"
