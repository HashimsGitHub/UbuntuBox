#!/bin/bash
# test-theme.sh
# Run INSIDE UbuntuBox to instantly preview the colour theme.
# No rebuild needed — just source the bashrc and open a new shell.
#
# Usage: bash /root/test-theme.sh

set -e
BASHRC_SRC="/root/bashrc"
BASHRC_DEST="$HOME/.bashrc"

echo ""
echo "  UbuntuBox - Colour Theme Preview"
echo "  =================================="
echo ""

# ── 1. Copy bashrc ────────────────────────────────────────────────────────────
echo "[1/3] Installing colour theme..."

if [ ! -f "$BASHRC_SRC" ]; then
    echo "  ERROR: $BASHRC_SRC not found."
    echo "  Copy bashrc from the v2.2 folder into %USERPROFILE%\\UbuntuBox\\"
    echo "  (that folder is mounted at /root inside UbuntuBox)"
    exit 1
fi

# Backup existing
if [ -f "$BASHRC_DEST" ]; then
    cp "$BASHRC_DEST" "${BASHRC_DEST}.backup"
    echo "  Backup: ${BASHRC_DEST}.backup"
fi

cp "$BASHRC_SRC" "$BASHRC_DEST"
echo "  OK ~/.bashrc updated"

# ── 2. Install neofetch + chafa if missing ────────────────────────────────────
echo ""
echo "[2/3] Checking neofetch and chafa..."
if ! command -v neofetch &>/dev/null || ! command -v chafa &>/dev/null; then
    apt-get update -qq && apt-get install -y -qq neofetch chafa
fi
echo "  OK ready"

# ── 3. Show colour test ───────────────────────────────────────────────────────
echo ""
echo "[3/3] Colour preview..."
echo ""

python3 - << 'PYEOF'
codes = [
    (87,  "Cyan (brackets)"),
    (83,  "Green (username / executables)"),
    (75,  "Blue (hostname / directories)"),
    (220, "Yellow (path / archives)"),
    (203, "Red (root / errors)"),
    (213, "Magenta (images)"),
    (214, "Orange (Python files)"),
    (240, "Dim grey (log files)"),
]
for code, label in codes:
    bar = f"\033[38;5;{code}m{'█' * 20}\033[0m"
    print(f"  {bar}  \033[38;5;{code}m{label}\033[0m")
print()
PYEOF

echo ""
echo "========================================"
echo "  Prompt preview (start a new shell):"
echo "========================================"
echo ""

# Source and show the prompt
bash --rcfile "$BASHRC_DEST" -c '
echo ""
echo "  Your prompt will look like:"
echo ""
# Print a simulated two-line prompt
printf "\033[38;5;87m┌──[\033[38;5;83mroot\033[38;5;87m@\033[38;5;75mubuntubox\033[38;5;87m]──[\033[38;5;220m~\033[38;5;87m]\033[0m\n"
printf "\033[38;5;87m└──#\033[0m ls -la\n"
echo ""
echo "  (cyan brackets, green user, blue host, yellow path)"
echo ""
ls --color=auto /root
echo ""
echo "  ls colours: cyan=dirs, green=executables, yellow=archives"
echo ""
' 2>/dev/null || true

echo ""
echo "========================================"
echo "  To apply permanently: just run exec bash"
echo "  To revert: cp ~/.bashrc.backup ~/.bashrc && exec bash"
echo "========================================"
echo ""
echo "  Happy? On Windows run: .\\build.ps1"
echo ""
