# Mac for Windows users

Helps someone coming from Windows: recover a forgotten Mac login password, and make macOS look and behave as close to Windows as it allows.

| File | What it does |
|---|---|
| [`make-mac-windows-like.sh`](make-mac-windows-like.sh) | Applies Windows-style settings (Finder, scrolling, right-click, Dock, snapping, Home/End keys, screenshots) and installs AltTab, Rectangle, Chrome, Edge and VS Code. Optional `--with-ubar` adds the uBar taskbar. Backs up your settings first; `--undo` puts everything back |
| [`reset-user-password.sh`](reset-user-password.sh) | From an admin account, resets the password of *another* user on the Mac |
| [`admin_recovery_steps.md`](admin_recovery_steps.md) | Step-by-step recovery of a forgotten **admin** login password |

---

## Make the Mac feel like Windows

Open **Terminal** (⌘ Space → type "Terminal" → Return), go to this folder, then:

```bash
chmod +x make-mac-windows-like.sh
./make-mac-windows-like.sh
```

Options:

```bash
./make-mac-windows-like.sh --no-apps     # settings only, install nothing
./make-mac-windows-like.sh --with-ubar   # also install uBar (Windows-style taskbar) and hide the Dock
./make-mac-windows-like.sh --undo        # restore all macOS defaults (brings the Dock back)
```

Options can be combined, e.g. `--no-apps --with-ubar` installs only uBar plus the settings.

Don't run it with `sudo`. It changes settings for the user who runs it. If Homebrew (the Mac's package manager, like winget) isn't installed, the script installs it and asks for your Mac password once.

### What it changes

| Area | Change |
|---|---|
| Finder | Shows file extensions, path bar and status bar; folders on top; List view by default; new windows open your home folder; search looks in the current folder; hard drive and USB drives shown on the desktop |
| Mouse / trackpad | Windows scroll direction (Natural scrolling off), tap to click, two-finger click = right-click |
| Windows | Scroll bars always visible; double-click a title bar to maximize; drag windows to screen edges to snap; clicking the wallpaper no longer hides all windows; Tab moves through all buttons |
| Dock | No "recent apps" section, simple minimize animation, dots under running apps |
| Keyboard | Home/End go to start/end of the **line** and Ctrl+Home/End to top/bottom, in most Mac apps |
| Screenshots | Saved to `Pictures/Screenshots` |
| Apps | **AltTab** (Windows-style Alt+Tab with window previews), **Rectangle** (snap windows to halves/quarters with shortcuts), Chrome, Edge, VS Code |
| Taskbar (only with `--with-ubar`) | Installs **uBar** and hides the Mac Dock so uBar is the only taskbar (⌘ ⌥ D still shows the Dock) |

### After running it (only you can do these)

1. **Log out and back in** so scrolling and tap-to-click fully apply.
2. **Allow AltTab and Rectangle** when they ask: System Settings → Privacy & Security → Accessibility (and Screen Recording for AltTab).
3. **Using a Windows keyboard?** So that Ctrl+C copies: System Settings → Keyboard → Keyboard Shortcuts → **Modifier Keys** → choose the keyboard → *Control key* = ⌘ Command, *Command key* = ⌃ Control.

### Is there a free "Windows shell" for macOS?

No. Unlike Windows, macOS doesn't let a third-party app replace its desktop (the menu bar at the top, the Dock, window buttons on the left). The closest you can get for free is what this script does: Windows-style settings plus **AltTab**, **Rectangle** and, if you want deeper keyboard remapping, **Karabiner-Elements** (`brew install --cask karabiner-elements`). For a real bottom taskbar with window buttons, **uBar** is the best-known option, but it's paid (free trial). See below.

### Optional: uBar, a Windows-style taskbar

uBar puts a taskbar at the bottom of the screen with **one button per window**, a Start-style menu, a clock and window previews. It's a **paid app with a free trial**.

**Install it** with the script:

```bash
./make-mac-windows-like.sh --with-ubar
```

That installs uBar through Homebrew (`brew install --cask ubar`) and hides the Mac Dock. If Homebrew can't find it, download uBar from the developer's site (Brawer Software).

