- Bootstraps your Mac (Homebrew, Rosetta on Apple Silicon, Command Line Tools).
- Installs tools in bulk (PyCharm, Git, Python/pyenv, JDK, Spark, Docker, AWS/Azure/GCloud CLIs, SnowSQL, jq, etc.), sets paths, and creates a ready-to-use Python venv with common packages.
- [Display Link Manager](https://www.synaptics.com/products/displaylink-graphics/downloads/macos)
- ./add_sshkey_githun.sh youremail@mail.com
- ./clone_all_repos.sh --dir ~/dev --https

## Note: second user on the same Mac can't find Homebrew tools (`gh: command not found`)

Homebrew installed by **user1** lives in `/opt/homebrew/bin` (Apple silicon), which isn't on **user2**'s PATH. Run these three commands **as user2**, once:

1. Add Homebrew to user2's PATH permanently. Pick **one** option, not both. Use `>>`, not `>`, so the existing file isn't wiped.

   **Option A: Homebrew's recommended way.** This also sets up man pages and other paths:

   ```bash
   echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
   ```

   **Option B: just the PATH:**

   ```bash
   echo 'export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"' >> ~/.zprofile
   ```

2. Load it into the current Terminal window:

   ```bash
   source ~/.zprofile
   ```

3. Check it worked:

   ```bash
   gh --version
   ```

Then log in to GitHub as user2. Logins are per user and aren't shared with user1:

```bash
gh auth login
gh auth setup-git
```

New Terminal windows pick up the PATH automatically. Fully quit and reopen VS Code (⌘ Q) for its terminal to pick it up. Only **user1** can run `brew install`; user2 can use the installed tools.