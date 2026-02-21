#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <length> <seed>"
    exit 1
fi

LENGTH=$1
SEED=$2

IS_LINUX=false
if [ "$(uname)" = "Linux" ]; then
    IS_LINUX=true
fi

if [ "$IS_LINUX" = false ]; then
    echo "Warning: Not running on Linux — systemctl calls will be skipped."
    echo "Runtime isolation is NOT enforced. Docker Desktop must be running."
fi

INIT_TIME=$(date +%s)

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
RUNTIME=docker ./src/network_baremetal/container-up.sh
RUNTIME=docker ./src/network_baremetal/container-down.sh

if command -v podman &>/dev/null; then
    echo "Pre-building container images for Podman..."
    if [ "$IS_LINUX" = true ]; then
        sudo systemctl stop docker.socket || true
        sudo systemctl stop docker || true
        sudo systemctl start podman || true
    fi
    RUNTIME=podman ./src/network_baremetal/container-up.sh
    RUNTIME=podman ./src/network_baremetal/container-down.sh
else
    echo "Podman not found — skipping Podman pre-build."
fi

echo "Pre-build complete."

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
            ./energibridge/target/release/energibridge \
                -o "$OUTPUT_DIR_PODMAN/$OUTPUT_FILENAME" \
                ./src/podman_test.sh
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
            ./energibridge/target/release/energibridge \
                -o "$OUTPUT_DIR_DOCKER/$OUTPUT_FILENAME" \
                ./src/docker_test.sh
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
