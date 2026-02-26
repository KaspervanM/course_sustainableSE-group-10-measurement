#!/usr/bin/env bash
set -euo pipefail

RUNTIME="${RUNTIME:-}"
if [ -z "$RUNTIME" ]; then
    echo "RUNTIME must be set to 'docker' or 'podman'"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Project root is two levels above src/cpu
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

CONTAINER_NAME="${CPU_CONTAINER_NAME:-measurement-cpu}"

echo "Tearing down CPU container ($CONTAINER_NAME) under runtime: $RUNTIME"

case "$RUNTIME" in
    docker)
        if ! command -v docker >/dev/null 2>&1; then
            echo "Error: docker not found"
            exit 1
        fi

        if docker ps -a --format '{{.Names}}' | grep -xq "$CONTAINER_NAME"; then
            docker rm -f "$CONTAINER_NAME"
            echo "Removed container $CONTAINER_NAME"
        else
            echo "No container named $CONTAINER_NAME found; nothing to do."
        fi
        ;;
    podman)
        if ! command -v podman >/dev/null 2>&1; then
            echo "Error: podman not found"
            exit 1
        fi

        if podman ps -a --format '{{.Names}}' | grep -xq "$CONTAINER_NAME"; then
            podman rm -f "$CONTAINER_NAME"
            echo "Removed container $CONTAINER_NAME"
        else
            echo "No container named $CONTAINER_NAME found; nothing to do."
        fi
        ;;
    *)
        echo "Error: unsupported RUNTIME: $RUNTIME"
        exit 1
        ;;
esac