#!/usr/bin/env bash
set -euo pipefail

# Defaults
CONCURRENCY=100
TOTAL=5000

while getopts "c:n:" opt; do
    case "$opt" in
        c) CONCURRENCY="$OPTARG" ;;
        n) TOTAL="$OPTARG" ;;
        *) echo "Usage: $0 [-c concurrency] [-n total_requests]"; exit 1 ;;
    esac
done

# Endpoints matching the session profiles
ENDPOINTS=(
    "http://localhost:8080/page1"
    "http://localhost:8081/stress/mem?size_mb=10&seconds=1"
    "http://localhost:8080/page2"
    "http://localhost:8081/seed?count=1"
    "http://localhost:8081/stress/sql?intensity=2"
    "http://localhost:8080/page3"
    "http://localhost:8081/stress/mem?size_mb=12&seconds=1"
    "http://localhost:8081/seed?count=2"
    "http://localhost:8081/stress/sql?intensity=1"
    "http://localhost:8081/stress/mem?size_mb=15&seconds=3"
)

NUM_ENDPOINTS=${#ENDPOINTS[@]}

echo "Load test: $TOTAL requests, concurrency $CONCURRENCY"
echo "Endpoints: $NUM_ENDPOINTS"

# Generate URL list (round-robin across endpoints)
URL_LIST=$(mktemp)
trap 'rm -f "$URL_LIST"' EXIT

for (( i=0; i<TOTAL; i++ )); do
    echo "${ENDPOINTS[$((i % NUM_ENDPOINTS))]}"
done > "$URL_LIST"

# Fire requests in parallel using xargs + curl
xargs -P "$CONCURRENCY" -I {} \
    curl -sf --max-time 30 -o /dev/null {} \
    < "$URL_LIST"

echo "Load test complete: $TOTAL requests finished."
