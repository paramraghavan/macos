In that case, you can download directly from OneDrive's web interface to your SSD, bypassing local storage entirely.
Here's how:

**Set your browser's default download location to the SSD first:**

**Safari:** Settings → General → File download location → Select your SSD

**Chrome:** Settings → Downloads → Change location → Select your SSD

**Then download from OneDrive web:**

1. Go to [onedrive.live.com](https://onedrive.live.com)
2. Select the files/folders you want
3. Click **Download** — files go straight to your SSD

---

**For large folders, a better approach is rclone (free CLI tool):**

It streams directly from OneDrive to your SSD without using local disk space as a buffer.

```bash
# Install via Homebrew
brew install rclone

# Configure OneDrive (one-time setup)
rclone config

# Copy directly to your SSD
rclone copy onedrive:/ /Volumes/YourSSDName/ --progress
```

During `rclone config`, choose **Microsoft OneDrive** as the remote type and follow the OAuth login steps. After that,
transfers go cloud → SSD with minimal local storage use.

---

**rclone is the best option here** if you have a lot of data — it handles large transfers reliably, supports resume, and
never stages files on your main drive.

## rclone in detail

Here's the full step-by-step rclone setup:

---

## Step 1: Install rclone

Open **Terminal** and run:

```bash
brew install rclone
```

If you don't have Homebrew, install it first:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

---

## Step 2: Start configuration

```bash
rclone config
```

You'll see a menu. Type **n** and press Enter to create a new remote.

---

## Step 3: Name your remote

```
name> onedrive
```

Type `onedrive` and press Enter.

---

## Step 4: Choose storage type

It will list numbered options. Type:

```
Storage> onedrive
```

Or type the number next to **Microsoft OneDrive** in the list.

---

## Step 5: Client ID and Secret

For both of these, just press **Enter** to skip (use defaults):

```
client_id> [just press Enter]
client_secret> [just press Enter]
```

---

## Step 6: Choose region

```
region> 1
```

Press Enter for the default (global/personal OneDrive).

---

## Step 7: Advanced config & auto config

```
Edit advanced config? n
Use auto config? y
```

A **browser window will open** — log into your Microsoft account and grant rclone permission.

---

## Step 8: Choose account type

```
Your choice> 1
```

Select **OneDrive Personal or Business** (option 1).

---

## Step 9: Confirm and finish

rclone will show your drive info. Type **y** to confirm, then **q** to quit the config menu.

---

## Step 10: Find your SSD name

```bash
ls /Volumes/
```

Look for your SSD in the output.

---

## Step 11: Copy OneDrive → SSD

```bash
rclone copy onedrive:/ /Volumes/YourSSDName/ --progress --transfers 4
```

- Replace `YourSSDName` with your actual SSD name
- `--progress` shows live transfer stats
- `--transfers 4` runs 4 files in parallel (speeds things up)

---

## Bonus: If transfer gets interrupted

Just run the same command again — rclone **skips already-copied files** automatically.

---