To do it by hand instead:
1. Install uBar.
2. Hide the Dock: System Settings → **Desktop & Dock** → *Automatically hide and show the Dock*: **On**.
3. Optionally stop the Dock popping up at all:

   ```bash
   defaults write com.apple.dock autohide-delay -float 1000 && killall Dock
   ```

**Set it up to feel like Windows:**
1. Allow it in System Settings → Privacy & Security → **Accessibility** (to control windows) and **Screen Recording** (for window previews).
2. In uBar's preferences:
   - position: **Bottom**
   - group by **Window** (one button per window, like Windows)
   - turn on the **Start-style menu**, **clock** and **window previews**
   - turn on **Launch at login**
3. Need the Dock for a moment? **⌘ ⌥ D** toggles it.

**During the trial, check that:**
- minimizing and restoring windows from uBar feels natural
- it plays well with AltTab and Rectangle
- it isn't using much CPU or memory (Activity Monitor)

**Not buying it?**

```bash
./make-mac-windows-like.sh --undo   # brings the Dock back
brew uninstall --cask ubar
```

Also remove uBar from System Settings → General → **Login Items** if it's still listed.

### Things macOS won't let you change

- The **menu bar is always at the top of the screen**, not inside each window.
- Window buttons (close, minimize, maximize) stay on the **top-left**.
- Closing the last window usually **doesn't quit the app** (the dot under its Dock icon shows it's still running). Quit with **⌘ Q**.

---

## Windows → Mac cheat sheet

| Windows | Mac |
|---|---|
| Start menu / search | **⌘ Space** (Spotlight), or the Apps / Launchpad icon in the Dock |
| Ctrl + C / V / X / Z | **⌘ C / V / X / Z** |
| Cut and paste a file | **⌘ C**, then **⌘ ⌥ Option + V** (moves it) |
| Delete file | **⌘ Backspace** |
| Rename file (F2) | Select it, press **Return** |
| Open file (Enter) | **⌘ O** or double-click |
| Close window (X) | **⌘ W** (the app keeps running) |
| Quit app (Alt + F4) | **⌘ Q** |
| Alt + Tab | **⌘ Tab** (apps), or AltTab (windows) |
| Ctrl + Alt + Del / Task Manager | **⌘ ⌥ Esc** (Force Quit) / **Activity Monitor** |
| Win + Shift + S (snip) | **⌘ Shift 4** (area), **⌘ Shift 5** (all options) |
| Lock screen (Win + L) | **⌃ Ctrl + ⌘ + Q** |
| Show desktop (Win + D) | **F11**, or spread thumb and three fingers on the trackpad |
| Snap window left/right (Win + ←/→) | **Fn + Ctrl + ← / →** (built in), or Rectangle's **Ctrl + ⌥ + ← / →** |
| Control Panel / Settings | **System Settings** |
| File Explorer | **Finder** |
| winget | **Homebrew** (`brew install --cask <app>`) |

---

## Recovering a forgotten Mac login password

Full step-by-step guide: **[admin_recovery_steps.md](admin_recovery_steps.md)** (based on Apple's [If you forgot your Mac login password](https://support.apple.com/en-us/102633)).

**Part A: reset it on the Mac**
1. **Start in Recovery:** on Apple silicon, hold the power button until "Loading startup options" → **Options** → **Continue**. On Intel, hold **⌘ + R** while starting.
2. Click **"Forgot all passwords?"**
3. Choose the **recovery key** and type it (24 characters, capitals, with dashes). The box is faint: click in the window or press **Tab**, then type.
4. Answer the prompts (Macintosh HD, allow Deactivate, pick your user), set a **new password**, and allow a new keychain.
5. **Restart** and log in with the new password.

**Part B: get the recovery key** (macOS Tahoe 26+)
Use an iPhone, iPad or other Mac on the **same Apple Account** with iCloud Keychain on → open the **Passwords** app → search **`recovery key`** → open the entry named after your Mac → tap the dots to show the key.

**If that doesn't work:** use your **Apple Account** instead of the key at step 3; or try Recovery → **Utilities → Terminal → `resetpassword`**; or reset from another admin account (or run [`reset-user-password.sh`](reset-user-password.sh) there). Last resort: Recovery Assistant → **Erase Mac**, which deletes everything.
