# Move Two OneDrive Accounts to One Google Drive (Mac)

This guide copies two OneDrive accounts to an external SSD, finds files that exist in both accounts, and uploads everything to one Google Drive account.

**Route:** OneDrive → SSD → verify → find duplicates → review → Google Drive → verify

## How your data stays safe

- `rclone copy` never deletes anything from the source. Don't substitute `rclone sync` or `rclone move`.
- The duplicate script only reads your files and writes its own lists. A duplicate is only skipped during upload, and it stays on the SSD and in OneDrive.
- Each stage is verified by file contents. OneDrive and Google Drive don't share a checksum type, so the SSD is what makes this possible.
- Nothing in this guide deletes data from OneDrive. Leave both accounts in place until the last section.

## Checklist

- [ ] 1. Install the software
- [ ] 2. Format and mount the SSD
- [ ] 3. Connect the three accounts
- [ ] 4. Check available storage
- [ ] 5. Move items rclone may miss
- [ ] 6. Copy `od1` to the SSD and verify it
- [ ] 7. Copy `od2` to the SSD and verify it
- [ ] 8. Make the duplicate list
- [ ] 9. Review the duplicate list
- [ ] 10. Upload to Google Drive
- [ ] 11. Verify Google Drive
- [ ] 12. Finish up

---

## 1. Install the software

You need three things: Apple's Command Line Tools, Homebrew, and rclone. Python 3 comes with the Command Line Tools and runs the duplicate script.

Open **Terminal** (Applications → Utilities) and check what's already installed:

```bash
xcode-select -p
```

```bash
brew --version
```

```bash
rclone version
```

```bash
python3 --version
```

Install only what's missing:

### Command Line Tools

Skip this if `xcode-select -p` printed a folder path.

```bash
xcode-select --install
```

Click **Install** in the window that appears and wait for it to finish.

### Homebrew

Skip this if `brew --version` printed a version.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

When it finishes, run the commands it shows under **Next steps**. They add `brew` to your PATH. Then close and reopen Terminal.

### rclone

If rclone is already installed through Homebrew, run `brew upgrade rclone` instead.

```bash
brew install rclone
```

### Confirm

Each of these should print a version. Python must be 3.8 or newer.

```bash
rclone version
```

```bash
python3 --version
```

---

## 2. Format and mount the SSD

> **Warning: Formatting erases everything on the SSD.** Copy off anything you need first. Check that you've selected the external SSD, not your Mac's internal drive.

### Format

1. Plug in the SSD and open **Disk Utility** (Applications → Utilities).
2. Choose **View → Show All Devices**.
3. In the sidebar, select the top-level entry for the external SSD, usually the manufacturer's name.
4. Click **Erase** and enter:
   - **Name:** `MigrationSSD`
   - **Format:** `APFS`
   - **Scheme:** `GUID Partition Map`
5. Click **Erase**, then **Done**.

The commands in this guide depend on the exact name `MigrationSSD`.

If you plan to keep the SSD as a long-term backup, consider **APFS (Encrypted)**, since it will hold all your personal files. You'll need the password each time you connect it, and the data can't be recovered without it.

### Mount

macOS normally mounts the SSD automatically when you plug it in. Confirm that it's mounted:

```bash
diskutil info /Volumes/MigrationSSD
```

Look for `Mounted: Yes` and `File System Personality: APFS`. See how much free space it has:

```bash
df -h /Volumes/MigrationSSD
```

If it isn't mounted, mount it:

```bash
diskutil mount MigrationSSD
```

If that fails, list the drives and look for your SSD:

```bash
diskutil list external
```

If the volume has a different name, rename it in Disk Utility or replace the path in every command.

### Prepare it

```bash
mkdir -p /Volumes/MigrationSSD/logs
```

If macOS asks whether Terminal can access files on a removable volume, click **Allow**.

To keep long transfers running:

- Keep the Mac plugged in.
- Connect the SSD directly to the Mac if you can, rather than through a hub.
- In **System Settings → Energy** (or **Battery → Options**), turn off **Put hard disks to sleep** if you see the setting.
- Leave the SSD and Google Drive folders alone during transfers.

