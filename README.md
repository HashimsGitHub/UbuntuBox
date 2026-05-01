# UbuntuBox

<p align="center">
  <img src="icon.ico" width="80" alt="UbuntuBox Logo"/>
</p>

<p align="center">
  <strong>Run a full Ubuntu Linux bash terminal on Windows — one click, no dual boot, no VM setup.</strong>
</p>

<p align="center">
  <a href="https://github.com/HashimsGitHub/UbuntuBox/releases/latest">
    <img src="https://img.shields.io/github/v/release/HashimsGitHub/UbuntuBox?label=Download&style=for-the-badge&color=E95420" alt="Download"/>
  </a>
  <img src="https://img.shields.io/badge/Windows-10%2F11-0078D4?style=for-the-badge&logo=windows" alt="Windows"/>
  <img src="https://img.shields.io/badge/Ubuntu-24.04-E95420?style=for-the-badge&logo=ubuntu" alt="Ubuntu"/>
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License"/>
</p>

---

## What is UbuntuBox?

UbuntuBox is a one-click Windows installer that gives you a full Ubuntu Linux terminal powered by Podman containers. No WSL configuration, no virtual machine setup, no Docker Desktop — just double-click and get a bash shell with your favourite Linux tools ready to go.

It also integrates directly into **VS Code** as a terminal profile called `UbuntuBox (WSL)`.

---

## Features

- **One-click install** — Podman installed and configured automatically
- **Full Ubuntu 24.04** bash environment
- **Pre-installed tools** — git, curl, wget, python3, vim, nano, htop, jq, and more
- **Persistent home folder** — files saved at `C:\Users\<you>\UbuntuBox\` survive container restarts
- **VS Code integration** — appears as `UbuntuBox (WSL)` in the terminal dropdown
- **Shared files** — desktop app and VS Code terminal share the same home folder
- **Clean uninstall** — removes everything including VS Code profile

---

## Requirements

| Requirement | Details |
|-------------|---------|
| OS | Windows 10 (Build 19041+) or Windows 11 |
| Virtualisation | Must be enabled in BIOS (Intel VT-x / AMD-V) |
| Disk space | ~1.5 GB |
| Privileges | Admin rights during install only |

---

## Installation

### Step 1 — Download
Go to the [Releases page](https://github.com/HashimsGitHub/UbuntuBox/releases/latest) and download `UbuntuBoxSetup.exe`.

### Step 2 — Run the installer
Double-click `UbuntuBoxSetup.exe`. When Windows shows:
```
Unknown publisher wants to make changes to your device
```
Click **Yes** — this is expected for a self-signed certificate.

### Step 3 — Follow the installer
The installer will automatically:
- Enable WSL2 and Virtual Machine Platform (may require a restart)
- Install Podman
- Load the Ubuntu container image
- Create a desktop shortcut

### Step 4 — Launch
Double-click **UbuntuBox** on your desktop. A terminal opens with a full Ubuntu bash shell.

> **Note:** If WSL2 features were not previously enabled, Windows will prompt for a restart after install. Simply reboot and run the installer again — it will complete in seconds the second time.

---

## VS Code Integration

During install, tick **"Add UbuntuBox as VS Code terminal profile"**. After install:

1. Open VS Code
2. Click the dropdown arrow next to `+` in the terminal panel
3. Select **UbuntuBox (WSL)**

You get a full Linux bash terminal inline in VS Code. Files are shared with the desktop app — anything you create in one appears in the other.

To add the VS Code profile after install, go to:
```
Start Menu -> UbuntuBox -> Add UbuntuBox to VS Code Terminal
```

---

## Pre-installed Linux Tools

```
bash          curl          wget          git
vim           nano          python3       pip3
net-tools     htop          jq            tree
unzip         zip           openssh-client build-essential
sudo          less          man
```

---

## Persistent Storage

Your files are stored at:
```
C:\Users\<username>\UbuntuBox\
```
This folder is mounted as `/root` inside the container. Files survive container restarts and are shared between the desktop app and VS Code terminal.

---

## Building from Source

### Requirements
- [Podman for Windows](https://github.com/containers/podman/releases/latest)
- [Inno Setup 6](https://jrsoftware.org/isdl.php)
- [Windows SDK](https://developer.microsoft.com/windows/downloads/windows-sdk/) (for code signing)

### Steps

```powershell
# Clone the repo
git clone https://github.com/HashimsGitHub/UbuntuBox.git
cd UbuntuBox

# Download Podman installer and rename it
# From: https://github.com/containers/podman/releases/latest
# Rename to: podman-installer.exe

# Optional: place UbuntuBox.pfx in folder for code signing

# Build everything
.\build.ps1
```

Output: `Output\UbuntuBoxSetup.exe`

---

## How It Works

```
UbuntuBoxSetup.exe
      |
      +-- Installs Podman (container runtime)
      +-- Initialises Podman machine (WSL2-backed Linux VM)
      +-- Loads ubuntu-box container image
      +-- Creates desktop shortcut + VS Code profile

Double-click UbuntuBox
      |
      +-- Starts Podman machine (if not running)
      +-- Cleans up any stale session
      +-- Mounts C:\Users\<you>\UbuntuBox -> /root
      +-- Opens Ubuntu bash terminal
```

---

## Uninstalling

Go to **Settings -> Apps -> UbuntuBox -> Uninstall**.

The uninstaller will:
- Remove the Podman container image
- Remove the VS Code terminal profile
- Delete all installed files

Podman itself remains installed — uninstall it separately from Apps if desired.

---

## Troubleshooting

**SmartScreen warning on install**
Click **More info** then **Run anyway**. This appears because the certificate is self-signed.

**"Cannot connect to Podman" error**
Run in PowerShell:
```powershell
podman machine start
```

**Container name already in use**
Run in PowerShell:
```powershell
podman rm -f ubuntu-box-session
```
Then relaunch UbuntuBox.

**Blank terminal in VS Code**
Run the Start Menu shortcut **Add UbuntuBox to VS Code Terminal** and restart VS Code.

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

## Author

**Hashim Hilal**

---

<p align="center">
  Made with love for developers who want Linux tools without leaving Windows.
</p>
