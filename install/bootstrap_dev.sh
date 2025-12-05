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

  # Apple Silicon default path; Intel will be handled by brew itself
  if [[ -d /opt/homebrew/bin ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.bash_profile"
    eval "$(/opt/homebrew/bin/brew shellenv)" || true
  elif [[ -d /usr/local/bin ]]; then
    echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$HOME/.zprofile"
    echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$HOME/.bash_profile"
    eval "$(/usr/local/bin/brew shellenv)" || true
  fi
else
  # Ensure brew env in current shell
  if [[ -d /opt/homebrew/bin ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -d /usr/local/bin ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

echo "==> Updating Homebrew..."
brew update

echo "==> Installing core CLI & utilities..."
brew install \
  git \
  gh \
  jq \
  wget \
  curl \
  tree \
  make \
  cmake \
  openssl \
  readline \
  zlib \
  ripgrep \
  fzf \
  htop \
  tmux \
  neofetch

echo "==> Basic language runtimes (global, you can override later with pyenv/nvm)..."
brew install \
  python \
  node

echo "==> Git sensible defaults..."
git config --global init.defaultBranch main
git config --global pull.rebase false

echo "==> Installing core GUI apps..."
brew install --cask \
  google-chrome \
  visual-studio-code \
  iterm2 \
  rectangle

echo "==> Setup fzf keybindings (CTRL-R, CTRL-T, etc.)..."
"$(brew --prefix)/opt/fzf/install" --all --no-bash --no-fish || true

echo "==> Cleanup..."
brew cleanup

echo "==> Done."
echo "   • Close & reopen your terminal, or run: eval \"\$(brew shellenv)\""
echo "   • Next step (optional): run setup-dataeng-env.sh for full data engineering stack."
