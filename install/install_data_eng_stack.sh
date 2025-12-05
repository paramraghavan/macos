#!/usr/bin/env bash
set -euo pipefail

echo "==> Loading Homebrew environment..."
if [[ -d /opt/homebrew/bin ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -d /usr/local/bin ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
else
  echo "Homebrew not found. Run bootstrap-mac-dev.sh first."
  exit 1
fi

echo "==> Core CLI (if somehow missing)..."
brew install git gh jq wget curl tree make cmake openssl readline zlib

echo "==> Install pyenv + pyenv-virtualenv..."
brew install pyenv pyenv-virtualenv

# Add pyenv to zsh
if ! grep -q 'pyenv init' "$HOME/.zshrc" 2>/dev/null; then
  {
    echo ''
    echo '# pyenv setup'
    echo 'export PYENV_ROOT="$HOME/.pyenv"'
    echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"'
    echo 'eval "$(pyenv init -)"'
    echo 'eval "$(pyenv virtualenv-init -)"'
  } >> "$HOME/.zshrc"
fi

# Add pyenv to bash
if ! grep -q 'pyenv init' "$HOME/.bash_profile" 2>/dev/null; then
  {
    echo ''
    echo '# pyenv setup'
    echo 'export PYENV_ROOT="$HOME/.pyenv"'
    echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"'
    echo 'eval "$(pyenv init -)"'
    echo 'eval "$(pyenv virtualenv-init -)"'
  } >> "$HOME/.bash_profile"
fi

echo "==> Activating pyenv in current shell..."
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

PYVER=3.11.9
ENV_NAME=dataeng

echo "==> Installing Python $PYVER via pyenv (if needed)..."
pyenv install -s "$PYVER"

echo "==> Creating/overwriting virtualenv '$ENV_NAME'..."
pyenv virtualenv -f "$PYVER" "$ENV_NAME"
pyenv global "$ENV_NAME"

echo "==> Upgrading pip basics..."
pip install --upgrade pip wheel setuptools

echo "==> Installing core Python data/DE packages..."
pip install \
  pandas \
  pyarrow \
  numpy \
  scipy \
  matplotlib \
  jupyterlab \
  ipykernel \
  black \
  ruff \
  "pyspark==3.5.1" \
  requests \
  tqdm \
  rich

echo "==> Cloud & DB connectors..."
pip install \
  boto3 \
  awscli \
  snowflake-connector-python \
  snowflake-snowpark-python \
  sqlalchemy \
  psycopg2-binary \
  google-cloud-storage \
  azure-storage-blob

echo "==> Installing JDK 17 for Spark..."
brew install openjdk@17

echo "==> Linking JDK into system JavaVirtualMachines (may require sudo)..."
sudo ln -sf /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk \
  /Library/Java/JavaVirtualMachines/openjdk-17.jdk 2>/dev/null || true

if ! grep -q 'JAVA_HOME' "$HOME/.zshrc" 2>/dev/null; then
  {
    echo 'export JAVA_HOME=$(/usr/libexec/java_home -v 17)'
    echo 'export PATH="$JAVA_HOME/bin:$PATH"'
  } >> "$HOME/.zshrc"
fi

if ! grep -q 'JAVA_HOME' "$HOME/.bash_profile" 2>/dev/null; then
  {
    echo 'export JAVA_HOME=$(/usr/libexec/java_home -v 17)'
    echo 'export PATH="$JAVA_HOME/bin:$PATH"'
  } >> "$HOME/.bash_profile"
fi

echo "==> Installing Apache Spark (local dev)..."
brew install apache-spark

echo "==> Docker Desktop (for local services)..."
brew install --cask docker

echo "==> Terminals & IDEs (DE-focused)..."
brew install --cask iterm2
brew install --cask pycharm-ce
# Uncomment if you want VS Code here too:
# brew install --cask visual-studio-code

echo "==> Cloud CLIs..."
brew install awscli
brew install azure-cli
brew install --cask google-cloud-sdk

echo "==> Snowflake CLI (SnowSQL)..."
brew install --cask snowflake-snowsql || true  # ignore if cask name changes

echo "==> Other helpful DE tools..."
brew install terraform kubectl k9s httpie yq

echo "==> Registering Jupyter kernel for this env..."
python -m ipykernel install --user --name "$ENV_NAME" --display-name "Python ($ENV_NAME)"

echo "==> Done: data engineering environment ready."
echo "   • Restart terminal or: source ~/.zshrc"
echo "   • Jupyter kernel: Python ($ENV_NAME)"
echo "   • PyCharm can use pyenv interpreter: $ENV_NAME"
