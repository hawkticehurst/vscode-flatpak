# Visual Studio Code Flatpak / AppImage

A set of prototype build pipelines for VS Code and VS Code Insiders Flatpak and AppImage distributions.

## Install

This repository checks for new VS Code and VS Code Insiders versions every 6 hours. If a new upstream version is found, a new flatpak build is triggered automatically.

Check the latest published builds on the Releases page: https://github.com/hawkticehurst/vscode-flatpak/releases.

After downloading a release asset, install or run it from the directory where it was saved:

```sh
# Stable Flatpak build artifact
flatpak install --user ./vscode-flatpak-stable.flatpak

# Insiders Flatpak build artifact
flatpak install --user ./vscode-flatpak-insider.flatpak

# Stable AppImage build artifact
chmod +x ./vscode-appimage-stable.AppImage
./vscode-appimage-stable.AppImage

# Insiders AppImage build artifact
chmod +x ./vscode-appimage-insiders.AppImage
./vscode-appimage-insiders.AppImage
```

For a GUI-based experience, you can also use [Warehouse](https://flathub.org/en/apps/io.github.flattool.Warehouse) to manage the installation of these apps.

## Usage

Once installed open the application as you would normally via your operating system GUI, or for a CLI-based experience, use these commands:

```sh
# Run Stable
flatpak run com.visualstudio.code

# Run Insiders
flatpak run com.visualstudio.code.insiders
```

### Execute commands on the host system

To run commands on the host system from inside the sandbox:

```sh
host-spawn <COMMAND>
```

Or using the built-in `flatpak-spawn`:

```sh
flatpak-spawn --host <COMMAND>
```

### Use host shell in the integrated terminal

To use your host system's shell in the VS Code integrated terminal, go to **File → Preferences → Settings**, search for `terminal.integrated.profiles.linux`, and click **Edit in settings.json**.

Using `host-spawn` (recommended):

```json
{
  "terminal.integrated.defaultProfile.linux": "bash",
  "terminal.integrated.profiles.linux": {
    "bash": {
      "path": "/app/bin/host-spawn",
      "args": ["bash"],
      "icon": "terminal-bash",
      "overrideName": true
    }
  }
}
```

Using `flatpak-spawn`:

```json
{
  "terminal.integrated.defaultProfile.linux": "bash",
  "terminal.integrated.profiles.linux": {
    "bash": {
      "path": "/usr/bin/flatpak-spawn",
      "args": ["--host", "--env=TERM=xterm-256color", "bash"],
      "icon": "terminal-bash",
      "overrideName": true
    }
  }
}
```

> **Tip:** Replace `bash` with your preferred shell (`zsh`, `fish`, etc.). The `overrideName` option displays the shell name in the terminal tab.

### SDK extensions for language support

This flatpak uses the `org.freedesktop.Sdk` runtime, which includes basic development tools (gcc, python, etc.). For additional language support, install SDK extensions:

```sh
flatpak install flathub org.freedesktop.Sdk.Extension.dotnet
flatpak install flathub org.freedesktop.Sdk.Extension.golang
FLATPAK_ENABLE_SDK_EXT=dotnet,golang flatpak run com.visualstudio.code
```

Tool extensions are also available for shells and other utilities:

```sh
flatpak install com.visualstudio.code.tool.fish
flatpak install com.visualstudio.code.tool.podman

# Insiders channel tool extensions
flatpak install com.visualstudio.code.insiders.tool.fish
flatpak install com.visualstudio.code.insiders.tool.podman
```

Use `flatpak search <TEXT>` to discover more extensions.

To see what's currently available inside the sandbox:

```sh
flatpak run --command=sh com.visualstudio.code
ls /usr/bin   # shared runtime
ls /app/bin   # bundled with VS Code flatpak
```

## Building

The repository uses split CI targets for Stable and Insiders across both Flatpak and AppImage packaging.

Manifests:

- Stable: [flatpak/stable/com.visualstudio.code.yaml](flatpak/stable/com.visualstudio.code.yaml)
- Insiders: [flatpak/insiders/com.visualstudio.code.insiders.yaml](flatpak/insiders/com.visualstudio.code.insiders.yaml)

GitHub Actions workflows:

- Stable workflow: [.github/workflows/flatpak-build-stable.yml](.github/workflows/flatpak-build-stable.yml)
- Insiders workflow: [.github/workflows/flatpak-build-insiders.yml](.github/workflows/flatpak-build-insiders.yml)
- Stable AppImage workflow: [.github/workflows/appimage-build-stable.yml](.github/workflows/appimage-build-stable.yml)
- Insiders AppImage workflow: [.github/workflows/appimage-build-insiders.yml](.github/workflows/appimage-build-insiders.yml)

Each workflow independently resolves the current channel archive URL and only builds when a new upstream archive SHA is detected.

Artifacts produced by CI:

- Stable Flatpak: `vscode-flatpak-stable.flatpak`
- Insiders Flatpak: `vscode-flatpak-insider.flatpak`
- Stable AppImage: `vscode-appimage-stable.AppImage`
- Insiders AppImage: `vscode-appimage-insiders.AppImage`

To build locally:

```sh
# Install flatpak-builder if not already installed
flatpak install flathub org.flatpak.Builder

# Build Stable Flatpak
flatpak-builder --force-clean build-dir flatpak/stable/com.visualstudio.code.yaml

# Build Insiders Flatpak
flatpak-builder --force-clean build-dir flatpak/insiders/com.visualstudio.code.insiders.yaml

# Build Stable AppImage
STABLE_URL=$(curl -sIL -o /dev/null -w '%{url_effective}' https://update.code.visualstudio.com/latest/linux-x64/stable)
bash scripts/build-appimage.sh stable "$STABLE_URL" "local" ./vscode-appimage-stable.AppImage

# Build Insiders AppImage
INSIDERS_URL=$(curl -sIL -o /dev/null -w '%{url_effective}' https://update.code.visualstudio.com/latest/linux-x64/insider)
bash scripts/build-appimage.sh insiders "$INSIDERS_URL" "local" ./vscode-appimage-insiders.AppImage
```

> **Note:** `url: PLACEHOLDER_URL` and `sha256: PLACEHOLDER` in manifests are replaced automatically by CI. For local builds, download the target archive and update both fields manually.
