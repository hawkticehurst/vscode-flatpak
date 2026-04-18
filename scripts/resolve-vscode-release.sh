#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <stable|insiders> <tag-prefix> <output-file> <event-name>" >&2
  exit 1
fi

CHANNEL="$1"
TAG_PREFIX="$2"
OUTPUT_FILE="$3"
EVENT_NAME="$4"

case "$CHANNEL" in
  stable)
    DOWNLOAD_CHANNEL="stable"
    ARCHIVE_PATH="/tmp/vscode-stable.tar.gz"
    ;;
  insiders)
    DOWNLOAD_CHANNEL="insider"
    ARCHIVE_PATH="/tmp/vscode-insiders.tar.gz"
    ;;
  *)
    echo "Unsupported channel: $CHANNEL" >&2
    exit 1
    ;;
esac

CDN_URL=$(curl -sIL -o /dev/null -w '%{url_effective}' "https://update.code.visualstudio.com/latest/linux-x64/${DOWNLOAD_CHANNEL}")
echo "Resolved CDN URL: ${CDN_URL}"

curl -L --fail -o "${ARCHIVE_PATH}" "${CDN_URL}"
if [ ! -s "${ARCHIVE_PATH}" ]; then
  echo "Error: download failed or archive is empty" >&2
  exit 1
fi

SHA=$(sha256sum "${ARCHIVE_PATH}" | awk '{print $1}')
PACKAGE_JSON_PATH=$(tar -tzf "${ARCHIVE_PATH}" | grep -m1 'resources/app/package.json$' || true)
VERSION=""
if [ -n "${PACKAGE_JSON_PATH}" ]; then
  VERSION=$(tar -xOf "${ARCHIVE_PATH}" "${PACKAGE_JSON_PATH}" | sed -n 's/^[[:space:]]*"version":[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
fi
if [ -z "${VERSION}" ]; then
  VERSION="unknown"
fi

TAG="${TAG_PREFIX}-${SHA:0:12}"

if git rev-parse -q --verify "refs/tags/${TAG}" >/dev/null; then
  BUILD_NEEDED=false
else
  BUILD_NEEDED=true
fi

if [ "${EVENT_NAME}" = "workflow_dispatch" ]; then
  SHOULD_BUILD=true
else
  SHOULD_BUILD="${BUILD_NEEDED}"
fi

{
  echo "sha=${SHA}"
  echo "version=${VERSION}"
  echo "url=${CDN_URL}"
  echo "tag=${TAG}"
  echo "build_needed=${BUILD_NEEDED}"
  echo "should_build=${SHOULD_BUILD}"
} >> "${OUTPUT_FILE}"

echo "Calculated checksum: ${SHA}"
echo "Detected VS Code version: ${VERSION}"
echo "Build needed (new upstream): ${BUILD_NEEDED}"
echo "Should build in this run: ${SHOULD_BUILD}"
