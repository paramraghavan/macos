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

2. **Store your PAT safely**

   **Option A – Env var**

   ```bash
   export GITHUB_PAT="ghp_yourtokenhere"
   ```

   **Option B – File (nicer for long-term)**

   ```bash
   echo "ghp_yourtokenhere" > ~/.github_pat
   chmod 600 ~/.github_pat
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
      
## How does it know the user? we did not specify --org
Because the script sends your Personal Access Token with every API call:
→ GitHub decodes the PAT
→ Identifies your GitHub user
→ Returns all repos associated with that identity

> No username required.