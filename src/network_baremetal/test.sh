#!/usr/bin/env bash
set -euo pipefail

./src/network_baremetal/traffic/traffic-controller.sh src/network_baremetal/traffic/session-config.json 200
