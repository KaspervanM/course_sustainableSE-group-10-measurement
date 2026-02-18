#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <length> <seed>"
    exit 1
fi

LENGTH=$1
SEED=$2

INIT_TIME=$(date +%s)

# Generate podman-docker sequence
SEQUENCE=$(./gen_sequence.sh "$LENGTH" "$SEED")
echo "Generated sequence: $SEQUENCE"

DATETIME=$(date +'%Y%m%d_%H%M%S')

OUTPUT_DIR_PODMAN="./artifacts/podman/test_$DATETIME"
OUTPUT_DIR_DOCKER="./artifacts/docker/test_$DATETIME"
mkdir -p "$OUTPUT_DIR_PODMAN" "$OUTPUT_DIR_DOCKER"

# Loop over podman-docker sequence
for (( i=0; i<${#SEQUENCE}; i++ )); do
    CHAR=${SEQUENCE:$i:1}
    DATETIME=$(date +'%Y%m%d_%H%M%S')
    OUTPUT_FILENAME="measurement1_$DATETIME.csv"

    case $CHAR in
        p)
            echo "Round $((i+1)): Running Podman test (Docker idle)..."

            # Ensure Docker daemon is stopped
            sudo systemctl stop docker || true
            sudo systemctl start podman || true

            # Run Podman test
            ./energibridge \
                -o "$OUTPUT_DIR_PODMAN/$OUTPUT_FILENAME" \
                ./podman_test.sh
            ;;
        d)
            echo "Round $((i+1)): Running Docker test (Podman idle)..."

            # Ensure Podman is stopped
            sudo systemctl stop podman || true
            sudo systemctl stop podman.socket || true

            sudo systemctl start docker

            # Run Docker test
            ./energibridge \
                -o "$OUTPUT_DIR_DOCKER/$OUTPUT_FILENAME" \
                ./docker_test.sh
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
