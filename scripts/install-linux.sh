#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Diti Linux Installer & Updater Setup
# ==============================================================================

REPO="Adamskiee/aditime"
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/diti"
BIN_DIR="${HOME}/.local/bin"
DESKTOP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/256x256/apps"
DOCS_DIR="${HOME}/Documents"
DB_PATH="${DOCS_DIR}/diti.db"

# 1. Ensure required base directories exist
mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$DESKTOP_DIR" "$ICON_DIR" "$DOCS_DIR"

echo "=================================================="
echo "          Diti Linux Installer"
echo "=================================================="

# Check if PATH contains ~/.local/bin
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
  echo "Notice: $BIN_DIR is not currently in your PATH."
  echo "Add 'export PATH=\"\$HOME/.local/bin:\$PATH\"' to your ~/.bashrc or ~/.profile."
fi

# Detect existing user data
if [ -f "$DB_PATH" ]; then
  echo "Found existing user database at: $DB_PATH"
  echo "-> This file will NOT be touched during installation or updates."
fi

# 2. Determine target version to install
TARGET_TAG="${1:-}"

resolve_latest_tag() {
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    gh release view --repo "$REPO" --json tagName -q .tagName 2>/dev/null || true
  elif [ -n "${GITHUB_TOKEN:-}" ]; then
    curl -fsSL -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null \
      | grep '"tag_name":' | head -n1 | sed -E 's/.*"tag_name": "([^"]+)".*/\1/' || true
  else
    curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null \
      | grep '"tag_name":' | head -n1 | sed -E 's/.*"tag_name": "([^"]+)".*/\1/' || true
  fi
}

TMP_DIR="$(mktemp -d -t diti-install-XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

BUNDLE_SOURCE=""

if [ "$TARGET_TAG" = "--local" ] || [ "$TARGET_TAG" = "-l" ]; then
  # Local build mode
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  LOCAL_BUNDLE="$REPO_ROOT/build/linux/x64/release/bundle"
  if [ ! -d "$LOCAL_BUNDLE" ]; then
    echo "Building release bundle locally..."
    (cd "$REPO_ROOT" && flutter build linux --release)
  fi
  TARGET_TAG="local-$(date +%Y%m%d%H%M)"
  BUNDLE_SOURCE="$LOCAL_BUNDLE"
  echo "Installing from local bundle: $BUNDLE_SOURCE"
else
  if [ -z "$TARGET_TAG" ]; then
    echo "Checking latest release for $REPO..."
    TARGET_TAG="$(resolve_latest_tag)"
  fi

  if [ -z "$TARGET_TAG" ]; then
    # Fallback to local build if available in current git repository
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
    if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/../build/linux/x64/release/bundle" ]; then
      echo "Could not query GitHub releases, falling back to local build..."
      TARGET_TAG="local-build"
      BUNDLE_SOURCE="$SCRIPT_DIR/../build/linux/x64/release/bundle"
    else
      echo "Error: Could not determine latest release tag."
      echo "If the repository is private, ensure 'gh' is authenticated or GITHUB_TOKEN is set."
      exit 1
    fi
  fi
fi

if [ -z "$BUNDLE_SOURCE" ]; then
  TARBALL_NAME="diti-${TARGET_TAG}-linux-x86_64.tar.gz"
  TARBALL_PATH="$TMP_DIR/$TARBALL_NAME"

  echo "Downloading $TARGET_TAG ($TARBALL_NAME)..."
  DOWNLOAD_SUCCESS=false

  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    if gh release download "$TARGET_TAG" --repo "$REPO" --pattern "*linux-x86_64.tar.gz" --dir "$TMP_DIR"; then
      DOWNLOAD_SUCCESS=true
    fi
  fi

  if [ "$DOWNLOAD_SUCCESS" = false ]; then
    AUTH_HEADER=()
    if [ -n "${GITHUB_TOKEN:-}" ]; then
      AUTH_HEADER=(-H "Authorization: Bearer $GITHUB_TOKEN")
    fi
    DOWNLOAD_URL="https://github.com/$REPO/releases/download/$TARGET_TAG/$TARBALL_NAME"
    if curl -fSL "${AUTH_HEADER[@]}" "$DOWNLOAD_URL" -o "$TARBALL_PATH" 2>/dev/null; then
      DOWNLOAD_SUCCESS=true
    fi
  fi

  if [ "$DOWNLOAD_SUCCESS" = false ]; then
    echo "Error: Failed to download release asset $TARBALL_NAME."
    exit 1
  fi

  echo "Extracting bundle..."
  mkdir -p "$TMP_DIR/extracted"
  tar -xzf "$TARBALL_PATH" -C "$TMP_DIR/extracted" --strip-components=1
  BUNDLE_SOURCE="$TMP_DIR/extracted"
