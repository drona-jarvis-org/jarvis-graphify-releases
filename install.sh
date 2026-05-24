#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# jarvis-graphify installer — macOS & Linux
#
# One-liner install:
#   curl -fsSL https://raw.githubusercontent.com/dronaprod/jarvis-graphify/main/install.sh | bash
# ─────────────────────────────────────────────────────────────────────────────
set -e

TOOL="jarvis-graphify"
REPO="dronaprod/jarvis-graphify"
RELEASE_BASE="https://github.com/${REPO}/releases/latest/download"
INSTALL_DIR="$HOME/.local/bin"
GLOBAL_DIR="/usr/local/bin"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[jarvis-graphify]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warning]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*"; exit 1; }

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║      jarvis-graphify installer       ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# ── Detect platform & pick binary ─────────────────────────────────────────
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Darwin)
        case "$ARCH" in
            arm64)  BINARY="jarvis-graphify-macos-arm64" ;;
            x86_64) BINARY="jarvis-graphify-macos-x86_64" ;;
            *)      error "Unsupported macOS architecture: $ARCH" ;;
        esac ;;
    Linux)
        case "$ARCH" in
            x86_64)  BINARY="jarvis-graphify-linux-x86_64" ;;
            aarch64) BINARY="jarvis-graphify-linux-arm64" ;;
            *)       error "Unsupported Linux architecture: $ARCH" ;;
        esac ;;
    *)
        error "Unsupported OS: $OS. On Windows use install.ps1" ;;
esac

info "Detected: $OS / $ARCH → $BINARY"

# ── Download ──────────────────────────────────────────────────────────────
TMP_BIN=$(mktemp /tmp/jarvis-graphify-XXXXXX)
URL="${RELEASE_BASE}/${BINARY}"

info "Downloading from GitHub Releases…"
if command -v curl &>/dev/null; then
    curl -fsSL "$URL" -o "$TMP_BIN" \
      || error "Download failed.\nURL: $URL\nCheck your internet connection or visit https://github.com/${REPO}/releases"
elif command -v wget &>/dev/null; then
    wget -q "$URL" -O "$TMP_BIN" \
      || error "Download failed. Visit https://github.com/${REPO}/releases"
else
    error "Neither curl nor wget found. Install one and try again."
fi

chmod +x "$TMP_BIN"

# ── Install ───────────────────────────────────────────────────────────────
if [ "$EUID" -eq 0 ]; then
    # Running as root — install globally
    install -m 755 "$TMP_BIN" "$GLOBAL_DIR/$TOOL"
    rm -f "$TMP_BIN"
    info "✓ Installed to $GLOBAL_DIR/$TOOL (available to all users)"
else
    # User install — no sudo needed
    mkdir -p "$INSTALL_DIR"
    install -m 755 "$TMP_BIN" "$INSTALL_DIR/$TOOL"
    rm -f "$TMP_BIN"
    info "✓ Installed to $INSTALL_DIR/$TOOL"

    # Add ~/.local/bin to PATH in shell rc files if missing
    for RC in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile"; do
        if [ -f "$RC" ] && ! grep -q '\.local/bin' "$RC"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$RC"
            info "Added ~/.local/bin to PATH in $RC"
        fi
    done
    warn "Restart your terminal (or run: source ~/.zshrc) to use jarvis-graphify."
fi

# ── Verify ────────────────────────────────────────────────────────────────
BIN="${EUID:-1}-0" # placeholder; the actual binary location
if [ "$EUID" -eq 0 ]; then
    VER=$("$GLOBAL_DIR/$TOOL" --version 2>&1 || true)
else
    VER=$("$INSTALL_DIR/$TOOL" --version 2>&1 || true)
fi

echo ""
info "Installed: $VER"
echo ""
echo "  Next steps:"
echo "    1. Restart your terminal  (or: source ~/.zshrc)"
echo "    2. Go to your project:    cd /path/to/your-project"
echo "    3. Create config:         $TOOL setup"
echo "    4. Edit the config:       open jarvis-graphify-in/settings.json"
echo "    5. Run:                   $TOOL ."
echo "    6. Open graph:            open jarvis-graphify-out/graph.html"
echo ""
echo "  Docs: https://github.com/${REPO}#readme"
echo ""
