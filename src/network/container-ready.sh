#!/usr/bin/env bash
set -euo pipefail

TIMEOUT=120
INTERVAL=2
ELAPSED=0

echo "Waiting for services to become ready (timeout: ${TIMEOUT}s)..."

while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
    FRONTEND_OK=false
    BACKEND_OK=false

    if curl -sf --max-time 2 -o /dev/null http://localhost:8080/page1 2>/dev/null; then
        FRONTEND_OK=true
    fi

    if curl -sf --max-time 2 -o /dev/null 'http://localhost:8081/seed?count=1' 2>/dev/null; then
        BACKEND_OK=true
    fi

    if [ "$FRONTEND_OK" = true ] && [ "$BACKEND_OK" = true ]; then
        echo "All services are ready (after ${ELAPSED}s)."
        exit 0
    fi

    sleep "$INTERVAL"
    ELAPSED=$((ELAPSED + INTERVAL))
done

echo "Error: Services did not become ready within ${TIMEOUT}s."
exit 1
