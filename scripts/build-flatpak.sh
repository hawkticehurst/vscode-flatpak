#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <stable|insiders> <resolved-archive-url> <sha256> <output-path>" >&2
  exit 1
fi

CHANNEL="$1"
ARCHIVE_URL="$2"
ARCHIVE_SHA="$3"
OUTPUT_PATH="$4"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "${SCRIPT_DIR}/.." && pwd)

case "${CHANNEL}" in
  stable)
    MANIFEST_SOURCE="${REPO_ROOT}/flatpak/stable/com.visualstudio.code.yaml"
    APP_ID="com.visualstudio.code"
    ;;
  insiders)
    MANIFEST_SOURCE="${REPO_ROOT}/flatpak/insiders/com.visualstudio.code.insiders.yaml"
    APP_ID="com.visualstudio.code.insiders"
    ;;
  *)
    echo "Unsupported channel: ${CHANNEL}" >&2
    exit 1
    ;;
esac

WORKDIR=$(mktemp -d)
cleanup() {
  rm -rf "${WORKDIR}"
}
trap cleanup EXIT

MANIFEST_DIR=$(dirname "${MANIFEST_SOURCE}")
MANIFEST_PATH=$(mktemp "${MANIFEST_DIR}/.$(basename "${MANIFEST_SOURCE}").XXXXXX")
BUILD_DIR="${WORKDIR}/build-dir"
REPO_DIR="${WORKDIR}/repo"

cp "${MANIFEST_SOURCE}" "${MANIFEST_PATH}"
sed -i \
  "s|url: PLACEHOLDER_URL|url: ${ARCHIVE_URL}|" \
  "${MANIFEST_PATH}"
sed -i \
  "s|sha256: PLACEHOLDER|sha256: ${ARCHIVE_SHA}|" \
  "${MANIFEST_PATH}"

mkdir -p "$(dirname "${OUTPUT_PATH}")"
flatpak-builder \
  --force-clean \
  --repo="${REPO_DIR}" \
  "${BUILD_DIR}" \
  "${MANIFEST_PATH}"

flatpak build-bundle "${REPO_DIR}" "${OUTPUT_PATH}" "${APP_ID}"
