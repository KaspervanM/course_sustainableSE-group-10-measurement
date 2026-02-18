#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <length> <seed>"
    exit 1
fi

LENGTH=$1
SEED=$2

INIT_TIME=$(date +%s)

vagrant up --provision

# Generate podman-docker sequence
SEQUENCE=$(./gen_sequence.sh "$LENGTH" "$SEED")
echo "Generated sequence: $SEQUENCE"


DATETIME=$(date +'%Y%m%d_%H%M%S')

OUTPUT_DIR_PODMAN="./artifacts/podman/test_$DATETIME"
OUTPUT_DIR_DOCKER="./artifacts/docker/test_$DATETIME"
mkdir -p "$OUTPUT_DIR_PODMAN"
mkdir -p "$OUTPUT_DIR_DOCKER"

# Loop over podman-docker sequence
for (( i=0; i<${#SEQUENCE}; i++ )); do
    CHAR=${SEQUENCE:$i:1}
    DATETIME=$(date +'%Y%m%d_%H%M%S')
    OUTPUT_FILENAME="measurement1_$DATETIME.csv"
    
    case $CHAR in
        p)
            echo "Round $((i+1)): Running Podman test on podman_vm (docker_vm idling)..."

            # Ensure Docker VM is halted / idling
            vagrant halt docker_vm -f
            vagrant up podman_vm

            # Run podman test
            ./energibridge -o "$OUTPUT_DIR_PODMAN/$OUTPUT_FILENAME" vagrant ssh podman_vm -c "./podman_test.sh"

            vagrant halt podman_vm -f
            ;;
        d)
            echo "Round $((i+1)): Running Docker test on docker_vm (podman_vm idling)..."

            # Ensure Podman VM is halted / idling
            vagrant halt podman_vm -f
            vagrant up docker_vm
            
            # Run docker test
            ./energibridge -o "$OUTPUT_DIR_DOCKER/$OUTPUT_FILENAME" vagrant ssh docker_vm -c "./docker_test.sh"

            vagrant halt docker_vm -f
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