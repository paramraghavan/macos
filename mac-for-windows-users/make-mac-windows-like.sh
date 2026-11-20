#!/bin/bash
# =============================================================================
# make-mac-windows-like.sh
# Makes macOS look and behave as close to Windows as macOS allows, for someone
# switching from Windows. Run it as the user who will use the Mac (NOT with sudo).
#
#   ./make-mac-windows-like.sh            # apply settings + install helper apps
#   ./make-mac-windows-like.sh --no-apps  # settings only, install nothing
#   ./make-mac-windows-like.sh --with-ubar  # also install uBar (Windows-style taskbar,
#                                           # paid app with free trial) and hide the Mac Dock
#   ./make-mac-windows-like.sh --undo     # put every setting back to the macOS default
#
# Safe to re-run. Before changing anything it saves a backup of the current
# settings to ~/.mac-windows-like-backup/<date-time>/.
# Some changes (scroll direction, tap to click) take full effect after logging out and back in.
# =============================================================================
set -u

MODE="apply"
INSTALL_APPS=1
WITH_UBAR=0
for arg in "$@"; do
  case "$arg" in
    --undo)       MODE="undo" ;;
    --no-apps)    INSTALL_APPS=0 ;;
    --with-ubar)  WITH_UBAR=1 ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "Unknown option: $arg (try --help)"; exit 1 ;;
  esac
done

if [ "$(id -u)" -eq 0 ]; then
  echo "Don't run this with sudo - run it as the normal user whose Mac this is."; exit 1
fi
if [ "$(uname)" != "Darwin" ]; then
  echo "This script is for macOS only."; exit 1
fi

step() { printf '\n\033[1;36m=== %s ===\033[0m\n' "$1"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }

# Every setting this script touches: "domain|key|type|value|description"
# (-currentHost entries use the domain "currentHost:<domain>")
SETTINGS=(
  # --- Finder: behave like File Explorer
  "NSGlobalDomain|AppleShowAllExtensions|bool|true|Show file extensions (.docx, .pdf, ...)"
  "com.apple.finder|ShowPathbar|bool|true|Finder path bar (like Explorer's address bar)"
  "com.apple.finder|ShowStatusBar|bool|true|Finder status bar (item count, free space)"
  "com.apple.finder|_FXSortFoldersFirst|bool|true|Folders on top when sorting by name"
  "com.apple.finder|FXPreferredViewStyle|string|Nlsv|List view by default (like Explorer's Details view)"
  "com.apple.finder|NewWindowTarget|string|PfHm|New Finder windows open your home folder"
  "com.apple.finder|FXDefaultSearchScope|string|SCcf|Search the current folder, not the whole Mac"
  "com.apple.finder|FXEnableExtensionChangeWarning|bool|false|No warning when renaming a file extension"
  "com.apple.finder|ShowHardDrivesOnDesktop|bool|true|Show the hard drive on the desktop (like 'This PC')"
  "com.apple.finder|ShowExternalHardDrivesOnDesktop|bool|true|Show USB drives on the desktop"
  "com.apple.finder|ShowRemovableMediaOnDesktop|bool|true|Show removable media on the desktop"
  # --- Mouse / trackpad
  "NSGlobalDomain|com.apple.swipescrolldirection|bool|false|Windows scroll direction (Natural scrolling off)"
  "com.apple.AppleMultitouchTrackpad|Clicking|bool|true|Tap to click (built-in trackpad)"
  "com.apple.driver.AppleBluetoothMultitouch.trackpad|Clicking|bool|true|Tap to click (Magic Trackpad)"
  "currentHost:NSGlobalDomain|com.apple.mouse.tapBehavior|int|1|Tap to click (login screen and current host)"
  "com.apple.AppleMultitouchTrackpad|TrackpadRightClick|bool|true|Two-finger click = right-click"
  "com.apple.driver.AppleBluetoothMultitouch.trackpad|TrackpadRightClick|bool|true|Two-finger click = right-click (Magic Trackpad)"
  # --- Windows and desktop
  "NSGlobalDomain|AppleShowScrollBars|string|Always|Scroll bars always visible"
  "NSGlobalDomain|AppleActionOnDoubleClick|string|Maximize|Double-click a title bar to maximize (zoom)"
  "NSGlobalDomain|AppleKeyboardUIMode|int|2|Tab key moves between all buttons and controls"
  "com.apple.WindowManager|EnableStandardClickToShowDesktop|bool|false|Clicking the wallpaper does NOT hide all windows"
  "com.apple.WindowManager|EnableTilingByEdgeDrag|bool|true|Snap windows by dragging them to screen edges"
  # --- Dock: behave more like the taskbar
  "com.apple.dock|show-recents|bool|false|No 'recent apps' section in the Dock"
  "com.apple.dock|mineffect|string|scale|Simple minimize animation"
  "com.apple.dock|show-process-indicators|bool|true|Dot under apps that are running"
  "com.apple.dock|minimize-to-application|bool|false|Minimized windows get their own Dock icon"
  # --- Screenshots: like Windows' Pictures\Screenshots
  "com.apple.screencapture|location|string|$HOME/Pictures/Screenshots|Screenshots saved to Pictures/Screenshots"
)

