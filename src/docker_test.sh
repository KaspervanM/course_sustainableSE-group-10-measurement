#!/usr/bin/env bash
set -euo pipefail

RUNTIME=docker ./src/network_baremetal/container-up.sh
./src/network_baremetal/container-ready.sh
./src/network_baremetal/loadtest.sh -c 10 -n 50
RUNTIME=docker ./src/network_baremetal/container-down.sh
