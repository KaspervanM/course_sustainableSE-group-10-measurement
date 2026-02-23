#!/usr/bin/env bash
set -euo pipefail

BIN_NAME="energibridge"
BIN_SRC="$(which energibridge)"
COPIED_BIN="./energibridge/target/release/${BIN_NAME}"
USER_TO_ADD="$(whoami)"
GROUP_NAME="msr"

cleanup() {
  echo "Cleaning up..."

  rm -f "$COPIED_BIN" || true

  # Try to unload module
  sudo modprobe -r msr 2>/dev/null || true

  # Restore ownership and permissions of /dev/cpu/*/msr
  if compgen -G "/dev/cpu/*/msr" > /dev/null; then
    sudo chown root:root /dev/cpu/*/msr 2>/dev/null || true
    sudo chmod 600 /dev/cpu/*/msr 2>/dev/null || true
  fi

  # Remove user from group
  sudo gpasswd -d "$USER_TO_ADD" "$GROUP_NAME" 2>/dev/null || true

  # Remove group if it exists
  if getent group "$GROUP_NAME" >/dev/null; then
    sudo groupdel "$GROUP_NAME" 2>/dev/null || true
  fi
}

trap cleanup EXIT INT TERM ERR

mkdir -p "$(dirname "$COPIED_BIN")"
cp "$BIN_SRC" "$COPIED_BIN"

sudo setcap cap_sys_rawio=ep "$COPIED_BIN"

sudo modprobe msr || true

sudo groupadd -f "$GROUP_NAME"

sudo chgrp -R "$GROUP_NAME" /dev/cpu/*/msr
sudo chmod g+r /dev/cpu/*/msr

sudo usermod -a -G "$GROUP_NAME" "$USER_TO_ADD"

echo "Switching to a shell with '$GROUP_NAME' group active..."
echo "To exit, run 'exit'"
echo "To run the experiment, run './test.sh <length> <seed>'"
sg "$GROUP_NAME" "$SHELL"
