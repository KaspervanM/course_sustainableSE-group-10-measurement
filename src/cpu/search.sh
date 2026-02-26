#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <starting position> <search milliseconds>"
    exit 1
fi

START_POS=$1
SEARCH_MS=$2

{ 
  printf "uci\nisready\n"
  printf "position %s\n" "$START_POS"
  printf "go movetime %s\n" "$SEARCH_MS"
  sleep $((SEARCH_MS / 1000 + 1))
} | /usr/src/cpu/target/release/chesseng
