#!/usr/bin/env bash
set -euo pipefail

echo "==> Detecting CPU..."
ARCH=$(uname -m)
echo "Architecture: $ARCH"

echo "==> Installing Xcode Command Line Tools (if needed)..."
xcode-select -p >/dev/null 2>&1 || xcode-select --install || true

if [[ "$ARCH" == "arm64" ]]; then
  echo "==> Ensuring Rosetta 2 (for x86 tools when needed)..."
  /usr/sbin/softwareupdate --install-rosetta --agree-to-license || true
fi

echo "==> Installing Homebrew (if missing)..."
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.bash_profile"
  eval "$(/opt/homebrew/bin/brew shellenv)" || true
fi

echo "==> Updating Homebrew..."
brew update

echo "==> Done. Close & reopen your terminal (or run: eval \"$(brew shellenv)\")"