# Only with --with-ubar: hide the Mac Dock so uBar is the only taskbar.
# A 1000-second hover delay means the Dock effectively never pops up; Command+Option+D toggles it.
UBAR_SETTINGS=(
  "com.apple.dock|autohide|bool|true|Dock hides automatically (uBar replaces it)"
  "com.apple.dock|autohide-delay|float|1000|Dock effectively never pops up (Cmd+Option+D shows it)"
)

BACKUP_DOMAINS="NSGlobalDomain com.apple.finder com.apple.dock com.apple.WindowManager com.apple.screencapture com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad"
KEYBINDINGS="$HOME/Library/KeyBindings/DefaultKeyBinding.dict"
KEYBINDINGS_MARKER="// installed by make-mac-windows-like.sh"

restart_ui() {
  killall Finder >/dev/null 2>&1
  killall Dock >/dev/null 2>&1
  killall SystemUIServer >/dev/null 2>&1
}

write_setting() {   # domain key type value
  local domain="$1" key="$2" type="$3" value="$4"
  if [[ "$domain" == currentHost:* ]]; then
    defaults -currentHost write "${domain#currentHost:}" "$key" "-$type" "$value"
  else
    defaults write "$domain" "$key" "-$type" "$value"
  fi
}

delete_setting() {  # domain key
  local domain="$1" key="$2"
  if [[ "$domain" == currentHost:* ]]; then
    defaults -currentHost delete "${domain#currentHost:}" "$key" >/dev/null 2>&1
  else
    defaults delete "$domain" "$key" >/dev/null 2>&1
  fi
}

# =============================================================================
# UNDO
# =============================================================================
if [ "$MODE" = "undo" ]; then
  step "Restoring macOS defaults"
  for entry in "${SETTINGS[@]}" "${UBAR_SETTINGS[@]}"; do
    IFS='|' read -r domain key type value desc <<< "$entry"
    delete_setting "$domain" "$key"
    ok "reset: $desc"
  done
  pgrep -x uBar >/dev/null 2>&1 && osascript -e 'tell application "uBar" to quit' >/dev/null 2>&1
  if [ -f "$KEYBINDINGS" ] && grep -q "$KEYBINDINGS_MARKER" "$KEYBINDINGS"; then
    rm "$KEYBINDINGS"; ok "removed Windows-style Home/End keys"
  fi
  restart_ui
  echo
  echo "Done. Log out and back in for every change to take effect."
  echo "Apps installed by this script were left in place; remove them with: brew uninstall --cask <name>"
  echo "  (uBar, if you tried it: brew uninstall --cask ubar - and remove it from Login Items)"
  echo "Backups of your earlier settings are in ~/.mac-windows-like-backup/"
  exit 0
fi

# =============================================================================
# APPLY
# =============================================================================
step "Backing up current settings"
BACKUP_DIR="$HOME/.mac-windows-like-backup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
for d in $BACKUP_DOMAINS; do
  defaults export "$d" "$BACKUP_DIR/$d.plist" >/dev/null 2>&1
done
ok "saved to $BACKUP_DIR"

# Close System Settings so it doesn't overwrite what we change
osascript -e 'tell application "System Settings" to quit' >/dev/null 2>&1

step "Applying Windows-style settings"
mkdir -p "$HOME/Pictures/Screenshots"
for entry in "${SETTINGS[@]}"; do
  IFS='|' read -r domain key type value desc <<< "$entry"
  if write_setting "$domain" "$key" "$type" "$value"; then ok "$desc"; else echo "  ! couldn't set: $desc"; fi
done
if [ "$WITH_UBAR" -eq 1 ]; then
  for entry in "${UBAR_SETTINGS[@]}"; do
    IFS='|' read -r domain key type value desc <<< "$entry"
    if write_setting "$domain" "$key" "$type" "$value"; then ok "$desc"; else echo "  ! couldn't set: $desc"; fi
  done
fi

