#!/bin/bash
# Launcher script for VS Code Flatpak
# Uses zypak-wrapper from Electron BaseApp to properly handle Electron sandboxing

set -e

exec /app/bin/zypak-wrapper.sh /app/vscode/code "$@"
