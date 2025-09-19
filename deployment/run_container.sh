#!/usr/bin/env bash
# Run the Simple Tuner app in Docker (serving Flutter Web via Nginx)
# Usage examples:
#   ./deployment/run_container.sh                 # builds if needed, runs on http://localhost:8080
#   HOST_PORT=9090 ./deployment/run_container.sh  # override port via env var
#   ./deployment/run_container.sh --build         # force rebuild image
#   ./deployment/run_container.sh -p 5000         # choose port via flag
#   ./deployment/run_container.sh --image-name myimg --container-name myctr
set -euo pipefail

# Defaults (can be overridden via env vars)
IMAGE_NAME=${IMAGE_NAME:-simple-tuner}
CONTAINER_NAME=${CONTAINER_NAME:-simple-tuner}
HOST_PORT=${HOST_PORT:-8080}
FORCE_BUILD=${FORCE_BUILD:-false}
NO_CACHE=${NO_CACHE:-false}

# Parse simple flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--port)
      HOST_PORT="$2"; shift 2 ;;
    --build)
      FORCE_BUILD=true; shift ;;
    --no-cache)
      NO_CACHE=true; shift ;;
    --image-name)
      IMAGE_NAME="$2"; shift 2 ;;
    --container-name)
      CONTAINER_NAME="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [--build] [--no-cache] [-p|--port <hostPort>] [--image-name <name>] [--container-name <name>]";
      exit 0 ;;
    *)
      echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Ensure Docker is available
if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is not installed or not in PATH." >&2
  exit 1
fi

# Resolve repository root (script resides in deployment/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# Decide whether to build the image
IMAGE_EXISTS=$(docker images -q "$IMAGE_NAME:latest" || true)
if [[ -z "$IMAGE_EXISTS" || "$FORCE_BUILD" == "true" ]]; then
  echo "Building Docker image: $IMAGE_NAME:latest"
  BUILD_ARGS=(build -f deployment/Dockerfile -t "$IMAGE_NAME:latest" .)
  if [[ "$NO_CACHE" == "true" ]]; then
    BUILD_ARGS=(build --no-cache -f deployment/Dockerfile -t "$IMAGE_NAME:latest" .)
  fi
  docker "${BUILD_ARGS[@]}"
else
  echo "Image $IMAGE_NAME:latest already exists. Skipping build. Use --build to force rebuild."
fi

# If a container with same name exists, stop and remove it
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Stopping and removing existing container: $CONTAINER_NAME"
  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
fi

# Run the container
echo "Starting container $CONTAINER_NAME from image $IMAGE_NAME:latest on http://localhost:$HOST_PORT"
docker run -d --rm \
  --name "$CONTAINER_NAME" \
  -p "$HOST_PORT:80" \
  "$IMAGE_NAME:latest"

# Show status
sleep 1
docker ps --filter "name=${CONTAINER_NAME}"