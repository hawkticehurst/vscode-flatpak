# Visual Studio Code Flatpak

An unofficial Flatpak build of Visual Studio Code, generated from the official Microsoft-built packages.

> **Note:** This is a community-maintained Flatpak. It is not supported by Microsoft.

## Table of Contents

- [Usage](#usage)
  - [Execute commands on the host system](#execute-commands-on-the-host-system)
  - [Use host shell in the integrated terminal](#use-host-shell-in-the-integrated-terminal)
  - [SDK extensions for language support](#sdk-extensions-for-language-support)
- [Building](#building)

## Usage

Most functionality works out of the box. However, because Flatpak runs in a sandboxed environment, some features require additional setup.

### Execute commands on the host system

To run commands on the host system from inside the sandbox:

```sh
$ host-spawn <COMMAND>
```

Or using the built-in `flatpak-spawn`:

```sh
$ flatpak-spawn --host <COMMAND>
```

Most users report a better experience with `host-spawn`.

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

This Flatpak uses the `org.freedesktop.Sdk` runtime, which includes basic development tools (gcc, python, etc.). For additional language support, install SDK extensions:

```sh
$ flatpak install flathub org.freedesktop.Sdk.Extension.dotnet
$ flatpak install flathub org.freedesktop.Sdk.Extension.golang
$ FLATPAK_ENABLE_SDK_EXT=dotnet,golang flatpak run com.visualstudio.code
```

Tool extensions are also available for shells and other utilities:

```sh
$ flatpak install com.visualstudio.code.tool.fish
$ flatpak install com.visualstudio.code.tool.podman
```

Use `flatpak search <TEXT>` to discover more extensions.

To see what's currently available inside the sandbox:

```sh
$ flatpak run --command=sh com.visualstudio.code
$ ls /usr/bin   # shared runtime
$ ls /app/bin   # bundled with this flatpak
```

## Building

The Flatpak is built using split CI targets for Stable and Insiders.

Manifests:

- Stable: [com.visualstudio.code.yaml](com.visualstudio.code.yaml)
- Insiders: [com.visualstudio.code.insiders.yaml](com.visualstudio.code.insiders.yaml)

GitHub Actions workflows:

- Stable workflow: [.github/workflows/flatpak-build.yml](.github/workflows/flatpak-build.yml)
- Insiders workflow: [.github/workflows/flatpak-build-insiders.yml](.github/workflows/flatpak-build-insiders.yml)

Each workflow independently resolves the current channel archive URL and patches the corresponding manifest checksum before building.

To build locally:

```sh
# Install flatpak-builder if not already installed
$ flatpak install flathub org.flatpak.Builder

# Build
$ flatpak-builder --force-clean build-dir com.visualstudio.code.yaml

# Build Insiders
$ flatpak-builder --force-clean build-dir com.visualstudio.code.insiders.yaml
```

> **Note:** The `sha256: PLACEHOLDER` in the manifest is replaced automatically by CI. For local builds, you may need to download the archive manually and update the checksum.
