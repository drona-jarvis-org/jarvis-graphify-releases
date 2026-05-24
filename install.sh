#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# jarvis-graphify installer — macOS & Linux
#
# One-liner (downloads wheel from GitHub Releases):
#   curl -fsSL https://raw.githubusercontent.com/dronaprod/jarvis_graphify/main/release/install.sh | bash
#
# From a cloned / unzipped release folder (uses local dist/ wheel):
#   bash install.sh            # user install — no sudo needed
#   sudo bash install.sh       # system-wide
# ─────────────────────────────────────────────────────────────────────────────
set -e

TOOL="jarvis-graphify"
VERSION="1.1.0"
VENV_DIR="$HOME/.jarvis-graphify/venv"
GLOBAL_BIN="/usr/local/bin/$TOOL"
USER_BIN="$HOME/.local/bin/$TOOL"
GITHUB_RELEASE_URL="https://github.com/dronaprod/jarvis_graphify/releases/download/v${VERSION}/jarvis_graphify-${VERSION}-py3-none-any.whl"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[jarvis-graphify]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warning]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*"; exit 1; }

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║      jarvis-graphify installer       ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# ── Detect Python ─────────────────────────────────────────────────────────
PYTHON=""
for cmd in python3.12 python3.11 python3.10 python3.9 python3 python; do
    if command -v "$cmd" &>/dev/null; then
        ver=$("$cmd" -c "import sys; print(sys.version_info >= (3,9))" 2>/dev/null)
        if [ "$ver" = "True" ]; then
            PYTHON="$cmd"
            break
        fi
    fi
done
[ -z "$PYTHON" ] && error "Python 3.9+ not found. Install from https://python.org"
PY_VER=$($PYTHON --version)
info "Using $PY_VER"

# ── Create virtual environment ────────────────────────────────────────────
info "Creating virtual environment at $VENV_DIR …"
mkdir -p "$(dirname "$VENV_DIR")"
$PYTHON -m venv "$VENV_DIR"
VENV_PIP="$VENV_DIR/bin/pip"

# ── Locate or download wheel ──────────────────────────────────────────────
WHEEL=""
TMP_WHL=""

# 1. Try local dist/ (when run from a cloned / unzipped release folder)
if [ -n "${BASH_SOURCE[0]:-}" ] && [ "${BASH_SOURCE[0]}" != "bash" ] && [ "${BASH_SOURCE[0]}" != "-bash" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    WHEEL=$(ls "$SCRIPT_DIR/dist/"*.whl 2>/dev/null | head -1)
fi

# 2. Download from GitHub Releases (curl-piped one-liner install)
if [ -z "$WHEEL" ]; then
    info "Downloading jarvis-graphify v${VERSION} from GitHub Releases…"
    TMP_WHL=$(mktemp /tmp/jarvis_graphify_XXXXXX.whl)
    if command -v curl &>/dev/null; then
        curl -fsSL "$GITHUB_RELEASE_URL" -o "$TMP_WHL" \
          || error "Download failed. Check your internet connection or visit https://github.com/dronaprod/jarvis_graphify/releases"
    elif command -v wget &>/dev/null; then
        wget -q "$GITHUB_RELEASE_URL" -O "$TMP_WHL" \
          || error "Download failed. Neither curl nor wget succeeded."
    else
        error "Neither curl nor wget found. Install one and try again."
    fi
    WHEEL="$TMP_WHL"
fi

info "Installing from $(basename "$WHEEL") …"
"$VENV_PIP" install --upgrade pip --quiet
"$VENV_PIP" install --force-reinstall "$WHEEL" --quiet \
  || error "pip install failed. The wheel may be corrupted — try again."

# Clean up temp file if we downloaded it
[ -n "$TMP_WHL" ] && rm -f "$TMP_WHL"

VENV_BIN="$VENV_DIR/bin/$TOOL"
[ -f "$VENV_BIN" ] || error "Install failed — binary not found at $VENV_BIN"

# ── Link binary ───────────────────────────────────────────────────────────
if [ "$EUID" -eq 0 ]; then
    info "Linking to $GLOBAL_BIN (system-wide) …"
    ln -sf "$VENV_BIN" "$GLOBAL_BIN"
    info "✓ Installed globally — available to all users"
else
    info "Linking to $USER_BIN (user mode, no sudo required) …"
    mkdir -p "$HOME/.local/bin"
    ln -sf "$VENV_BIN" "$USER_BIN"

    # Add ~/.local/bin to PATH in shell rc files if missing
    for RC in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile"; do
        if [ -f "$RC" ] && ! grep -q '\.local/bin' "$RC"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$RC"
            info "Added ~/.local/bin to PATH in $RC"
        fi
    done
    warn "If '$TOOL' is not found after install, run:  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# ── Done ──────────────────────────────────────────────────────────────────
INSTALLED_VER=$("$VENV_BIN" --version 2>&1 || true)
echo ""
info "Installed: $INSTALLED_VER"
echo ""
echo "  Next steps:"
echo "    1. Restart your terminal (or run: source ~/.zshrc)"
echo "    2. Go to your project:     cd /path/to/your-project"
echo "    3. Create config:          $TOOL setup"
echo "    4. Edit the config:        open jarvis-graphify-in/settings.json"
echo "    5. Run the scan:           $TOOL ."
echo "    6. Open the graph:         open jarvis-graphify-out/graph.html"
echo ""
echo "  Docs & source:  https://github.com/dronaprod/jarvis_graphify"
echo ""
