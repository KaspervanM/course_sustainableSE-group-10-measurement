#!/usr/bin/env bash
set -euo pipefail

RUNTIME=docker ./src/network/container-up.sh
./src/network/container-ready.sh
./src/network/loadtest.sh
RUNTIME=docker ./src/network/container-down.sh
