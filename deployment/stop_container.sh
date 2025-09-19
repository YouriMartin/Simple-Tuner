#!/usr/bin/env bash
# Stop and remove the Simple Tuner Docker container
# Usage:
#   ./deployment/stop_container.sh                # stops container named 'simple-tuner'
#   CONTAINER_NAME=myctr ./deployment/stop_container.sh
#   ./deployment/stop_container.sh --container-name myctr
set -euo pipefail

CONTAINER_NAME=${CONTAINER_NAME:-simple-tuner}

# Parse flag
while [[ $# -gt 0 ]]; do
  case "$1" in
    --container-name)
      CONTAINER_NAME="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [--container-name <name>]"; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is not installed or not in PATH." >&2
  exit 1
fi

if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Stopping running container: $CONTAINER_NAME"
  docker stop "$CONTAINER_NAME" >/dev/null
elif docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Container $CONTAINER_NAME is not running. Removing it."
fi

# Remove container if exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  docker rm "$CONTAINER_NAME" >/dev/null
  echo "Container $CONTAINER_NAME removed."
else
  echo "No container named $CONTAINER_NAME found. Nothing to do."
fi
