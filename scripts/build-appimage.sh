#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <stable|insiders> <resolved-archive-url> <version> <output-path>" >&2
  exit 1
fi

CHANNEL="$1"
ARCHIVE_URL="$2"
VERSION="$3"
OUTPUT_PATH="$4"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "${SCRIPT_DIR}/.." && pwd)

case "${CHANNEL}" in
  stable)
    APP_ID="com.visualstudio.code"
    EXECUTABLE="code"
    DESKTOP_SOURCE="${REPO_ROOT}/flatpak/stable/com.visualstudio.code.desktop"
    URL_HANDLER_SOURCE="${REPO_ROOT}/flatpak/stable/com.visualstudio.code-url-handler.desktop"
    PNG_GLOB="${REPO_ROOT}/assets/icons/vscode_*.png"
    SVG_SOURCE="${REPO_ROOT}/assets/icons/vscode.svg"
    ;;
  insiders)
    APP_ID="com.visualstudio.code.insiders"
    EXECUTABLE="code-insiders"
    DESKTOP_SOURCE="${REPO_ROOT}/flatpak/insiders/com.visualstudio.code.insiders.desktop"
    URL_HANDLER_SOURCE="${REPO_ROOT}/flatpak/insiders/com.visualstudio.code.insiders-url-handler.desktop"
    PNG_GLOB="${REPO_ROOT}/assets/icons/vscode_insiders_*.png"
    SVG_SOURCE="${REPO_ROOT}/assets/icons/vscode_insiders.svg"
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

ARCHIVE_PATH="${WORKDIR}/${EXECUTABLE}.tar.gz"
APPDIR="${WORKDIR}/${APP_ID}.AppDir"
CONTENT_DIR="${APPDIR}/usr/share/${EXECUTABLE}"
APPIMAGETOOL_PATH="${WORKDIR}/appimagetool.AppImage"
APPIMAGETOOL_URL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"

mkdir -p "${WORKDIR}/src"
curl -L --fail -o "${ARCHIVE_PATH}" "${ARCHIVE_URL}"
tar -xzf "${ARCHIVE_PATH}" -C "${WORKDIR}/src"

SOURCE_DIR=$(find "${WORKDIR}/src" -mindepth 1 -maxdepth 1 -type d | head -1)
if [ -z "${SOURCE_DIR}" ]; then
  echo "Unable to locate unpacked VS Code directory" >&2
  exit 1
fi

mkdir -p \
  "${CONTENT_DIR}" \
  "${APPDIR}/usr/bin" \
  "${APPDIR}/usr/share/applications"

cp -a "${SOURCE_DIR}/." "${CONTENT_DIR}/"

cat > "${APPDIR}/AppRun" <<EOF
#!/usr/bin/env bash
set -euo pipefail
HERE=\$(dirname "\$(readlink -f "\$0")")
exec "\${HERE}/usr/bin/${EXECUTABLE}" "\$@"
EOF
chmod +x "${APPDIR}/AppRun"

cat > "${APPDIR}/usr/bin/${EXECUTABLE}" <<EOF
#!/usr/bin/env bash
set -euo pipefail
HERE=\$(dirname "\$(readlink -f "\$0")")
exec "\${HERE}/../share/${EXECUTABLE}/${EXECUTABLE}" "\$@"
EOF
chmod +x "${APPDIR}/usr/bin/${EXECUTABLE}"

cp "${DESKTOP_SOURCE}" "${APPDIR}/usr/share/applications/${APP_ID}.desktop"
cp "${URL_HANDLER_SOURCE}" "${APPDIR}/usr/share/applications/$(basename "${URL_HANDLER_SOURCE}")"

for icon_path in ${PNG_GLOB}; do
  icon_name=$(basename "${icon_path}")
  icon_size=$(printf '%s' "${icon_name}" | sed -E 's/.*_([0-9]+)\.png/\1/')
  if [ -z "${icon_size}" ] || [ "${icon_size}" = "${icon_name}" ]; then
    continue
  fi

  install -Dm644 \
    "${icon_path}" \
    "${APPDIR}/usr/share/icons/hicolor/${icon_size}x${icon_size}/apps/${APP_ID}.png"
done

install -Dm644 \
  "${SVG_SOURCE}" \
  "${APPDIR}/usr/share/icons/hicolor/scalable/apps/${APP_ID}.svg"

ln -s "usr/share/applications/${APP_ID}.desktop" "${APPDIR}/${APP_ID}.desktop"
ln -s "usr/share/icons/hicolor/512x512/apps/${APP_ID}.png" "${APPDIR}/${APP_ID}.png"
ln -s "${APP_ID}.png" "${APPDIR}/.DirIcon"

if command -v desktop-file-validate >/dev/null 2>&1; then
  desktop-file-validate "${APPDIR}/usr/share/applications/${APP_ID}.desktop"
fi

curl -L --fail -o "${APPIMAGETOOL_PATH}" "${APPIMAGETOOL_URL}"
chmod +x "${APPIMAGETOOL_PATH}"

mkdir -p "$(dirname "${OUTPUT_PATH}")"
APPIMAGE_EXTRACT_AND_RUN=1 ARCH=x86_64 VERSION="${VERSION}" \
  "${APPIMAGETOOL_PATH}" "${APPDIR}" "${OUTPUT_PATH}"
