#!/usr/bin/env bash

# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

# Script to handle exoticisms related to 'docker login' and 'docker push'.
#
# Log in to docker.elastic.co if the namespace eck, eck-ci or eck-snapshots is used
# Log in to gcloud if GCR is used

set -euo pipefail

# source variables if present
if [[ -f .registry.env ]]; then
    # shellcheck disable=SC2046
    export $(sed "s|[[:space:]]*=[[:space:]]*|=|g" .registry.env)
fi

docker-login() {
    local image=$1
    local registry=${image%%"/"*}

    if grep -q "$registry" ~/.docker/config.json; then
        # already logged in
        return 0
    fi

    case "$image" in

        */eck/*|*/eck-ci/*|*/eck-snapshots/*)
            echo "Authentication to ${registry}..."
            docker login -u "${DOCKER_LOGIN}" -p "${DOCKER_PASSWORD}" docker.elastic.co 2> /dev/null
        ;;

        *.gcr.io/*)
            echo "Authentication to ${registry}..."
            gcloud auth configure-docker --quiet 2> /dev/null
        ;;

        *)
            if ! grep -q "$registry" ~/.docker/config.json; then
               echo "Please log in to $registry."
               exit 1
            fi
        ;;
    esac
}

docker-push() {
    local image=$1
    echo "Push $image..."
    # silence the verbose output of the `docker push` command
    docker push "$image" | grep -v -E 'Waiting|Layer already|Preparing|Pushing|Pushed'
}

docker-login "$@"
docker-push  "$@"
