#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <config_file> <num_processes>"
    exit 1
fi

CONFIG_FILE=$1
NUM_PROCS=$2
DELAY=0.2

pids=()

cleanup() {
    trap - EXIT INT TERM ERR
    echo "Parent exiting. Stopping children..."
    for pid in "${pids[@]:-}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill -TERM "$pid" || true
        fi
    done

    wait "${pids[@]:-}" 2>/dev/null || true
    exit
}
trap cleanup EXIT INT TERM ERR

for ((i=1; i<=NUM_PROCS; i++)); do
    WORKER=$(( (i - 1) % 3 + 1 ))
    ID=$i

    echo "Starting worker=$WORKER id=$ID"

    ./src/network/traffic/session-simulator.sh "$CONFIG_FILE" "$WORKER" "$ID" &
    pids+=($!)

    sleep "$DELAY"
done

wait "${pids[@]}"
