#!/usr/bin/env bash
set -euo pipefail

RUNTIME=docker ./src/cpu/container-up.sh

IMAGE_NAME="${CPU_IMAGE_NAME:-measurement-cpu:latest}"
CONTAINER_NAME="${CPU_CONTAINER_NAME:-measurement-cpu}"

if ! command -v docker >/dev/null 2>&1; then
    echo "Error: docker not found"
    exit 1
fi

echo "Running search.sh in container $CONTAINER_NAME from image $IMAGE_NAME (runtime: docker)"
docker run --rm --name "$CONTAINER_NAME" "$IMAGE_NAME" sh -lc '/usr/src/cpu/search.sh "startpos" 10000'

RUNTIME=docker ./src/cpu/container-down.sh
