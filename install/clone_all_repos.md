`Gotcha — here’s a reusable **`clone-all-github-repos.sh`** that:

* Uses your **PAT** (from env or `~/.github_pat`)
* Can clone **your own repos** (`/user/repos`, including private)
* Can clone **an org’s repos** (`--org <orgname>`)
* **Skips repos that are already cloned** (checks folder name)
* Lets you choose **SSH vs HTTPS**
* Lets you optionally **include forks**

---

## 🔧 Script: `clone-all-github-repos.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

########################################
# Configuration / Defaults
########################################

ORG=""
TARGET_DIR="."
INCLUDE_FORKS="false"
PROTOCOL="ssh"  # ssh | https

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --org NAME        Clone repos from this GitHub organization instead of your user.
  --dir PATH        Directory to clone into (default: current directory).
  --include-forks   Include forked repositories (default: skip forks).
  --https           Use HTTPS clone URLs instead of SSH (default: SSH).
  -h, --help        Show this help.

Authentication:
  - PAT is read from the GITHUB_PAT environment variable if set,
    otherwise from ~/.github_pat.

Examples:
  # Clone all repos (your user, private+public, no forks, SSH)
  GITHUB_PAT=xxxx $(basename "$0")

  # Same, with PAT stored in ~/.github_pat
  $(basename "$0")

  # Clone all repos from org 'my-org' into ./org-repos using HTTPS
  $(basename "$0") --org my-org --dir ./org-repos --https

  # Clone everything including forks
  $(basename "$0") --include-forks
EOF
}

########################################
# Parse arguments
########################################

while [[ $# -gt 0 ]]; do
  case "$1" in
    --org)
      ORG="$2"
      shift 2
      ;;
    --dir)
      TARGET_DIR="$2"
      shift 2
      ;;
    --include-forks)
      INCLUDE_FORKS="true"
      shift 1
      ;;
    --https)
      PROTOCOL="https"
      shift 1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

########################################
# Read PAT
########################################

if [[ -n "${GITHUB_PAT-}" ]]; then
  TOKEN="$GITHUB_PAT"
elif [[ -f "$HOME/.github_pat" ]]; then
  TOKEN="$(<"$HOME/.github_pat")"
else
  echo "ERROR: GitHub Personal Access Token not found." >&2
  echo "Set GITHUB_PAT env var or put the token in ~/.github_pat" >&2
  exit 1
fi

########################################
# Dependency checks
########################################

for cmd in curl jq git; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: '$cmd' is not installed but required." >&2
    exit 1
  fi
done

########################################
# Determine API endpoint
########################################

if [[ -n "$ORG" ]]; then
  echo "==> Cloning repos from GitHub organization: $ORG"
  API_BASE="https://api.github.com/orgs/$ORG/repos"
else
  echo "==> Cloning repos for the authenticated user"
  API_BASE="https://api.github.com/user/repos"
fi

mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

PAGE=1
PER_PAGE=100

while :; do
  echo "==> Fetching page $PAGE..."

  RESPONSE=$(curl -sS -H "Authorization: token $TOKEN" \
    "$API_BASE?type=all&per_page=$PER_PAGE&page=$PAGE")

  # If rate-limited or error, show something helpful
  if echo "$RESPONSE" | jq -e 'type=="object" and has("message")' >/dev/null 2>&1; then
    echo "GitHub API returned an error:" >&2
    echo "$RESPONSE" | jq -r '.message' >&2
    exit 1
  fi

  COUNT=$(echo "$RESPONSE" | jq 'length')
  if [[ "$COUNT" -eq 0 ]]; then
    echo "==> No more repos found. Done."
    break
  fi

  # Build jq filter:
  #   - optionally filter out forks
  #   - choose ssh_url or clone_url
  if [[ "$INCLUDE_FORKS" == "true" ]]; then
    FORK_FILTER='.'
  else
    FORK_FILTER='select(.fork == false)'
  fi

  if [[ "$PROTOCOL" == "ssh" ]]; then
    URL_FIELD='ssh_url'
  else
    URL_FIELD='clone_url'
  fi

  REPOS=$(echo "$RESPONSE" | jq -r ".[] | $FORK_FILTER | .$URL_FIELD")

  if [[ -z "$REPOS" ]]; then
    echo "==> No repos on this page after filtering (maybe only forks)."
    ((PAGE++))
    continue
  fi

  while IFS= read -r REPO_URL; do
    [[ -z "$REPO_URL" ]] && continue

    REPO_NAME=$(basename "$REPO_URL" .git)

    if [[ -d "$REPO_NAME" ]]; then
      echo "-- Skipping $REPO_NAME (already exists)"
      continue
    fi

    echo "++ Cloning $REPO_URL -> $REPO_NAME"
    git clone "$REPO_URL"
  done <<< "$REPOS"

  ((PAGE++))
