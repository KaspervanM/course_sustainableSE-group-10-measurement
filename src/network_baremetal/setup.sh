#!/usr/bin/env bash
set -euo pipefail

sudo echo "This script uses sudo internally."

PID_MYSQLD=$(sudo db/start-mysql.sh | tail -n1)

$(cd backend && go build)
$(cd frontend && go build)

PID_BACKEND=$(pgrep backend) || true

if [ -n "$PID_BACKEND" ]; then
    echo "Found existing backend process (PID: $PID_BACKEND). Shutting it down..."
    kill -9 $PID_BACKEND
    while kill -0 "$PID_BACKEND" 2>/dev/null; do
        sleep 0.5
    done
fi

./backend/backend &
PID_BACKEND=$!


PID_FRONTEND=$(pgrep frontend) || true

if [ -n "$PID_FRONTEND" ]; then
    echo "Found existing backend process (PID: $PID_FRONTEND). Shutting it down..."
    kill -9 $PID_FRONTEND
    while kill -0 "$PID_FRONTEND" 2>/dev/null; do
        sleep 0.5
    done
fi

./frontend/frontend &
PID_FRONTEND=$!

cleanup() {
    trap - EXIT INT TERM ERR
    if [ -n "$PID_FRONTEND" ] && kill -0 "$PID_FRONTEND" 2>/dev/null; then
        echo "Killing the frontend"
        kill -9 "$PID_FRONTEND"
        wait $PID_FRONTEND 2>/dev/null || true
        $(cd frontend && go clean)
    fi
    if [ -n "$PID_BACKEND" ] && kill -0 "$PID_BACKEND" 2>/dev/null; then
        echo "Killing the backend"
        kill -9 "$PID_BACKEND"
        wait $PID_BACKEND 2>/dev/null || true
        $(cd backend && go clean)
    fi
    if [ -n "$PID_MYSQLD" ] && sudo kill -0 "$PID_MYSQLD" 2>/dev/null; then
        echo "Killing mysqld"
        sudo kill -9 "$PID_MYSQLD"
        wait $PID_MYSQLD 2>/dev/null || true
    fi
    exit
}
trap cleanup EXIT INT TERM ERR

sleep 1
echo "To keep the services running, run this script in the background."
echo "To stop the mysqld, the backend and the frontend, type CTRL-C or run:"
echo "kill -TERM $$"

wait