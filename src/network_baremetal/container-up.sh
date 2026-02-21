#!/usr/bin/env bash
set -euo pipefail

RUNTIME="${RUNTIME:?RUNTIME must be set to 'docker' or 'podman'}"
COMPOSE_DIR="$(cd "$(dirname "$0")" && pwd)"

case "$RUNTIME" in
    docker)
        docker compose -f "$COMPOSE_DIR/compose.yaml" up -d --build
        ;;
    podman)
        podman compose -f "$COMPOSE_DIR/compose.yaml" up -d --build
        ;;
    *)
        echo "Error: RUNTIME must be 'docker' or 'podman', got '$RUNTIME'"
        exit 1
        ;;
esac