done

echo "==> All repositories processed."
```

---

## 📦 Setup Steps

1. **Save the script**
   For example:

   ```bash
   mkdir -p ~/bin
   nano ~/bin/clone-all-github-repos.sh
   # paste the script, save, exit
   chmod +x ~/bin/clone-all-github-repos.sh
   ```

2. **Give the script your GitHub token.** See [Providing the token](#providing-the-token-fixes-error-github-personal-access-token-not-found) below. The quickest way, if `gh` is installed:

   ```bash
   GITHUB_PAT="$(gh auth token)" ./clone_all_repos.sh --dir ~/dev --https
   ```

3. **Run it**

    * Clone **your own repos** (SSH, no forks) into current dir:

      ```bash
      clone-all-github-repos.sh
      ```

    * Clone **your own repos** into `~/code/github`:

      ```bash
      clone-all-github-repos.sh --dir ~/code/github
      ```

    * Clone **org repos** over **HTTPS**, including forks:

      ```bash
      clone-all-github-repos.sh --org my-org --https --include-forks --dir ~/code/my-org
      ```
      
## Providing the token (fixes "ERROR: GitHub Personal Access Token not found")

The script looks for your GitHub token in two places, in this order:
1. the environment variable `GITHUB_PAT`
2. the file `~/.github_pat`

If it finds neither, it stops with that error. Use **one** of these three ways.

### Option 1 (easiest): borrow the token from `gh`

Nothing to create or store. Log in to GitHub with `gh`, once:

```bash
gh auth login
gh auth setup-git
```

Then run the script with gh's token:

```bash
GITHUB_PAT="$(gh auth token)" ./clone_all_repos.sh --dir ~/dev --https
```

`gh auth token` prints the token gh already saved in your keychain, and the script uses it for this run only. `gh auth setup-git` lets the `--https` clones use the same login, so git doesn't ask for a password.

### Option 2: save a token in `~/.github_pat`

1. **Create the token on GitHub** (details in [generate_github_pat.md](generate_github_pat.md)):
   - Settings → Developer settings → **Fine-grained tokens** → **Generate new token**
   - Resource owner: **your account**
   - Repository access: **All repositories**
   - Permissions: **Contents: Read** (Metadata: Read is added automatically)
   - Click **Generate token** and **copy it**. GitHub only shows it once.
2. **Save it to the file straight from the clipboard,** so the token never appears in your shell history. `chmod 600` makes the file readable only by you:

   ```bash
   pbpaste > ~/.github_pat && chmod 600 ~/.github_pat
   ```

3. **Run the script:**

   ```bash
   ./clone_all_repos.sh --dir ~/dev --https
   ```

### Option 3: set it for the current Terminal window only

```bash
read -rs GITHUB_PAT && export GITHUB_PAT
```

Paste the token and press Return. Nothing is shown and nothing is saved to history. Then run the script. The token is forgotten when you close the window.

### Things to know

- **Each Mac user needs their own:** `~/.github_pat` and the `gh` login are per user. A second user on the same Mac needs their own token or their own `gh auth login`.
- **SSH vs HTTPS:** without `--https`, the script clones over SSH. That needs your SSH key added to GitHub (`./add_sshkey_github.sh`). If you haven't done that, use `--https`.
- **"Bad credentials" error:** the token is wrong, expired, or doesn't have access to your repositories. Create a new one with **All repositories** and **Contents: Read**.
- **Avoid** `export GITHUB_PAT="ghp_..."` or `echo "ghp_..." > ~/.github_pat` typed directly. Both save the token in your shell history. Use Options 1 to 3 instead.

## How does it know the user? we did not specify --org
Because the script sends your Personal Access Token with every API call:
→ GitHub decodes the PAT
→ Identifies your GitHub user
→ Returns all repos associated with that identity

> No username required.