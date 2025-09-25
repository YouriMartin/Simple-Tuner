#!/usr/bin/env bash
set -euo pipefail

# Build Android APKs inside Docker and export them to a local ./apk directory
# Requirements: Docker installed and running

# Resolve project root (this script resides in deployment/)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
APK_OUT_DIR="${PROJECT_ROOT}/apk"
IMAGE_TAG="simple-tuner-android-builder:latest"

# Create output directory
mkdir -p "${APK_OUT_DIR}"

# Build the Android builder image (includes required NDK & CMake)
echo "[1/4] Building Docker image ${IMAGE_TAG}..."
docker build -f "${SCRIPT_DIR}/Dockerfile.android" -t "${IMAGE_TAG}" "${PROJECT_ROOT}"

# Run the build inside the container with the project mounted
# We also accept Android licenses to avoid interactive prompts
BUILD_CMD='\
  set -euo pipefail && \
  flutter --version && \
  flutter doctor -v && \
  flutter config --enable-android && \
  yes | flutter doctor --android-licenses >/dev/null 2>&1 || true && \
  flutter pub get && \
  # Clean previous builds to avoid caching issues across hosts \
  flutter clean && \
  # Build split-per-abi release APKs \
  flutter build apk --release --split-per-abi
'

echo "[2/4] Running Flutter build inside Docker..."
docker run --rm \
  -u $(id -u):$(id -g) \
  -v "${PROJECT_ROOT}:/app" \
  -w /app \
  "${IMAGE_TAG}" \
  bash -lc "${BUILD_CMD}"

# Collect artifacts
SRC_DIR="${PROJECT_ROOT}/build/app/outputs/flutter-apk"
echo "[3/4] Collecting APKs from ${SRC_DIR}..."
if compgen -G "${SRC_DIR}/app-*-release.apk" > /dev/null; then
  # Copy all release APKs to apk/ and add timestamp
  TS="$(date +%Y%m%d-%H%M%S)"
  for f in "${SRC_DIR}"/app-*-release.apk; do
    base=$(basename "$f")
    cp -f "$f" "${APK_OUT_DIR}/${TS}-${base}"
  done
else
  echo "No release APKs found in ${SRC_DIR}. Build may have failed." >&2
  exit 1
fi

# Print summary
echo "[4/4] APKs exported to: ${APK_OUT_DIR}"
ls -lh "${APK_OUT_DIR}" | sed '1d'

echo "Done."