fi

# 3. Install bundle into ~/.local/share/aditime/bundle
echo "Staging application files into $INSTALL_DIR/bundle..."
mkdir -p "$INSTALL_DIR/bundle.new"
cp -r "$BUNDLE_SOURCE"/* "$INSTALL_DIR/bundle.new/"
chmod +x "$INSTALL_DIR/bundle.new/diti" 2>/dev/null || true
(cd "$INSTALL_DIR/bundle.new" && ln -sf diti focus_flow && ln -sf diti aditime) 2>/dev/null || true

# Atomically swap bundle directory
rm -rf "$INSTALL_DIR/bundle.old"
if [ -d "$INSTALL_DIR/bundle" ]; then
  mv "$INSTALL_DIR/bundle" "$INSTALL_DIR/bundle.old"
fi
mv "$INSTALL_DIR/bundle.new" "$INSTALL_DIR/bundle"
rm -rf "$INSTALL_DIR/bundle.old"

echo "$TARGET_TAG" > "$INSTALL_DIR/version"

# 4. Install launcher wrapper at ~/.local/bin/aditime
cat << 'EOF' > "$BIN_DIR/diti"
#!/usr/bin/env bash
if [ "${1:-}" = "--update" ]; then
  exec "$HOME/.local/bin/diti-update" "${@:2}"
fi
exec "$HOME/.local/share/diti/bundle/diti" "$@"
EOF
chmod +x "$BIN_DIR/diti"
ln -sf "$BIN_DIR/diti" "$BIN_DIR/diti"

# 5. Install standalone updater at ~/.local/bin/aditime-update
cat << 'EOF' > "$BIN_DIR/diti-update"
#!/usr/bin/env bash
set -euo pipefail

REPO="Adamskiee/aditime"
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/diti"
DOCS_DIR="${HOME}/Documents"
DB_PATH="${DOCS_DIR}/diti.db"

echo "==> Diti Updater"

CURRENT_VERSION="unknown"
if [ -f "$INSTALL_DIR/version" ]; then
  CURRENT_VERSION="$(cat "$INSTALL_DIR/version" | tr -d '\r\n')"
fi
echo "Current installed version: $CURRENT_VERSION"

# Resolve latest version
LATEST_TAG=""
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  LATEST_TAG="$(gh release view --repo "$REPO" --json tagName -q .tagName 2>/dev/null || true)"
elif [ -n "${GITHUB_TOKEN:-}" ]; then
  LATEST_TAG="$(curl -fsSL -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null \
    | grep '"tag_name":' | head -n1 | sed -E 's/.*"tag_name": "([^"]+)".*/\1/' || true)"
