# Windows machine setup

One PowerShell script, [`setup-windows.ps1`](setup-windows.ps1), that sets up a new Windows machine.

**Laptop:** Acer Aspire Go 15.6" (i7-13620H, 16 GB DDR5, 512 GB). For first-day updates, performance settings, battery care (including getting the most hours on the move) and upkeep, see **[LAPTOP-CARE.md](LAPTOP-CARE.md)**.

**Files in this folder**

| File | What it's for |
|---|---|
| [`setup-windows.ps1`](setup-windows.ps1) | Installs all the apps, clones your repos, sets up PySpark |
| [`remove-bloat.ps1`](remove-bloat.ps1) | Removes preinstalled trials and promo apps. Preview by default; `-Apply` to remove. Details in [LAPTOP-CARE.md](LAPTOP-CARE.md#4-removing-bloat-with-remove-bloatps1) |
| [`LAPTOP-CARE.md`](LAPTOP-CARE.md) | Performance, battery, heat, storage and maintenance guide for this laptop |

Suggested order on a new laptop: Windows Update → `remove-bloat.ps1` → `setup-windows.ps1`.

## What it does

1. **Installs apps with winget** (Windows' built-in package manager): Google Chrome, VS Code (plus its Python and Jupyter extensions), OneDrive (usually already on Windows 11, so it's skipped there), Git for Windows (includes **Git Bash**), GitHub CLI, Python 3.12, Java 17 (Temurin). Spark needs Java.
   **Git Bash** gives you a Mac-style bash shell (`ls`, `grep`, `ssh`, etc.). Open it from Start → "Git Bash", or right-click a folder → "Open Git Bash here". The script also makes Git Bash the default terminal in VS Code (`terminal.integrated.defaultProfile.windows`).
2. **Clones all GitHub repos, private ones included.** It opens a browser so you can sign in to GitHub (`gh auth login`), then clones every repo under `paramraghavan` into `C:\Users\<you>\code\github`. On a re-run it pulls updates for repos that are already there.
3. **Sets up PySpark:**
   - Creates a Python virtual environment at `code\pyspark-env` and installs PySpark 3.5, Jupyter, pandas and pyarrow.
   - Sets `JAVA_HOME`, `HADOOP_HOME` and `PYSPARK_PYTHON`.
   - Runs a smoke test that builds a DataFrame, writes it to Parquet and reads it back.
4. **Is safe to re-run.** Apps that are already installed are skipped.

A log is written to `C:\Users\<you>\code\setup-windows.log`.

### About winutils

Spark on Windows needs `winutils.exe` and `hadoop.dll` to write files to disk. The script downloads them from the third-party GitHub repo `cdarlint/winutils` (hadoop-3.3.6) into `C:\hadoop\bin`. This is the usual approach, but if you'd rather not, pass `-SkipWinutils`. Spark will still run, but `df.write` will fail.

## Installing all the requested Windows apps and libraries

> **Note: what gets installed.** Running the script once sets up all of this:
>
> | Category | What | Where / notes |
> |---|---|---|
> | Browser | Google Chrome | |
> | Editor | Visual Studio Code + Python and Jupyter extensions | Git Bash set as VS Code's default terminal |
> | Cloud storage | OneDrive | Usually preinstalled on Windows 11; you sign in yourself |
> | Git | Git for Windows, including **Git Bash** | `C:\Program Files\Git` |
> | GitHub | GitHub CLI (`gh`) + every repo you own, private ones included | `C:\Users\<you>\code\github` |
> | Python | Python 3.12 | `py` launcher on PATH |
> | Java | Temurin JDK 17 (needed by Spark) | `JAVA_HOME` set |
> | Spark | PySpark 3.5, Jupyter, pandas, pyarrow in a virtual environment | `C:\Users\<you>\code\pyspark-env`, `PYSPARK_PYTHON` set |
> | Hadoop helpers | `winutils.exe`, `hadoop.dll` (skip with `-SkipWinutils`) | `C:\hadoop\bin`, `HADOOP_HOME` set |
>
> At the end it runs a PySpark smoke test. If you see `Spark 3.5.x OK`, everything works.

1. Right-click Start and choose **Terminal (Admin)**.
2. `cd` to the folder that holds the script (for example `cd $HOME\Downloads\windows-install`), then run these three commands. This is the one and only install step; they're explained below.

   ```powershell
   Unblock-File .\setup-windows.ps1
   Set-ExecutionPolicy -Scope Process Bypass -Force
   .\setup-windows.ps1
   ```

3. When it finishes, open a **new** terminal so the new environment variables take effect.
4. Sign in to OneDrive from its icon in the taskbar (the script installs it but can't sign you in). Keep `C:\Users\<you>\code` **outside** OneDrive: syncing `.git` folders and the Python venv is slow and can corrupt them. GitHub is the backup for the repos.

### What those three commands mean

Windows blocks scripts by default, for safety. The first two commands get past those blocks for this one script only, and the third runs it.

**1. `Unblock-File .\setup-windows.ps1`: "I trust this file."**
When you download a file (from a gist, email, etc.), Windows quietly tags it as "came from the internet". Windows is suspicious of tagged scripts and may refuse to run them or ask for confirmation. This command removes the tag from this one file.
- It's like right-clicking the file → Properties → ticking **Unblock**.
- On a Mac, the closest thing is the "downloaded from the internet, are you sure?" prompt.

**2. `Set-ExecutionPolicy -Scope Process Bypass -Force`: "let scripts run in this window."**
PowerShell has a rule called the *execution policy*. On a new Windows machine it often doesn't allow running `.ps1` scripts at all, and you get the error *"running scripts is disabled on this system"*.
- `Bypass` turns off that check.
- `-Scope Process` limits it to **this terminal window only**. Close the window and the normal rule is back. Nothing changes system-wide.
- `-Force` skips the "Are you sure? [Y/N]" question.

**3. `.\setup-windows.ps1`: run the script.**
- `.\` means "in the current folder". PowerShell won't run a script by bare name, even if you're in the same folder. This is also a safety rule, so a file in the folder can't pretend to be a real command.
- This is the step that installs the apps, clones your repos and sets up PySpark.

**In short:** trust the file → allow scripts in this window → run it.

Two things to remember:
- `cd` into the folder with the script first, for example `cd $HOME\Downloads\windows-install`.
- Open the terminal **as Administrator** (right-click Start → Terminal (Admin)). The script refuses to run otherwise, because installing apps for all users needs admin rights.

### Options

| Option | Default | Meaning |
|---|---|---|
| `-GitHubUser` | `paramraghavan` | GitHub account whose repos to clone |
| `-CodeDir` | `$HOME\code` | Where repos and the PySpark venv go |
| `-SkipRepos` | off | Don't clone repos |
| `-SkipPySpark` | off | Don't set up Java/PySpark |
| `-SkipWinutils` | off | Don't download winutils.exe / hadoop.dll |

Example: `.\setup-windows.ps1 -SkipRepos -CodeDir D:\dev`

### Using PySpark afterwards

```powershell
& "$HOME\code\pyspark-env\Scripts\Activate.ps1"
pyspark            # interactive shell
jupyter notebook   # notebooks
```

In VS Code, pick `code\pyspark-env\Scripts\python.exe` as the interpreter (Ctrl+Shift+P → "Python: Select Interpreter").

## Getting the script from a Mac to Windows

AirDrop doesn't work with Windows. Options, best first:

- **Private GitHub Gist.** You're signing in to GitHub on the new machine anyway. On the Mac:

  ```bash
  gh gist create windows-setup/setup-windows.ps1
  ```

  Then open the gist on Windows and download the raw file. A "secret" gist is unlisted, but anyone with the link can see it. That's fine here because the script holds no passwords or keys.
- **LocalSend**: a free, AirDrop-like app for Mac and Windows. Install it on both; they'll find each other on the same Wi-Fi.
- **OneDrive, Google Drive or iCloud Drive** (iCloud has a Windows app), or **email it to yourself**.
- **USB stick.**
- **Windows to Windows**: Windows has an AirDrop-style feature called **Nearby Sharing** (Settings → System → Nearby sharing). Right-click the file → Share.

## Troubleshooting

- **`winget` not found**: install "App Installer" from the Microsoft Store and re-run.
- **"running scripts is disabled"**: run the `Set-ExecutionPolicy -Scope Process Bypass -Force` line first (it only affects that terminal window).
- **`java` or `pyspark` not found right after setup**: open a new terminal.
- **A repo fails to clone**: the script warns and continues. Re-run it later to retry; existing repos are pulled, not re-cloned.
