#!/usr/bin/env bash
set -euo pipefail

RUNTIME="${RUNTIME:-}"
if [ -z "$RUNTIME" ]; then
    echo "RUNTIME must be set to 'docker' or 'podman'"
    exit 1
fi

BUILD_FLAG=""
if [ "${BUILD:-0}" = "1" ]; then
    BUILD_FLAG="--build"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Project root is two levels above src/cpu
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

IMAGE_NAME="${CPU_IMAGE_NAME:-measurement-cpu:latest}"
CONTAINER_NAME="${CPU_CONTAINER_NAME:-measurement-cpu}"
DOCKERFILE_PATH="$SCRIPT_DIR/Dockerfile"

if [ ! -f "$DOCKERFILE_PATH" ]; then
    echo "Error: Dockerfile not found at $DOCKERFILE_PATH"
    exit 1
fi

if [ "$BUILD_FLAG" = "--build" ]; then
    echo "building image $IMAGE_NAME from $DOCKERFILE_PATH (context: $PROJECT_ROOT)"
    case "$RUNTIME" in
        docker)
            if ! command -v docker >/dev/null 2>&1; then
                echo "Error: docker not found"
                exit 1
            fi
            docker build -f "$DOCKERFILE_PATH" -t "$IMAGE_NAME" "$PROJECT_ROOT"
            ;;
        podman)
            if ! command -v podman >/dev/null 2>&1; then
                echo "Error: podman not found"
                exit 1
            fi
            podman build -f "$DOCKERFILE_PATH" -t "$IMAGE_NAME" "$PROJECT_ROOT"
            ;;
        *)
            echo "Error: RUNTIME must be 'docker' or 'podman', got '$RUNTIME'"
            exit 1
            ;;
    esac
else
    echo "skipping image build"
fi

case "$RUNTIME" in
    docker)
        if ! command -v docker >/dev/null 2>&1; then
            echo "Error: docker not found"
            exit 1
        fi

        # if a container with the same name exists, remove it first
        if docker ps -a --format '{{.Names}}' | grep -xq "$CONTAINER_NAME"; then
            echo "Removing existing container named $CONTAINER_NAME"
            docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
        fi
        ;;
    podman)
        if ! command -v podman >/dev/null 2>&1; then
            echo "Error: podman not found"
            exit 1
        fi

        if podman ps -a --format '{{.Names}}' | grep -xq "$CONTAINER_NAME"; then
            echo "Removing existing container named $CONTAINER_NAME"
            podman rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
        fi
        ;;
    *)
        echo "Error: unsupported RUNTIME: $RUNTIME"
        exit 1
        ;;
esac

echo "Container $CONTAINER_NAME is available to start"