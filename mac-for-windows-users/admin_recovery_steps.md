# Recovering a forgotten macOS admin password

Try the options in order and stop when one works.

## 1. Reset with your Apple Account (easiest)

1. At the login screen, enter a wrong password **3 times**.
2. A message appears with an arrow ➜, or a **"Restart and show password reset options"** button. Click it.
3. Sign in with your **Apple Account** (Apple ID) email and password.
4. Choose the admin user and set a **new password**.

If no reset option appears, your Apple Account isn't linked to the login. Go to option 2.

## 2. Use your FileVault recovery key

If the Mac is encrypted with FileVault and you saved the **recovery key** when setting it up (a code like `ABCD-EFGH-...`, maybe in a note or printout), the same prompt after 3 failed tries offers to use it. Enter the key, then set a new password.

## 3. Use another admin account (if there is one)

Log in as the other admin → **System Settings → Users & Groups** → click ⓘ next to your account → **Reset Password**.

Or, from that admin account, run the helper script in this folder:

```bash
./reset-user-password.sh
```

## 4. Recovery Mode

1. **Shut down** the Mac.
2. Start Recovery:
   - **Apple silicon (M1, M2, M3, M4):** press and **hold the power button** until "Loading startup options" appears → click **Options** → **Continue**.
   - **Intel Mac:** press power, then immediately **hold ⌘ Command + R** until the Apple logo appears.
3. If you see **"Forgot all passwords?"**, click it, sign in with your Apple Account, and set a new password.
4. Otherwise, from the top menu choose **Utilities → Terminal**, type:

   ```
   resetpassword
   ```

   and press Return. In the Reset Password window, choose **"I forgot my password"**, follow the steps, pick your admin user, and set the new password.
5. Restart the Mac (Apple menu → Restart) and log in with the new password.

> No script can do this step for you. You're outside macOS when you need it.

## After you're back in

- If you see **"The system was unable to unlock your login keychain"**, choose **Create New Keychain**. Old saved passwords stored only on this Mac are lost, but those in **iCloud Keychain** come back once you sign in to iCloud.
- Save the new password in a **password manager**.
- Make option 1 work next time: **System Settings → Users & Groups** → ⓘ next to your account → turn on **Allow user to reset password using Apple Account**.
- Note down your **FileVault recovery key** somewhere safe (System Settings → Privacy & Security → FileVault).

## If none of these work

The last resort is **Recovery → Erase Mac**, then restoring from a Time Machine backup if you have one. You'll need your **Apple Account password** afterwards to get past Activation Lock. If you don't know that either, contact **Apple Support** with your proof of purchase.
