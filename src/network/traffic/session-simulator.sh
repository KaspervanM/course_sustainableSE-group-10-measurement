#!/usr/bin/env bash
set -euo pipefail

BACKEND="http://localhost:8081"
FRONTEND="http://localhost:8080"

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <json_file> <session_number> <job_id>"
  exit 1
fi

JSON_FILE="$1"
SESSION="$2"
ID="$3"
TEMP_FILE="tmpfile_$ID"

cleanup() {
    trap - EXIT INT TERM ERR
    if [ -n "$ACTIVE_PID" ] && kill -0 "$ACTIVE_PID" 2>/dev/null; then
        kill -9 "$ACTIVE_PID" 2>/dev/null || true
        wait $ACTIVE_PID 2>/dev/null || true
    fi
    [[ -f "$TEMP_FILE" ]] && rm "$TEMP_FILE" 2>/dev/null || true
    exit
}
trap cleanup EXIT INT TERM ERR

while read -r step; do
    contact=$(jq -r '.contact' <<<"$step")
    request=$(jq -r '.request' <<<"$step")
    delay=$(jq -r '.delay_after' <<<"$step")

    case "$contact" in
        backend)
            url="${BACKEND}${request}"
            ;;
        frontend)
            url="${FRONTEND}${request}"
            ;;
        *)
            echo "Unknown contact: $contact" >&2
            exit 1
            ;;
    esac

    echo "$ID requesting: $url"
    wget -q -O "$TEMP_FILE" "$url" &
    ACTIVE_PID=$!
    wait "$ACTIVE_PID"

    if [[ "$delay" != "0" ]]; then
        sleep "$delay" &
        ACTIVE_PID=$!
        wait "$ACTIVE_PID"
    fi
done < <(jq -c --arg s "$SESSION" '.[$s][]' "$JSON_FILE")

echo "Finished job $ID of session $SESSION"
