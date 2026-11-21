# Forgot your MacBook login password? Reset it with the recovery key

Follow these steps in order. You'll need your **FileVault recovery key**. [Part B](#part-b-get-the-recovery-key-from-your-iphone-or-ipad--another-mac) shows how to get it from your iPhone, so do Part B first if you don't already have the key.

Based on Apple's [If you forgot your Mac login password](https://support.apple.com/en-us/102633).

---

## Part A. Reset the password on the Mac

### Step 1. Start the Mac in Recovery

1. **Shut down** the Mac. If it won't shut down, hold the power button for about 10 seconds.
2. Start it in Recovery ([Apple guide](https://support.apple.com/en-us/102518)):
   - **Apple silicon (M1, M2, M3, M4…):** press and **hold the power button** until **"Loading startup options"** appears → click **Options** → **Continue**.
   - **Intel Mac:** press power, then immediately **hold ⌘ Command + R** until the Apple logo appears.

### Step 2. Choose "Forgot all passwords?"

When the Mac asks you to **select a user you know the password for**, click **"Forgot all passwords?"** below the list.

### Step 3. Enter the recovery key

The Mac asks for your **Apple Account** or your **recovery key**. Choose the **recovery key**.

> **Don't have the key?** Get it from your iPhone first: see [Part B](#part-b-get-the-recovery-key-from-your-iphone-or-ipad--another-mac).

> **The box is hard to see.** The field for the key is a long, empty, faint box. If you can't see it, click in the middle of the window, or press **Tab** until the cursor appears, then start typing.

Type the key:
- It's **24 characters** in 6 groups: `XXXX-XXXX-XXXX-XXXX-XXXX-XXXX`.
- Use **capital letters** and **type the dashes**.
- Recovery keys never contain **I**, **S**, **1** or **0**. If a character looks like one of those, it's probably the other: **1** is really **I**, and **0** is really **O**.

Press **Return** or click **Next**.

### Step 4. Set a new password

The next prompts vary. Answer whichever appear:

1. **Select a volume:** choose **Macintosh HD**.
2. **Deactivate Mac:** allow it. Apple says it's temporary.
3. **Choose a user:** pick your account.
4. **New password:** type the new password twice, and add a hint if you like.
5. **Create new keychain:** allow it. Website passwords saved in iCloud come back once you sign in to iCloud.

### Step 5. Restart and log in

Choose **Apple menu → Restart**, then log in with the **new password**.

---

## Part B. Get the recovery key from your iPhone (or iPad / another Mac)

This works when the MacBook runs **macOS Tahoe 26 or later** and its key was saved to iCloud.

1. Use an **iPhone, iPad or another Mac** that's signed in to the **same Apple Account** as the MacBook, with **iCloud Passwords & Keychain** turned on ([how to turn it on](https://support.apple.com/en-us/109016)).
2. Open the **Passwords** app ([about the app](https://support.apple.com/en-us/120758)).
   - On a Mac running macOS Sonoma or earlier there's no Passwords app. Use **System Settings → Passwords** instead.
3. Type **`recovery key`** in the **Search** field.
4. Tap or click the result that **names your MacBook**.
5. Tap or click the **dots in the Recovery Key field** to show the key. You'll be asked for Face ID, Touch ID or the passcode.
6. Type that key into the box in [Part A, Step 3](#step-3-enter-the-recovery-key).

**No result?** Check the **All** view and **Recently Deleted** in the Passwords app, and make sure iCloud Keychain has finished syncing. If it's still not there, the key wasn't saved to iCloud: look in your notes, photos, printouts or another password manager.

---

## If that doesn't work

| Problem | What to do |
|---|---|
| No recovery key anywhere | At Step 3, choose **Apple Account** instead and sign in with your Apple Account email and password. A code may be sent to your iPhone. |
| No "Forgot all passwords?" button | In Recovery, choose **Utilities → Terminal** from the menu bar, type `resetpassword`, press Return, choose **"I forgot my password"** → **Next**, then continue from Step 3. |
| Another admin account on the Mac still works | Log in as that admin → **System Settings → Users & Groups** → ⓘ next to your account → **Reset Password**. Or run [`reset-user-password.sh`](reset-user-password.sh) from that account. |
| Forgot the Apple Account password too | Reset it at [iforgot.apple.com](https://iforgot.apple.com) or on your iPhone (Settings → your name → Sign-In & Security → Change Password). |
| Nothing works | **Last resort, which deletes everything:** in Recovery choose **Recovery Assistant → Erase Mac** → **Erase Mac** twice. Then [reinstall macOS](https://support.apple.com/en-us/102655), sign in with your Apple Account at the "Activate Mac" screen, and restore from Time Machine if you have a backup. |

---

## Afterwards, so it's easy next time

- Save the new login password in the **Passwords** app or a password manager.
- Turn on **Allow user to reset password using Apple Account**: System Settings → Users & Groups → ⓘ next to your account.
- Check the recovery key is saved: search **`recovery key`** in the Passwords app on your iPhone. If it isn't there, create a new key in Terminal and save it:

  ```bash
  sudo fdesetup changerecovery -personal
  ```
