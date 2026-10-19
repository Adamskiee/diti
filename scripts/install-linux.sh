#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Aditime Linux Installer & Updater Setup
# ==============================================================================

REPO="Adamskiee/aditime"
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/aditime"
BIN_DIR="${HOME}/.local/bin"
DESKTOP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/256x256/apps"
DOCS_DIR="${HOME}/Documents"
DB_PATH="${DOCS_DIR}/focus_flow.db"

# 1. Ensure required base directories exist
mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$DESKTOP_DIR" "$ICON_DIR" "$DOCS_DIR"

echo "=================================================="
echo "          Aditime Linux Installer"
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

TMP_DIR="$(mktemp -d -t aditime-install-XXXXXX)"
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
  TARBALL_NAME="aditime-${TARGET_TAG}-linux-x86_64.tar.gz"
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
chmod +x "$INSTALL_DIR/bundle.new/focus_flow" 2>/dev/null || true
if [ -L "$INSTALL_DIR/bundle.new/aditime" ] || [ -f "$INSTALL_DIR/bundle.new/aditime" ]; then
  chmod +x "$INSTALL_DIR/bundle.new/aditime" 2>/dev/null || true
else
  (cd "$INSTALL_DIR/bundle.new" && ln -sf focus_flow aditime)
fi

# Atomically swap bundle directory
rm -rf "$INSTALL_DIR/bundle.old"
if [ -d "$INSTALL_DIR/bundle" ]; then
  mv "$INSTALL_DIR/bundle" "$INSTALL_DIR/bundle.old"
fi
mv "$INSTALL_DIR/bundle.new" "$INSTALL_DIR/bundle"
rm -rf "$INSTALL_DIR/bundle.old"

echo "$TARGET_TAG" > "$INSTALL_DIR/version"

# 4. Install launcher wrapper at ~/.local/bin/aditime
cat << 'EOF' > "$BIN_DIR/aditime"
#!/usr/bin/env bash
if [ "${1:-}" = "--update" ]; then
  exec "$HOME/.local/bin/aditime-update" "${@:2}"
fi
exec "$HOME/.local/share/aditime/bundle/aditime" "$@"
EOF
chmod +x "$BIN_DIR/aditime"

# 5. Install standalone updater at ~/.local/bin/aditime-update
cat << 'EOF' > "$BIN_DIR/aditime-update"
#!/usr/bin/env bash
set -euo pipefail

REPO="Adamskiee/aditime"
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/aditime"
DOCS_DIR="${HOME}/Documents"
DB_PATH="${DOCS_DIR}/focus_flow.db"

echo "==> Aditime Updater"

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
  echo "==> Aditime is already up to date!"
  exit 0
fi

echo "==> Updating Aditime to $LATEST_TAG..."
TMP_DIR="$(mktemp -d -t aditime-update-XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

TARBALL_NAME="aditime-${LATEST_TAG}-linux-x86_64.tar.gz"
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
chmod +x "$INSTALL_DIR/bundle.new/focus_flow" 2>/dev/null || true
if [ -L "$INSTALL_DIR/bundle.new/aditime" ] || [ -f "$INSTALL_DIR/bundle.new/aditime" ]; then
  chmod +x "$INSTALL_DIR/bundle.new/aditime" 2>/dev/null || true
else
  (cd "$INSTALL_DIR/bundle.new" && ln -sf focus_flow aditime)
fi

# Atomic directory replacement
rm -rf "$INSTALL_DIR/bundle.old"
if [ -d "$INSTALL_DIR/bundle" ]; then
  mv "$INSTALL_DIR/bundle" "$INSTALL_DIR/bundle.old"
fi
mv "$INSTALL_DIR/bundle.new" "$INSTALL_DIR/bundle"
rm -rf "$INSTALL_DIR/bundle.old"

echo "$LATEST_TAG" > "$INSTALL_DIR/version"

echo "=================================================="
echo " Aditime successfully updated to $LATEST_TAG!"
if [ -f "$DB_PATH" ]; then
  echo " Your data in $DB_PATH remains intact."
fi
echo "=================================================="
EOF
chmod +x "$BIN_DIR/aditime-update"

