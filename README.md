## Prerequisites

### Required

- **Docker Desktop** (macOS/Windows) or **Docker Engine** (Linux)
  - macOS/Windows: [Install Docker Desktop](https://docs.docker.com/desktop/)
  - Linux: [Install Docker Engine](https://docs.docker.com/engine/install/) (rootless setup with the Docker daemon)

- **Podman**
  - macOS: `brew install podman && podman machine init && podman machine start`
  - Linux: [Install Podman](https://podman.io/docs/installation#installing-on-linux) via your package manager (e.g. `sudo apt install podman`)
  - Podman on macOS also needs `docker-compose`: `brew install docker-compose`

- **Nix** (provides EnergiBridge, jq, and other dependencies): [Install Nix](https://nixos.org/download/)

- **curl** (used by readiness checks and load testing; pre-installed on macOS and most Linux distros)

### Linux-only

- `systemctl` to toggle Docker/Podman services between measurements
- `setup.sh` configures MSR kernel module permissions for EnergiBridge (opens a subshell with automatic cleanup on exit)

### Verifying installation

```bash
docker --version        # Should print Docker version
podman --version        # Should print Podman version
podman machine list     # macOS: should show a running machine
curl --version          # Should print curl version
```

## Quick Start

```bash
# 1. Enter the Nix shell (installs energibridge + jq, runs setup.sh on Linux)
nix-shell

# 2. Run the full experiment
./test.sh <length> <seed>
```

- `<length>`: number of runs per runtime
- `<seed>`: randomization seed for interleaving Docker/Podman runs

### What happens

1. **Pre-build phase** (not measured): container images are built for both runtimes so build time is excluded from energy measurements.
2. **Randomized sequence**: `src/gen_sequence.sh` produces a balanced interleaving of `d` (Docker) and `p` (Podman) runs.
3. **Per run** (measured by EnergiBridge):
   - On Linux: the inactive runtime's systemd service is stopped, the active one is started
   - `container-up.sh` starts MySQL + backend + frontend via compose
   - `container-ready.sh` polls endpoints until services are healthy (up to 120s)
   - `loadtest.sh` fires HTTP requests across all endpoints
   - `container-down.sh` tears everything down (volumes removed for clean state)
4. Results are saved as CSV files in `./artifacts/{docker,podman}/test_<timestamp>/`.

## Manual Container Testing

```bash
# Start services with Docker
RUNTIME=docker ./src/network_baremetal/container-up.sh

# Wait for readiness
./src/network_baremetal/container-ready.sh

# Run a small load test
./src/network_baremetal/loadtest.sh -c 10 -n 100

# Tear down
RUNTIME=docker ./src/network_baremetal/container-down.sh
```

Replace `docker` with `podman` to test under Podman.

### Load test options

```
./src/network_baremetal/loadtest.sh [-c concurrency] [-n total_requests]
```

- `-c`: number of parallel requests (default: 100)
- `-n`: total number of requests (default: 5000)

## Project Structure

```
test.sh                          # Main experiment runner
setup.sh                         # Linux EnergiBridge setup (MSR permissions)
src/
  gen_sequence.sh                # Generates randomized d/p sequence
  docker_test.sh                 # Single Docker measurement run
  podman_test.sh                 # Single Podman measurement run
  network_baremetal/
    compose.yaml                 # Compose file (works with docker compose & podman compose)
    container-up.sh              # Start containers (RUNTIME=docker|podman)
    container-down.sh            # Stop containers and remove volumes
    container-ready.sh           # Poll endpoints until healthy
    loadtest.sh                  # HTTP load generator (xargs + curl)
    backend/                     # Go backend (port 8081): CPU/mem/SQL stress endpoints
    frontend/                    # Go frontend (port 8080): serves large pages
    db/init.sql                  # MySQL schema
artifacts/                       # Measurement CSV output
```
