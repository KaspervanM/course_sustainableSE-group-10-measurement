#!/usr/bin/env bash
set -euo pipefail

TIMEOUT="${TIMEOUT:-120}"
INTERVAL="${INTERVAL:-2}"
ELAPSED=0

echo "Waiting for CPU container to become ready (timeout: ${TIMEOUT}s)..."

RUNTIME="${RUNTIME:-}"
if [ -z "$RUNTIME" ]; then
    echo "RUNTIME must be set to 'docker' or 'podman'"
    exit 1
fi
CONTAINER_NAME="${CPU_CONTAINER_NAME:-measurement-cpu}"

# path inside the container where the test driver/binary should be present
# the dockerfile runtime image places files under /work/src/cpu and sets WORKDIR=/work
TEST_SCRIPT_PATH="/work/src/cpu/test.sh"
ENGINE_BIN_PATH="/work/src/cpu/target/release/chesseng"

while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
    CONTAINER_RUNNING=false
    TEST_SCRIPT_OK=false
    BINARY_OK=false

    case "$RUNTIME" in
        docker)
            if docker ps --format '{{.Names}}' | grep -xq "$CONTAINER_NAME"; then
                CONTAINER_RUNNING=true
            fi

            if [ "$CONTAINER_RUNNING" = true ]; then
                if docker exec "$CONTAINER_NAME" test -x "$TEST_SCRIPT_PATH" >/dev/null 2>&1; then
                    TEST_SCRIPT_OK=true
                fi
                # check if engine binary exists and is executable
                if docker exec "$CONTAINER_NAME" test -x "$ENGINE_BIN_PATH" >/dev/null 2>&1; then
                    BINARY_OK=true
                fi
            fi
            ;;
        podman)
            if podman ps --format '{{.Names}}' | grep -xq "$CONTAINER_NAME"; then
                CONTAINER_RUNNING=true
            fi

            if [ "$CONTAINER_RUNNING" = true ]; then
                if podman exec "$CONTAINER_NAME" test -x "$TEST_SCRIPT_PATH" >/dev/null 2>&1; then
                    TEST_SCRIPT_OK=true
                fi
                if podman exec "$CONTAINER_NAME" test -x "$ENGINE_BIN_PATH" >/dev/null 2>&1; then
                    BINARY_OK=true
                fi
            fi
            ;;
        *)
            echo "Error: unsupported RUNTIME: $RUNTIME"
            exit 1
            ;;
    esac

    if [ "$CONTAINER_RUNNING" = true ] && [ "$TEST_SCRIPT_OK" = true ] && [ "$BINARY_OK" = true ]; then
        echo "CPU container is ready (after ${ELAPSED}s)."
        exit 0
    fi

    sleep "$INTERVAL"
    ELAPSED=$((ELAPSED + INTERVAL))
done

echo "Error: CPU container did not become ready within ${TIMEOUT}s."
exit 1