# 6. Install application icon
cat << 'EOF' | base64 -d > "$ICON_DIR/aditime.png"
iVBORw0KGgoAAAANSUhEUgAAAMAAAADACAMAAABlApw1AAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAdpQTFRFAAAAVMX4VMX4AUN3AVGRAVaaAVebKbb2VMX4FmOXVMX4VMX4Kbb2AUuGAUuHAVWXAVebFmyWKbb2LLf2VMX4AClIACxOACxPAC1QAC5RAC5SAC9TAC9UADBWADFWADFXADNaADVeADZgADdgADtpADxsASZCASZDASpJATFXATRbATRcATRdATVfATZgAThjAThkATlmATpnATpoATtpATxqAT1sAT1tAT5tAT5uAT5vAT9vAT9wAUByAUFzAUF0AUJ1AUJ2AUR5AUR6AUV6AUV7AUZ8AUd+AUd/AUiAAUiBAUmCAUmDAUqDAUqEAUqFAUuEAUuFAUuGAUuHAUyHAUyIAUyJAU2IAU2JAU2KAU6KAU6LAU6MAU+MAU+NAVCOAVCPAVCQAVGPAVGQAVGRAVKRAVKSAVOSAVOTAVOUAVOVAVSUAVSVAVSWAVWWAVWXAVWYAVWZAVaYAVaZAVaaAVeaAVebAi5PAjFWAjRbAjdgAjpkAjxoAj5rAkBuAkFxAkJzAkN1AkR2AkV4AkZ5AkZ6Akd6FmiPFmmQF22WF3CbGHOfGXajGXmnGXuqGn2tGn+wGoCyG4K0G4O2G4S3G4W4G4W5G4a6HIa7H4vAKbb2LLf2TML4VMX4KQGaCAAAABV0Uk5TABAgMDAwMDAwQEDP3+/v7+/v7+/v7Yl3rQAAAz5JREFUeNrt1AdTE1EUhmFEQKygYi9YsTewYcOAEBBRg6KIkASBmKhhkazXLnbsvUb8r2bNMASy2b33zmzmnJnv+wF7nnd2dgsKMAzL60or/uqtohR++OGHH3744Ycffvjhhx9++OGHH3744Ycffvjhhx9++OGHH3744Ycffvjhhx9++OGHH3744Ycffvjhhx9++OGHH3744Ycffvjhhx9++Gn7C2dprpCGX/uhs6fBDz/88HPxa9+i4te9Rsevd4+SX+ciLb/6TWp+1av0/Gp3KfpVLtP0y9+m6pe9Ttcvd5+yX0ZA2+9uoO53U9D3Ozuc/DMWjpHwOxU4+hck/4yR8OcucPEntQo88OcqcPXrFHjity+Q8KsXuOS3K5DyqxZ45s8ukPSrFXjon1og7Vcp8NQ/uUDBL1/gsT+zQMkvW+C5f6JA0S9XkAf/eIGyX6YgL/50gYbfvSBPfqtAy+9WkDd/qkDP71yQR7/THP1OBTz8uQu4+HMV8PHbF3Dy2xXw8mcXcPNPLeDnn1zA0Z9ZwNM/UcDVP17A158u4Oy3Coj4C+Yk9fZ7Jg2/7hv49XJuEeeCny/a+8qK+RZY/kGzvIRrwY/n7b3xhBBcC74/O5vy3xJcC749bQvFb5pWAMuCr09ag9eHzHQAw4Ivj1u6o0YiFcCz4POIv6s/PjwRwKzg06OmjiuxwcwAVgUfH9YHgpGYYWQGMCr48MDX2hWOxuLGsDn+FXMqeH//qP9cT+/VrAAmBe/uHWw4dSHYF8kOYFHw9u5eX/OZzmA4ErthTPqKeRS8ubPrSENLoLMnPGAXQL7g9e3t++oaTwY6u8MDUbsA4gWvNm/ZXetrbDl9sTvUH72W/o8KwaZgdNOSbdWHrICOy6E+6z9qiuzRLRitWrRyR83h4yea285bAUZC2I5qQcq/ePXOmtq6Bn8qIDIkco5mgeVfVrmu+sCxen9X1BROo1jw37+8cu2e/c2hhHAbvYK0f8WqDW1DQmbUCtL+9U0RITtaBZZ/jU9eT61gtGrpxkumUBydgvlbG/sNZT+hgunztPyECorKtPyECorLBfOCEhSgAAUoQAEKUIACFKAABShAAZkCDKO1f/OiyBBYvwCtAAAAAElFTkSuQmCC
EOF

# 7. Install Desktop Entry
cat << EOF > "$DESKTOP_DIR/aditime.desktop"
[Desktop Entry]
Name=Aditime
Comment=Cross-platform daily planning and multi-phase routine timer
Exec=$BIN_DIR/aditime
Icon=aditime
Type=Application
Categories=Utility;Clock;
Terminal=false
StartupWMClass=focus_flow
EOF
chmod +x "$DESKTOP_DIR/aditime.desktop"

# Refresh desktop and icon caches if tools are available
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f -t "${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor" 2>/dev/null || true

echo ""
echo "=================================================="
echo "       Aditime installed successfully!"
echo "=================================================="
echo "  Executable:     $BIN_DIR/aditime"
echo "  Updater:        $BIN_DIR/aditime-update (or: aditime --update)"
echo "  Application:    $INSTALL_DIR/bundle"
echo "  Desktop Entry:  $DESKTOP_DIR/aditime.desktop"
echo "  User Database:  $DB_PATH (Untouched across updates)"
echo "=================================================="
echo ""
echo "You can now launch Aditime from your Application Menu"
echo "or by running 'aditime' in your terminal."
