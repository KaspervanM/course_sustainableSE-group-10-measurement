#!/usr/bin/env bash
set -euo pipefail

./src/network/traffic/traffic-controller.sh src/network/traffic/session-config.json 200
