#!/usr/bin/env bash
set -euo pipefail

# Re-load brew in current shell (covers both Intel & Apple Silicon)
if [[ -d /opt/homebrew/bin ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -d /usr/local/bin ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

echo "==> Bulk install core CLI & utilities"
brew install git gh jq wget curl tree make cmake openssl readline zlib

echo "==> Git quick setup (edit if you want)"
git config --global init.defaultBranch main
git config --global pull.rebase false

echo "==> Install Python toolchain via pyenv (clean isolation)"
brew install pyenv pyenv-virtualenv
# Add pyenv to shells
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
# activate in current shell
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Choose a stable Python (adjust if you prefer another)
PYVER=3.11.9
echo "==> Installing Python $PYVER via pyenv"
pyenv install -s "$PYVER"
pyenv virtualenv -f "$PYVER" dataeng
pyenv global dataeng

echo "==> PIP basics"
pip install --upgrade pip wheel setuptools

echo "==> Popular Python data/DE packages"
pip install pandas pyarrow numpy scipy matplotlib jupyterlab ipykernel black ruff \
            pyspark==3.5.1 \
            requests tqdm rich
# Cloud & DB connectors (pick what you use)
pip install boto3 awscli \
            snowflake-connector-python snowflake-snowpark-python \
            sqlalchemy psycopg2-binary \
            google-cloud-storage azure-storage-blob

echo "==> Install JDK + Spark (for local dev/testing)"
brew install openjdk@17
# link JDK (Ventura sometimes needs explicit JAVA_HOME)
sudo ln -sf /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk 2>/dev/null || true
if ! grep -q 'JAVA_HOME' "$HOME/.zshrc" 2>/dev/null; then
  echo 'export JAVA_HOME=$(/usr/libexec/java_home -v 17)' >> "$HOME/.zshrc"
  echo 'export PATH="$JAVA_HOME/bin:$PATH"' >> "$HOME/.zshrc"
fi
if ! grep -q 'JAVA_HOME' "$HOME/.bash_profile" 2>/dev/null; then
  echo 'export JAVA_HOME=$(/usr/libexec/java_home -v 17)' >> "$HOME/.bash_profile"
  echo 'export PATH="$JAVA_HOME/bin:$PATH"' >> "$HOME/.bash_profile"
fi

brew install apache-spark  # local Spark shell & submit
# Scala/SBT optional (uncomment if you want the Scala side)
# brew install scala sbt

echo "==> Docker Desktop (for local services)"
brew install --cask docker

echo "==> Terminals & IDEs"
brew install --cask iterm2
brew install --cask pycharm-ce   # Community; use 'pycharm' for Professional
# VS Code optional:
# brew install --cask visual-studio-code

echo "==> Cloud CLIs"
brew install awscli
brew install --cask google-cloud-sdk
brew install azure-cli

echo "==> Snowflake CLI (SnowSQL)"
brew install --cask snowflake-snowsql || true  # falls back silently if cask changes

echo "==> Other helpful tools"
brew install terraform kubectl k9s httpie yq

echo "==> Create a ready-to-run Jupyter kernel for this env"
python -m ipykernel install --user --name dataeng --display-name "Python (dataeng)"

echo "==> Final notes"
echo "• Close & reopen terminal to load PATH changes (or: source ~/.zshrc)"
echo "• Launch PyCharm from Applications or: open -a 'PyCharm CE'"
echo "• Start Docker Desktop from Applications before using containers"
echo "• Your Python env is 'dataeng' (pyenv); pip installs went there"
