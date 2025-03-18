#! /usr/bin/env bash

exec 100>/tmp/docker-prune.lock || exit 1
flock -w 100 100 || exit 1

docker volume prune -f
