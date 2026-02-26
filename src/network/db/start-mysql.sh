#!/usr/bin/env bash
set -euo pipefail

MYSQL_ROOT_PASSWORD="rootpassword"
MYSQL_USER="user"
MYSQL_PASSWORD="pass"
MYSQL_DATABASE="hw_shop"
INIT_SQL="./db/init.sql"
SOCKET_DIR="/run/mysqld"

if ! command -v mysqld >/dev/null 2>&1; then
    echo "Error: MySQL server not found. Please install MySQL."
    exit 1
fi

MYSQL_PID=$(pgrep mysqld) || true

if [ -n "$MYSQL_PID" ]; then
    echo "Found existing MySQL process (PID: $MYSQL_PID). Shutting it down..."
    mysqladmin -u root shutdown 2>/dev/null || kill -9 $MYSQL_PID
    while kill -0 "$MYSQL_PID" 2>/dev/null; do
        sleep 0.5
    done
fi

if [ ! -d "$SOCKET_DIR" ]; then
    echo "Creating MySQL socket directory at $SOCKET_DIR..."
    sudo mkdir -p "$SOCKET_DIR"
    sudo chown mysql:mysql "$SOCKET_DIR"
fi

echo "Starting MySQL server..."
mysqld_safe --socket="$SOCKET_DIR/mysqld.sock" > mysqld.log 2>&1 &
MYSQLD_PID=$!

echo "Waiting for MySQL to be ready..."
MAX_RETRIES=20
i=0
until mysqladmin ping >/dev/null 2>&1; do
    sleep 0.5
    i=$((i+1))
    if [ $i -ge $MAX_RETRIES ]; then
        echo "MySQL did not start in time. Check mysqld.log for errors."
        exit 1
    fi
done

echo "MySQL is ready!"

echo "Initializing database..."
mysql -u root <<EOF
DROP DATABASE IF EXISTS $MYSQL_DATABASE;
CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'localhost';
FLUSH PRIVILEGES;
USE $MYSQL_DATABASE;
SOURCE $INIT_SQL;
EOF

echo "Database '$MYSQL_DATABASE' initialized and ready."

echo "You can connect using:"
echo "  mysql -u $MYSQL_USER -p $MYSQL_PASSWORD $MYSQL_DATABASE"
echo "MySQL server PID:"
echo "$MYSQLD_PID"
