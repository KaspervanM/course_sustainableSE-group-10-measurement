## Prerequisites

### Required on all platforms

| Tool | Purpose | Install |
|------|---------|---------|
| **Docker** | Container runtime under test | macOS/Windows: [Docker Desktop](https://docs.docker.com/desktop/) · Linux: [Docker Engine](https://docs.docker.com/engine/install/) (rootless, with daemon) |
| **Podman** | Container runtime under test | macOS: `brew install podman` · Linux: `sudo apt install podman` (or distro equivalent) |
| **podman-compose** | Compose support for Podman | macOS: `brew install docker-compose` · Linux: `pip install podman-compose` |
| **EnergiBridge** | Energy measurement | See below |
| **curl** | Readiness checks and load testing | Pre-installed on macOS and most Linux distros |

### EnergiBridge

**Linux (via Nix — recommended):**
```bash
# nix-shell provides energibridge, jq, and all other deps automatically
nix-shell
```
[Install Nix](https://nixos.org/download/) if not already available.

**macOS (build from source):**
```bash
git clone https://github.com/tdurieux/EnergiBridge energibridge
cd energibridge && cargo build --release && cd ..
```
Requires [Rust](https://rustup.rs/) (`brew install rust`). `test.sh` expects the binary at `./energibridge/target/release/energibridge` and will attempt to build it automatically if missing.

### Linux-only

- `systemctl` — used to toggle Docker/Podman services between measurements
- MSR kernel module — required by EnergiBridge to read CPU energy registers; `setup.sh` loads it and sets permissions, then cleans up on exit

### macOS caveats

- `systemctl` is unavailable — Docker and Podman cannot be toggled between runs, so both may be active simultaneously (**runtime isolation is not enforced**)
- Docker Desktop must be running before starting the experiment

### Data analysis

- **Python 3** with `venv`
- **Jupyter**: `pip install jupyter`
- **Packages** (installed automatically by the notebook): `pandas`, `numpy`, `matplotlib`, `scipy`, `seaborn`

### Verify your setup

```bash
docker --version          # Docker version 27.x.x
podman --version          # podman version 5.x.x
podman machine list       # macOS: confirm a machine is running
curl --version            # curl 8.x.x
```

---

## Quick Start

### Linux

```bash
# 1. Enter Nix shell (installs energibridge + jq, runs setup.sh)
nix-shell

# 2. Run the experiment — 35 runs per runtime, seed 42
./test.sh 35 42
```

### macOS

```bash
# 1. Build EnergiBridge (one-time; skipped automatically on subsequent runs)
git clone https://github.com/tdurieux/EnergiBridge energibridge
cd energibridge && cargo build --release && cd ..

# 2. Run the experiment
./test.sh 35 42
```

---

## Usage

### `test.sh` — main experiment runner

```
./test.sh <length> <seed>
```

| Argument | Description |
|----------|-------------|
| `<length>` | Number of measurement runs **per runtime**. Total runs = `2 × length` (Docker and Podman are interleaved). |
| `<seed>` | Integer seed for reproducible randomization of the Docker/Podman run order. |

**Example:** `./test.sh 35 42` runs 70 measurements total (35 Docker + 35 Podman) in a randomly interleaved order seeded by `42`.

Results are written to `./artifacts/{docker,podman}/test_<timestamp>/` as CSV files.

### `src/network/loadtest.sh` — HTTP load generator

```
./src/network/loadtest.sh [-c <concurrency>] [-n <total_requests>]
```

| Flag | Default | Description |
|------|---------|-------------|
| `-c` | `15` | Number of parallel requests (via `xargs -P`) |
| `-n` | `2000` | Total number of HTTP requests to send |

Requests are distributed round-robin across 7 endpoints (frontend pages + backend stress/SQL endpoints). The database is seeded before load begins.

### `src/network/container-up.sh` — start containers

```
RUNTIME=<docker|podman> [BUILD=1] ./src/network/container-up.sh
```

| Variable | Default | Description |
|----------|---------|-------------|
| `RUNTIME` | *(required)* | `docker` or `podman` |
| `BUILD` | `0` | Set to `1` to build images before starting (needed on first run) |

### `src/network/container-ready.sh` — wait for services

Polls `http://localhost:8080/page1` (frontend) and `http://localhost:8081/seed?count=1` (backend) every **2 seconds** until both respond, or until the **120-second timeout** is reached.

### `src/gen_sequence.sh` — randomized run order

```
./src/gen_sequence.sh <length> <seed>
```

Outputs a string of `d` and `p` characters of length `2 × length`, balanced (equal Docker and Podman runs), randomized using the given seed.

---

## What happens during `test.sh`

1. **Pre-build** (not measured): container images are built for both Docker and Podman so build time is excluded from energy measurements. Timing starts after this step.
2. **Sequence generation**: `src/gen_sequence.sh` produces a balanced, randomly interleaved sequence of `d` and `p` tokens.
3. **Per run** (measured by EnergiBridge):
   - *Linux only:* the inactive runtime's systemd service is stopped; the active one is started
   - `container-up.sh` starts MySQL + backend + frontend via compose (no `--build`, images are pre-built)
   - `container-ready.sh` polls until services are healthy (up to 120s)
   - `loadtest.sh` fires HTTP requests across all endpoints (`-c 15`, `-n 2000`)
   - `container-down.sh` tears everything down and removes volumes for a clean state
4. **Output**: each run's CSV is saved to `./artifacts/{docker,podman}/test_<timestamp>/measurement1_<timestamp>.csv`

---

## Manual Container Testing

```bash
# First run: build images and start services
BUILD=1 RUNTIME=docker ./src/network/container-up.sh

# Wait for readiness (polls every 2s, 120s timeout)
./src/network/container-ready.sh

# Run a small load test
./src/network/loadtest.sh -c 5 -n 100

# Tear down (removes volumes)
RUNTIME=docker ./src/network/container-down.sh
```

Replace `docker` with `podman` to test under Podman. Omit `BUILD=1` on subsequent runs to reuse existing images.

---

## Project Structure

```
test.sh                          # Main experiment runner
setup.sh                         # Linux: loads MSR module + sets EnergiBridge permissions
configuration.nix                # NixOS configuration of the machine used for measurements
analysis.ipynb                   # Jupyter notebook for data analysis and plots
shell.nix                        # Nix shell: installs energibridge, jq, and deps
src/
  gen_sequence.sh                # Generates randomized d/p run sequence
  docker_test.sh                 # Single Docker measurement run
  podman_test.sh                 # Single Podman measurement run
  network/
    compose.yaml                 # Compose file (works with docker compose & podman compose)
    container-up.sh              # Start containers (RUNTIME=docker|podman, BUILD=1 to rebuild)
    container-down.sh            # Stop containers and remove volumes
    container-ready.sh           # Poll until frontend + backend are healthy (120s timeout)
    loadtest.sh                  # HTTP load generator — defaults: -c 15 -n 2000
    backend/                     # Go backend (port 8081): /stress/cpu, /stress/mem, /stress/sql
    frontend/                    # Go frontend (port 8080): serves large static pages
    db/
      Dockerfile                 # Pre-initialized MySQL image
      init.sql                   # Schema and seed data
artifacts/                       # Measurement CSVs (created at runtime)
test_results/                    # Copy measurements here for analysis (docker/ and podman/ subdirs)
```

---

## Replicability

Measurements were collected on a desktop running NixOS. The full system configuration is in `configuration.nix`.

---

## Data Analysis

1. Copy the desired measurement folders into `test_results/`:
   ```
   test_results/
     docker/test_<timestamp>/
     podman/test_<timestamp>/
   ```
2. Create a Python virtual environment and launch Jupyter:
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   pip install jupyter
   jupyter notebook
   ```
3. Open `analysis.ipynb` and run all cells. The first cell installs required packages (`pandas`, `numpy`, `matplotlib`, `scipy`, `seaborn`) into the active environment automatically.
