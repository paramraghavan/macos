#!/bin/bash
# =============================================================================
# reset-user-password.sh
# Resets the login password of ANOTHER local user on this Mac.
# Run it from a working ADMIN account, e.g. when a family member forgot theirs:
#
#   ./reset-user-password.sh            # lists users, asks which one
#   ./reset-user-password.sh jane       # reset the password for user "jane"
#
# Forgot the password of the ONLY admin account? A script can't help - you can't
# log in to run it. Use the Recovery steps in README.md (Apple Account reset or
# Recovery Mode -> Terminal -> resetpassword).
# =============================================================================
set -eu

if [ "$(uname)" != "Darwin" ]; then echo "macOS only."; exit 1; fi

ME="$(id -un)"
if ! dseditgroup -o checkmember -m "$ME" admin >/dev/null 2>&1; then
  echo "You ($ME) are not an administrator. Log in with an admin account and run this again."
  exit 1
fi

# Real (non-system) local users: UID >= 501
USERS=$(dscl . -list /Users UniqueID | awk '$2 >= 501 {print $1}')

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "Local users on this Mac:"
  for u in $USERS; do
    name=$(dscl . -read "/Users/$u" RealName 2>/dev/null | tail -n +2 | sed 's/^ *//')
    echo "  - $u  (${name:-no full name})"
  done
  read -r -p "Username to reset: " TARGET
fi

if ! echo "$USERS" | grep -qx "$TARGET"; then
  echo "No local user called '$TARGET'."; exit 1
fi
if [ "$TARGET" = "$ME" ]; then
  echo "To change your OWN password use System Settings > Users & Groups > Change Password"
  echo "(that also updates your keychain). This script is for other users."
  exit 1
fi

cat <<EOF

About to reset the password for: $TARGET
  - You'll be asked for YOUR admin password ($ME), then the NEW password for $TARGET.
  - $TARGET's saved passwords (login keychain) can't be unlocked with the new password.
    At next login they choose "Create New Keychain"; iCloud Keychain items come back after
    signing in to iCloud.
EOF
read -r -p "Continue? (y/N) " ans
case "$ans" in y|Y|yes|YES) ;; *) echo "Cancelled."; exit 0 ;; esac

# "-" makes sysadminctl prompt for each password, so nothing ends up in shell history.
# Passing the admin credentials keeps FileVault / Secure Token working for that user.
sudo sysadminctl -resetPasswordFor "$TARGET" -newPassword - -adminUser "$ME" -adminPassword -

echo
echo "Done. $TARGET can now log in with the new password."