else
  LATEST_TAG="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null \
    | grep '"tag_name":' | head -n1 | sed -E 's/.*"tag_name": "([^"]+)".*/\1/' || true)"
fi

if [ -z "$LATEST_TAG" ]; then
  echo "Error: Could not query latest release from GitHub."
  echo "Please verify internet connection, GitHub CLI authentication (gh auth login), or GITHUB_TOKEN."
  exit 1
fi

echo "Latest available version:  $LATEST_TAG"

FORCE_UPDATE=false
if [ "${1:-}" = "--force" ] || [ "${1:-}" = "-f" ]; then
  FORCE_UPDATE=true
fi

if [ "$CURRENT_VERSION" = "$LATEST_TAG" ] && [ "$FORCE_UPDATE" = false ]; then
  echo "==> Diti is already up to date!"
  exit 0
fi

echo "==> Updating Diti to $LATEST_TAG..."
TMP_DIR="$(mktemp -d -t diti-update-XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

TARBALL_NAME="diti-${LATEST_TAG}-linux-x86_64.tar.gz"
DOWNLOAD_SUCCESS=false

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  if gh release download "$LATEST_TAG" --repo "$REPO" --pattern "*linux-x86_64.tar.gz" --dir "$TMP_DIR"; then
    DOWNLOAD_SUCCESS=true
  fi
fi

if [ "$DOWNLOAD_SUCCESS" = false ]; then
  AUTH_HEADER=()
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    AUTH_HEADER=(-H "Authorization: Bearer $GITHUB_TOKEN")
  fi
  DOWNLOAD_URL="https://github.com/$REPO/releases/download/$LATEST_TAG/$TARBALL_NAME"
  if curl -fSL "${AUTH_HEADER[@]}" "$DOWNLOAD_URL" -o "$TMP_DIR/$TARBALL_NAME" 2>/dev/null; then
    DOWNLOAD_SUCCESS=true
  fi
fi

if [ "$DOWNLOAD_SUCCESS" = false ]; then
  echo "Error: Failed to download $TARBALL_NAME."
  exit 1
fi

echo "==> Unpacking update..."
mkdir -p "$TMP_DIR/extracted"
tar -xzf "$TMP_DIR/$TARBALL_NAME" -C "$TMP_DIR/extracted" --strip-components=1

mkdir -p "$INSTALL_DIR/bundle.new"
cp -r "$TMP_DIR/extracted"/* "$INSTALL_DIR/bundle.new/"
chmod +x "$INSTALL_DIR/bundle.new/diti" 2>/dev/null || true
(cd "$INSTALL_DIR/bundle.new" && ln -sf diti focus_flow && ln -sf diti aditime) 2>/dev/null || true

# Atomic directory replacement
rm -rf "$INSTALL_DIR/bundle.old"
if [ -d "$INSTALL_DIR/bundle" ]; then
  mv "$INSTALL_DIR/bundle" "$INSTALL_DIR/bundle.old"
fi
mv "$INSTALL_DIR/bundle.new" "$INSTALL_DIR/bundle"
rm -rf "$INSTALL_DIR/bundle.old"

echo "$LATEST_TAG" > "$INSTALL_DIR/version"

echo "=================================================="
echo " Diti successfully updated to $LATEST_TAG!"
if [ -f "$DB_PATH" ]; then
  echo " Your data in $DB_PATH remains intact."
fi
echo "=================================================="
EOF
chmod +x "$BIN_DIR/diti-update"
ln -sf "$BIN_DIR/diti-update" "$BIN_DIR/aditime-update" 2>/dev/null || true

# 6. Install application icon
cat << 'EOF' | base64 -d > "$ICON_DIR/diti.png"
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
Fv8ftwWGUksqA+0AAAAASUVORK5CYII=
EOF
cp "$ICON_DIR/diti.png" "$ICON_DIR/aditime.png" 2>/dev/null || true

# 7. Install Desktop Entry
cat << EOF > "$DESKTOP_DIR/diti.desktop"
[Desktop Entry]
Name=Diti
Comment=Cross-platform daily planning and multi-phase routine timer
Exec=$BIN_DIR/diti
Icon=diti
Type=Application
Categories=Utility;Clock;
Terminal=false
StartupWMClass=com.adilabs.diti
EOF
chmod +x "$DESKTOP_DIR/diti.desktop"

# Refresh desktop and icon caches if tools are available
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f -t "${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor" 2>/dev/null || true

echo ""
echo "=================================================="
echo "       Diti installed successfully!"
echo "=================================================="
echo "  Executable:     $BIN_DIR/diti"
echo "  Updater:        $BIN_DIR/diti-update (or: aditime --update)"
echo "  Application:    $INSTALL_DIR/bundle"
echo "  Desktop Entry:  $DESKTOP_DIR/diti.desktop"
echo "  User Database:  $DB_PATH (Untouched across updates)"
echo "=================================================="
echo ""
echo "You can now launch Diti from your Application Menu"
echo "or by running 'diti' in your terminal."
