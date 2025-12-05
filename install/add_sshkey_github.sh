#!/usr/bin/env bash
set -euo pipefail

# --- CONFIG ---
KEY_EMAIL="${1:-$(git config user.email || echo 'you@example.com')}"
KEY_FILE="$HOME/.ssh/id_ed25519"

echo "==> Checking for existing SSH key..."
if [[ -f "${KEY_FILE}" ]]; then
  echo "SSH key already exists at ${KEY_FILE}"
else
  echo "==> Generating new SSH key..."
  ssh-keygen -t ed25519 -C "${KEY_EMAIL}" -f "${KEY_FILE}" -N ""
fi

echo "==> Starting ssh-agent..."
eval "$(ssh-agent -s)"

echo "==> Adding SSH key to agent..."
ssh-add "${KEY_FILE}"

echo "==> Copying SSH public key to clipboard..."
if command -v pbcopy >/dev/null; then
  pbcopy < "${KEY_FILE}.pub"
elif command -v xclip >/dev/null; then
  xclip -sel clip < "${KEY_FILE}.pub"
else
  echo "⚠️  No clipboard tool found. Public key printed below:"
  cat "${KEY_FILE}.pub"
fi

echo "==> Adding SSH key to GitHub via gh..."
if ! command -v gh >/dev/null; then
  echo "❌ GitHub CLI (gh) is not installed. Install via:"
  echo "brew install gh"
  exit 1
fi

# Add key to GitHub account
gh ssh-key add "${KEY_FILE}.pub" --title "My Mac SSH Key $(date '+%Y-%m-%d')"

echo "==> Done!"
echo "Your SSH key is now added to GitHub 🎉"

## Notes
# - chmod +x add_sshkey_github.sh
# ./add_sshkey_github.sh "myemail@example.com"
