#!/usr/bin/env bash
set -euo pipefail

RUNTIME="${RUNTIME:?RUNTIME must be set to 'docker' or 'podman'}"
COMPOSE_DIR="$(cd "$(dirname "$0")" && pwd)"

BUILD_FLAG=""
if [ "${BUILD:-0}" = "1" ]; then
    BUILD_FLAG="--build"
fi

case "$RUNTIME" in
    docker)
        docker compose -f "$COMPOSE_DIR/compose.yaml" up -d $BUILD_FLAG
        ;;
    podman)
        podman compose -f "$COMPOSE_DIR/compose.yaml" up -d $BUILD_FLAG
        ;;
    *)
        echo "Error: RUNTIME must be 'docker' or 'podman', got '$RUNTIME'"
        exit 1
        ;;
esac
