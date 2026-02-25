#!/usr/bin/env bash
set -euo pipefail

RUNTIME=docker ./src/cpu/container-up.sh
./src/cpu/container-ready.sh
./src/cpu/search.sh "startpos" 10000
RUNTIME=docker ./src/cpu/container-down.sh