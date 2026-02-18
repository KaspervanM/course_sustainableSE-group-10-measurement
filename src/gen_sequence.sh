#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <length> <seed>"
    exit 1
fi

P_COUNT=$(($1 + 0))
D_COUNT=$(($1 + 0))
RANDOM=$2


SEQ=""
while true; do
    CHAR=$((RANDOM % 2))
    if [ $P_COUNT -gt 0 ] && [ "$CHAR" -eq 0 ]; then
        SEQ+="p"
        P_COUNT=$((P_COUNT - 1))
    elif [ $D_COUNT -gt 0 ]; then
        SEQ+="d"
        D_COUNT=$((D_COUNT - 1))
    elif [ $P_COUNT -eq 0 ] && [ $D_COUNT -eq 0 ]; then
        echo "$SEQ"
        exit
    fi
done
