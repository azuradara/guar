set -o errexit
set -o pipefail
set -o nounset

function create {
    name=$1
    org=$2
    token=$3

    docker rm -f $name >/dev/null 2>&1 || true

    docker run -d --restart=always \
        --runtime=sysbox-runc \
        -e ORG_NAME="$org" \
        -e RUNNER_SCOPE="org" \
        -e RUNNER_TOKEN="$token" \
        -e RUNNER_NAME="$name" \
        -e RUNNER_GROUP="" \
        -e LABELS="" \
        --name "$name" azuradara/guar:latest 

    sleep 4

    docker exec -w /actions-runner "$name" "../main.sh"
}

function main() {
    if [[ $# -ne 3 ]]; then
        printf "\nerror: Unexpected number of arguments provided\n"
        printf "\nUsage: ./guar.sh <runner-name> <org> <runner-token>\n\n"
        exit 2
    fi

    create "$1" "$2" "$3"
}

main "$@"