The `caffeinate -i` part of the long commands keeps the Mac awake. Keep the lid open unless you're using an external display.

### Disconnect it safely

Stop any running transfers first. Then eject it in Finder, or run:

```bash
diskutil eject /Volumes/MigrationSSD
```

---

## 3. Connect the three accounts

Start the setup tool:

```bash
rclone config
```

Choose `n` for a new remote and create these three. Menu numbers vary between versions, so choose by name.

| Remote name | Storage type | Settings |
|---|---|---|
| `od1` | Microsoft OneDrive | Region: Microsoft Cloud Global. Leave client ID and secret blank. Use web browser to log in: yes. Config type: OneDrive Personal or Business. |
| `od2` | Microsoft OneDrive | Same settings as `od1`. |
| `gdrive` | Google Drive | Leave client ID and secret blank. Scope: full access (`drive`). Leave the root folder and service account blank. Use web browser to log in: yes. Not a shared drive. |

> **Avoid connecting the wrong account:** rclone opens your default browser, which may already be signed in. Sign out of Microsoft before connecting `od2`, or copy the rclone sign-in link into a private window.

The script always keeps the `od1` copy of a duplicate, so **make your better-organized account `od1`**.

If either OneDrive is a work or school account, make sure your organization allows you to move that data.

Confirm that all three exist:

```bash
rclone listremotes
```

Then look at each one's top-level folders to confirm it's the right account:

```bash
rclone lsd od1:
```

```bash
rclone lsd od2:
```

```bash
rclone lsd gdrive:
```

If a remote points to the wrong account, run `rclone config`, delete that remote, and create it again.

---

## 4. Check available storage

See how much data each OneDrive account holds:

```bash
rclone size od1:
```

```bash
rclone size od2:
```

See how much free space Google Drive has:

```bash
rclone about gdrive:
```

Before continuing, make sure that:

- **The SSD can hold both accounts:** A 2 TB SSD holds about 1.8 TiB. Aim for at least 10% free space. If your data doesn't fit, you'll need a larger drive or to transfer it in batches.
- **Google Drive has enough free space:** The free tier is only 15 GB, and Gmail and Google Photos share this storage. Plan for the full total, since you may decide to upload everything in step 10.

---

## 5. Move items rclone may miss

Check these on the OneDrive website for **both** accounts:

- **Recycle bin:** Restore anything you want to keep.
- **Personal Vault:** Unlock it and move the files into a normal folder.
- **OneNote notebooks:** Export them separately, as they don't transfer as normal files. Download the export and save it in a normal OneDrive folder, or keep it on the SSD and upload it separately.
- **"Shared with me" files:** These belong to other people and aren't copied. Copy any you want into your own folders.

Version history, sharing links, and permissions won't carry over.

---

## 6. Copy `od1` to the SSD and verify it

```bash
caffeinate -i rclone copy od1: /Volumes/MigrationSSD/od1 --progress --log-file=/Volumes/MigrationSSD/logs/od1-download.log --log-level INFO
```

If this is interrupted, run it again. It only fetches files that are missing or changed.

Compare the SSD copy with OneDrive:

```bash
rclone check od1: /Volumes/MigrationSSD/od1 --one-way --combined /Volumes/MigrationSSD/logs/od1-check.txt
```

List any problems:

```bash
grep -v '^=' /Volumes/MigrationSSD/logs/od1-check.txt
```

