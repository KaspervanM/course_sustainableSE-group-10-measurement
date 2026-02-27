#!/usr/bin/env bash
set -euo pipefail

RUNTIME=podman ./src/network/container-up.sh
./src/network/container-ready.sh
./src/network/loadtest.sh
RUNTIME=podman ./src/network/container-down.sh