step "Windows-style Home / End keys"
# Makes Home/End jump to the start/end of the LINE (Mac default: top/bottom of the document),
# and Ctrl+Home / Ctrl+End jump to the top/bottom - in most Mac apps (TextEdit, Notes, Mail, Safari...).
if [ -f "$KEYBINDINGS" ] && ! grep -q "$KEYBINDINGS_MARKER" "$KEYBINDINGS"; then
  echo "  You already have $KEYBINDINGS - left it alone."
else
  mkdir -p "$(dirname "$KEYBINDINGS")"
  cat > "$KEYBINDINGS" <<EOF
$KEYBINDINGS_MARKER
{
  "\UF729"   = moveToBeginningOfLine:;
  "\UF72B"   = moveToEndOfLine:;
  "\$\UF729"  = moveToBeginningOfLineAndModifySelection:;
  "\$\UF72B"  = moveToEndOfLineAndModifySelection:;
  "^\UF729"  = moveToBeginningOfDocument:;
  "^\UF72B"  = moveToEndOfDocument:;
  "^\$\UF729" = moveToBeginningOfDocumentAndModifySelection:;
  "^\$\UF72B" = moveToEndOfDocumentAndModifySelection:;
}
EOF
  ok "Home/End = start/end of line, Ctrl+Home/End = top/bottom (restart apps to pick it up)"
fi

restart_ui

# =============================================================================
# APPS
# =============================================================================
if [ "$INSTALL_APPS" -eq 1 ] || [ "$WITH_UBAR" -eq 1 ]; then
  step "Helper apps (via Homebrew)"
  if ! command -v brew >/dev/null 2>&1 && [ ! -x /opt/homebrew/bin/brew ] && [ ! -x /usr/local/bin/brew ]; then
    echo "  Homebrew (the Mac's 'winget') isn't installed. Installing it - it will ask for your Mac password."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  # Make brew available in this script (Apple silicon vs Intel locations)
  if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then eval "$(/usr/local/bin/brew shellenv)"; fi

  if command -v brew >/dev/null 2>&1; then
    # alt-tab:   Windows-style Alt+Tab with window thumbnails
    # rectangle: Windows-style window snapping (halves, quarters, thirds) with keyboard shortcuts
    # google-chrome, microsoft-edge, visual-studio-code: familiar apps from Windows
    # ubar (only with --with-ubar): Windows-style taskbar - paid app with a free trial
    CASKS=""
    [ "$INSTALL_APPS" -eq 1 ] && CASKS="alt-tab rectangle google-chrome microsoft-edge visual-studio-code"
    [ "$WITH_UBAR" -eq 1 ] && CASKS="$CASKS ubar"
    for cask in $CASKS; do
      if brew list --cask "$cask" >/dev/null 2>&1; then ok "$cask already installed"
      elif brew install --cask "$cask"; then ok "installed $cask"
      else echo "  ! couldn't install $cask"
           [ "$cask" = "ubar" ] && echo "    Download uBar from the developer's site (Brawer Software) instead."
      fi
    done
    [ "$INSTALL_APPS" -eq 1 ] && { open -a "AltTab" >/dev/null 2>&1; open -a "Rectangle" >/dev/null 2>&1; }
    [ "$WITH_UBAR" -eq 1 ] && open -a "uBar" >/dev/null 2>&1
  else
    echo "  ! Homebrew isn't available - skipped apps. Re-run after installing it from https://brew.sh"
  fi
fi

# =============================================================================
# DONE
# =============================================================================
step "Done - a few things only you can do"
cat <<'EOF'
 1. LOG OUT and back in (Apple menu > Log Out) so scrolling and tap-to-click fully apply.
 2. AltTab and Rectangle will ask for "Accessibility" (and AltTab for "Screen Recording")
    permission: System Settings > Privacy & Security > allow them. In AltTab's settings,
    set the shortcut to Option+Tab (or Command+Tab) to taste.
 3. Using a WINDOWS keyboard? So that Ctrl+C copies:
    System Settings > Keyboard > Keyboard Shortcuts > Modifier Keys > pick the keyboard >
    Control key = Command, Command (Windows) key = Control.
EOF
if [ "$WITH_UBAR" -eq 1 ]; then
  cat <<'EOF'
 4. uBar (trial): allow it in Privacy & Security > Accessibility and Screen Recording.
    In uBar's preferences: position Bottom, group by Window (one button per window),
    turn on the Start-style menu, clock and window previews, and Launch at login.
    The Mac Dock is now hidden - Command+Option+D shows it if you need it.
    Not buying it? Run --undo (brings the Dock back), then: brew uninstall --cask ubar
EOF
else
  echo " 4. Want a real Windows-style taskbar? Re-run with --with-ubar (paid app, free trial)."
fi
echo
echo "To undo everything:  ./make-mac-windows-like.sh --undo"