No output means every file matched. If anything is listed, rerun the copy and check again. See [Reading check results](#reading-check-results).

---

## 7. Copy `od2` to the SSD and verify it

Start this after `od1` passes its check.

```bash
caffeinate -i rclone copy od2: /Volumes/MigrationSSD/od2 --progress --log-file=/Volumes/MigrationSSD/logs/od2-download.log --log-level INFO
```

```bash
rclone check od2: /Volumes/MigrationSSD/od2 --one-way --combined /Volumes/MigrationSSD/logs/od2-check.txt
```

```bash
grep -v '^=' /Volumes/MigrationSSD/logs/od2-check.txt
```

Don't look for duplicates until both accounts pass their checks.

---

## 8. Make the duplicate list

Save the script by copying this whole block into Terminal:

```bash
cat > ~/onedrive_dupes.py << 'EOF'
#!/usr/bin/env python3
"""Find files in od2 that are exact copies of files in od1. Never changes or deletes files.

  python3 onedrive_dupes.py find  SSD_PATH   writes duplicates.csv
  python3 onedrive_dupes.py build SSD_PATH   writes od2-upload-list.txt from duplicates.csv
"""
import collections, csv, filecmp, hashlib, os, sys

MIN_SIZE = 1024 * 1024  # smaller files are always uploaded
SKIP_NAMES = {".DS_Store"}


def walk(root):
    files = {}
    for folder, _, names in os.walk(root):
        for name in names:
            path = os.path.join(folder, name)
            if name not in SKIP_NAMES and os.path.isfile(path) and not os.path.islink(path):
                files[os.path.relpath(path, root)] = os.path.getsize(path)
    return files


def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as f:
        while chunk := f.read(1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest()


def find(ssd):
    od1_root, od2_root = os.path.join(ssd, "od1"), os.path.join(ssd, "od2")
    od1, od2 = walk(od1_root), walk(od2_root)
    od1_sizes = {size for size in od1.values() if size >= MIN_SIZE}
    od1_candidates = [p for p, size in od1.items() if size in od1_sizes]
    od2_candidates = [p for p, size in od2.items() if size in od1_sizes]
    od2_sizes = {od2[p] for p in od2_candidates}
    od1_candidates = [p for p in od1_candidates if od1[p] in od2_sizes]
    print(f"od1: {len(od1)} files, od2: {len(od2)} files")
    print(f"Comparing contents of {len(od1_candidates) + len(od2_candidates)} same-sized files...")

    od1_by_hash = collections.defaultdict(list)
    for path in od1_candidates:
        od1_by_hash[sha256(os.path.join(od1_root, path))].append(path)

    rows = []
    for path in od2_candidates:
        matches = od1_by_hash.get(sha256(os.path.join(od2_root, path)))
        if not matches:
            continue
        kept = path if path in matches else matches[0]
        if not filecmp.cmp(os.path.join(od1_root, kept), os.path.join(od2_root, path), shallow=False):
            print(f"WARNING: hash matched but bytes differ, will upload: {path}")
            continue
        rows.append((od2[path], kept, path))
    rows.sort(reverse=True)

    with open(os.path.join(ssd, "duplicates.csv"), "w", newline="", encoding="utf-8-sig") as f:
        out = csv.writer(f)
        out.writerow(["skip_upload", "size_mb", "same_path", "kept_from_od1", "skipped_from_od2"])
        for size, kept, path in rows:
            out.writerow(["YES", f"{size / 1024 / 1024:.1f}", "YES" if kept == path else "NO", kept, path])

    dup_bytes = sum(row[0] for row in rows)
    total_bytes = sum(od1.values()) + sum(od2.values())
    same = sum(1 for row in rows if row[1] == row[2])
    by_folder = collections.Counter()
    for size, _, path in rows:
        by_folder[path.split(os.sep)[0] if os.sep in path else "(top level)"] += size
    print(f"\nDuplicates: {len(rows)} files, {dup_bytes / 1024**3:.2f} GiB")
    print(f"Saving: {100 * dup_bytes / total_bytes if total_bytes else 0:.1f}% of {total_bytes / 1024**3:.2f} GiB total")
    print(f"Same path in both accounts: {same}. Different path: {len(rows) - same}")
    print("Largest od2 folders with duplicates:")
    for folder, size in by_folder.most_common(15):
        print(f"  {size / 1024**3:8.2f} GiB  {folder}")


def build(ssd):
    od2 = walk(os.path.join(ssd, "od2"))
    with open(os.path.join(ssd, "duplicates.csv"), newline="", encoding="utf-8-sig") as f:
        skip = {r["skipped_from_od2"] for r in csv.DictReader(f) if r["skip_upload"].strip().upper() == "YES"}
    unmatched = skip - od2.keys()
    upload = sorted(od2.keys() - skip)
    with open(os.path.join(ssd, "od2-upload-list.txt"), "w", encoding="utf-8") as f:
        f.writelines(path + "\n" for path in upload)
    print(f"od2 files: {len(od2)}")
    print(f"Skipped as duplicates: {len(od2) - len(upload)}")
    print(f"To upload: {len(upload)}")
    if unmatched:
        print(f"WARNING: {len(unmatched)} CSV paths match no od2 file, so nothing is skipped for them.")
        print("The CSV may have been damaged by a spreadsheet app. Example:", next(iter(unmatched)))


if __name__ == "__main__":
    if len(sys.argv) != 3 or sys.argv[1] not in ("find", "build"):
        sys.exit(__doc__)
    {"find": find, "build": build}[sys.argv[1]](sys.argv[2])
EOF
```

Run it. This can take a few hours:

```bash
caffeinate -i python3 ~/onedrive_dupes.py find /Volumes/MigrationSSD
```

> **Warning:** Running `find` again overwrites `duplicates.csv`, including your review edits.

A file only counts as a duplicate if it passes all of these:

- **Same contents:** Its SHA-256 checksum matches, and a byte-by-byte comparison confirms it. Names and dates don't matter.
- **In both accounts:** Repeats within one account are left alone, unless they also match a file in the other account.
- **At least 1 MB:** Smaller files are always uploaded. They save little space and are often part of a project or set of documents.

---

## 9. Review the duplicate list

Open `/Volumes/MigrationSSD/duplicates.csv` in Numbers or Excel.

| Column | Meaning |
|---|---|
| `skip_upload` | `YES` skips the `od2` copy. `NO` uploads it anyway. |
| `size_mb` | File size in MiB. |
| `same_path` | `YES` if the file has the same folder and name in both accounts. |
| `kept_from_od1` | The copy that will be uploaded. |
| `skipped_from_od2` | The copy that will be skipped. |

To review it:

1. **Start with the script's summary:** It shows the total saving and which folders are affected.
2. **Sort by `same_path`:** `YES` rows are the same file in the same place, so they're usually safe to skip. Spend your time on the `NO` rows.
3. **Spot-check a few rows:** Open the largest files from both columns, plus a few from each major folder.
4. **Change your mind on any row:** Set `skip_upload` to `NO` and that file will be uploaded anyway.

Mistakes here are low risk, because a wrongly kept row only uploads an extra copy. The main downside of skipping is that some `OneDrive-Account2` folders will have gaps, because the skipped file exists only under `OneDrive-Account1`.

### Decide whether to skip duplicates

**Copy everything instead if any of these apply:**

- The saving is under about 10%.
- Most rows are `NO` for `same_path` and you can't easily judge them.
- Skipping would leave gaps in folders you want to keep complete.

If you're copying everything, go to step 10 and use **Option B**.

### Build the upload list

Save the file as CSV (in Excel, use **CSV UTF-8**), then run:

```bash
python3 ~/onedrive_dupes.py build /Volumes/MigrationSSD
```

If you see a `WARNING`, the spreadsheet app probably damaged some filenames. Those files will simply be uploaded, so no data is lost.

---

## 10. Upload to Google Drive

Each account gets its own folder, so files with the same name can't collide.

Google limits uploads to **750 GB per day**. If rclone stops at that limit, run the same command about 24 hours later to continue. Files already uploaded are skipped.

### Upload `od1`

```bash
caffeinate -i rclone copy /Volumes/MigrationSSD/od1 gdrive:OneDrive-Account1 --exclude .DS_Store --progress --drive-chunk-size 64M --drive-stop-on-upload-limit --log-file=/Volumes/MigrationSSD/logs/od1-upload.log --log-level INFO
```

### Upload `od2`

Use **one** of these options.

**Option A: Skip the reviewed duplicates**

```bash
caffeinate -i rclone copy /Volumes/MigrationSSD/od2 gdrive:OneDrive-Account2 --files-from-raw /Volumes/MigrationSSD/od2-upload-list.txt --progress --drive-chunk-size 64M --drive-stop-on-upload-limit --log-file=/Volumes/MigrationSSD/logs/od2-upload.log --log-level INFO
```

**Option B: Copy everything**

```bash
caffeinate -i rclone copy /Volumes/MigrationSSD/od2 gdrive:OneDrive-Account2 --exclude .DS_Store --progress --drive-chunk-size 64M --drive-stop-on-upload-limit --log-file=/Volumes/MigrationSSD/logs/od2-upload.log --log-level INFO
```

---

## 11. Verify Google Drive

### Check `od1`

```bash
rclone check /Volumes/MigrationSSD/od1 gdrive:OneDrive-Account1 --exclude .DS_Store --one-way --combined /Volumes/MigrationSSD/logs/od1-gdrive-check.txt
```

```bash
grep -v '^=' /Volumes/MigrationSSD/logs/od1-gdrive-check.txt
```

### Check `od2`

**If you used Option A:**

```bash
rclone check /Volumes/MigrationSSD/od2 gdrive:OneDrive-Account2 --files-from-raw /Volumes/MigrationSSD/od2-upload-list.txt --one-way --combined /Volumes/MigrationSSD/logs/od2-gdrive-check.txt
```

**If you used Option B:**

```bash
rclone check /Volumes/MigrationSSD/od2 gdrive:OneDrive-Account2 --exclude .DS_Store --one-way --combined /Volumes/MigrationSSD/logs/od2-gdrive-check.txt
```

**Then, for either option:**

```bash
grep -v '^=' /Volumes/MigrationSSD/logs/od2-gdrive-check.txt
```

No output means every file matched. If anything is listed, rerun the upload and check again.

### Save a record of skipped files

If you used Option A, save the list to Google Drive so you can always see where each skipped file went:

```bash
rclone copyto /Volumes/MigrationSSD/duplicates.csv gdrive:OneDrive-Account2-skipped-duplicates.csv
```

### Reading check results

| Symbol | Meaning | What to do |
|---|---|---|
| `=` | File matches | Nothing |
| `+` | Missing from the destination | Rerun the copy or upload |
| `*` | File differs | Rerun the copy or upload, then check again |
| `!` | Error while checking | Check the log, then run the check again |

---

## 12. Finish up

1. Open a sample of files from Google Drive in your browser, including older videos, large PDFs, and spreadsheets.
2. Compare file counts and sizes:

```bash
rclone size gdrive:OneDrive-Account1
```

```bash
rclone size gdrive:OneDrive-Account2
```

3. Keep both OneDrive accounts for at least 30 days, and check when any paid plan renews.
4. Keep the SSD as a backup, ideally permanently. It's your only full copy of the skipped files once OneDrive is closed.

Files uploaded to Google Drive won't automatically appear in Google Photos, and they count toward your storage either way.

---

## Troubleshooting

| Problem | What to do |
|---|---|
| The transfer stopped or the SSD disconnected | Reconnect the SSD, confirm it's mounted, and run the same command again. |
| `No such file or directory` for `/Volumes/MigrationSSD` | The SSD isn't mounted or has a different name. Repeat the checks in step 2. |
| `No space left on device` | Check `df -h /Volumes/MigrationSSD`. You'll need a larger drive or to transfer in batches. |
| Sign-in or token errors | Reconnect that account with `rclone config reconnect od1:`, using the remote that failed. |
| `403` or `rateLimitExceeded` from Google | rclone retries automatically, so let it run. If it stops, rerun the command later. |
| Very slow Google uploads | Many small files upload slowly, which is normal. You can also [create your own Google client ID](https://rclone.org/drive/#making-your-own-client-id). |
| Upload stops at the daily limit | Run the same command about 24 hours later. |
| The same Office or image files keep differing between OneDrive and the SSD | OneDrive may have altered their metadata. Open several from both places to confirm they're fine, and review the errors in the log. |
| `python3` opens an install prompt | Finish installing the Command Line Tools, then rerun the command. |
| `Operation not permitted` on the SSD | Allow Terminal under **System Settings → Privacy & Security → Files and Folders**, or under **Full Disk Access**. |
