#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <length> <seed> <network | cpu>"
    exit 1
fi

LENGTH=$1
SEED=$2
TASK=$3

IS_LINUX=false
if [ "$(uname)" = "Linux" ]; then
    IS_LINUX=true
else
    echo "Warning: Not running on Linux — systemctl calls will be skipped."
    echo "Runtime isolation is NOT enforced. Docker Desktop must be running."
fi

ENERGIBRIDGE="./energibridge/target/release/energibridge"

if [ ! -x "$ENERGIBRIDGE" ]; then
    echo "energibridge binary not found at $ENERGIBRIDGE — building from source..."
    if [ ! -d "./energibridge" ]; then
        git clone https://github.com/tdurieux/EnergiBridge energibridge
    fi
    cargo build --release --manifest-path ./energibridge/Cargo.toml
    if [ ! -x "$ENERGIBRIDGE" ]; then
        echo "Error: failed to build energibridge"
        exit 1
    fi
fi

# Generate podman-docker sequence
SEQUENCE=$(./src/gen_sequence.sh "$LENGTH" "$SEED")
echo "Generated sequence: $SEQUENCE"

DATETIME=$(date +'%Y%m%d_%H%M%S')

OUTPUT_DIR_PODMAN="./artifacts/podman/test_$DATETIME"
OUTPUT_DIR_DOCKER="./artifacts/docker/test_$DATETIME"
mkdir -p "$OUTPUT_DIR_PODMAN" "$OUTPUT_DIR_DOCKER"

# Pre-build images for both runtimes (not measured by energibridge)
echo "Pre-building container images for Docker..."
if [ "$IS_LINUX" = true ]; then
    sudo systemctl start docker
fi
BUILD=1 RUNTIME=docker "./src/$TASK/container-up.sh"
RUNTIME=docker "./src/$TASK/container-down.sh"

if ! command -v podman &>/dev/null; then
    echo "Error: Podman not found. Both Docker and Podman are required for the experiment."
    exit 1
fi

echo "Pre-building container images for Podman..."
if [ "$IS_LINUX" = true ]; then
    sudo systemctl stop docker.socket || true
    sudo systemctl stop docker || true
    sudo systemctl start podman || true
fi
BUILD=1 RUNTIME=podman "./src/$TASK/container-up.sh"
RUNTIME=podman "./src/$TASK/container-down.sh"

echo "Pre-build complete."

# Start timing after pre-build
INIT_TIME=$(date +%s)

# Loop over podman-docker sequence
for (( i=0; i<${#SEQUENCE}; i++ )); do
    CHAR=${SEQUENCE:$i:1}
    DATETIME=$(date +'%Y%m%d_%H%M%S')
    OUTPUT_FILENAME="measurement1_$DATETIME.csv"

    case $CHAR in
        p)
            echo "Round $((i+1)): Running Podman test (Docker idle)..."

            if [ "$IS_LINUX" = true ]; then
                # Ensure Docker daemon is stopped
                sudo systemctl stop docker.socket || true
                sudo systemctl stop docker || true

                sudo systemctl start podman || true
            fi

            # Run Podman test
            "$ENERGIBRIDGE" \
                -o "$OUTPUT_DIR_PODMAN/$OUTPUT_FILENAME" \
                "./src/$TASK/podman_test.sh"
            ;;
        d)
            echo "Round $((i+1)): Running Docker test (Podman idle)..."

            if [ "$IS_LINUX" = true ]; then
                # Ensure Podman is stopped
                sudo systemctl stop podman.socket || true
                sudo systemctl stop podman || true

                sudo systemctl start docker
            fi

            # Run Docker test
            "$ENERGIBRIDGE" \
                -o "$OUTPUT_DIR_DOCKER/$OUTPUT_FILENAME" \
                "./src/$TASK/docker_test.sh"
            ;;
        *)
            echo "Warning: Unknown character '$CHAR' in sequence..."
            exit
            ;;
    esac
done

END_TIME=$(date +%s)
DIFF=$((END_TIME - INIT_TIME))

HOURS=$((DIFF / 3600))
MIN=$(((DIFF % 3600) / 60))
SEC=$((DIFF % 60))

printf "Elapsed: %02d:%02d:%02d\n" "$HOURS" "$MIN" "$SEC"

echo "Tests completed."
