
# Recommended 2TB SSDs for Backup (Reliable and Cross-Platform)
- Samsung Portable SSD T7 Shield (2TB): Very reliable, portable, with IP65 rating (water and dust resistant). Supports Windows and macOS natively and offers hardware-based encryption. Popular for its speed and durability.[1][2][3]
- **Crucial X9 Pro (2TB)**: Fast, reliable external USB-C SSD. Works well on macOS, Windows, and Linux. Comes with data recovery service and strong encryption.[2][4]
- SanDisk Professional G-Drive SSD: Rugged and fast, compatible with multiple platforms including Windows and macOS. Offers Thunderbolt 3 and USB-C connections.[5]
- WD My Passport SSD (2TB or 4TB): Reliable, affordable, cross-platform, with encryption and good speed. Works seamlessly with both macOS and Windows.[3][4]

## Steps to Back Up Selected OneDrive Folders on macOS
1. Install the standalone Microsoft OneDrive sync app (not from Mac App Store). Download from Microsoft’s official site to avoid issues.
2. Open OneDrive and sign in.
3. To back up important folders (like Desktop, Documents), click the OneDrive cloud icon in the menu bar → then the three dots → Preferences → Backup tab → Manage Backup.
4. Select the folders you want to back up. OneDrive will sync these folders locally and to the cloud.
5. For additional local backup, connect your external SSD.
6. Use Finder to manually copy or create Time Machine backups of the OneDrive folder or the selected folders to the external SSD.
7. Format the SSD to exFAT for cross-platform compatibility (both macOS and Windows can read/write exFAT). Use Disk Utility → Erase → choose exFAT.

## Notes on Cross-Platform Usage
- Formatting as exFAT is recommended so you can use the SSD both on Windows and macOS without issues.
- Do not format as APFS if you plan to use on Windows, as Windows doesn't support APFS natively without third-party software.
- Regularly check backup integrity; keep backup copies on different drives/media for safety.

This setup ensures your OneDrive folders are backed up locally on your Mac and the backup is safe on a reliable 2TB SSD usable on both Windows and macOS.

Here are detailed steps for formatting your 2TB SSD for cross-platform use (macOS and Windows) and backing up selected OneDrive folders on macOS:

## Formatting SSD to exFAT for Cross-Platform Use
1. Connect your SSD to the Mac.
2. Open **Disk Utility** (Finder → Applications → Utilities → Disk Utility).
3. In the sidebar, select your external SSD.
4. Click the **Erase** button at the top.
5. Set the following:
   - **Name:** Give a meaningful name to your drive.
   - **Format:** Choose **exFAT** (compatible with macOS and Windows).
   - **Scheme:** Choose **GUID Partition Map**.
6. Click **Erase** and wait for the process to complete.
7. Eject and reconnect the drive to confirm it mounts correctly.

This formatting ensures you can read/write the drive on both macOS and Windows without additional drivers.

## Backing Up Selected OneDrive Folders on macOS
1. Make sure the Microsoft OneDrive app is installed and signed in on your Mac.
2. Click the **OneDrive cloud icon** in the Mac menu bar.
3. Open **OneDrive Preferences** by clicking the three dots and choosing Preferences.
4. Go to the **Backup** tab and click **Manage Backup**.
5. Select folders like **Desktop**, **Documents**, and **Pictures** that you want OneDrive to back up and sync.
6. OneDrive will sync these selected folders automatically with your OneDrive in the cloud.
7. To create an additional local backup on your SSD:
   - Open **Finder** and navigate to your OneDrive folder (usually under your user directory).
   - Select the folders you want backed up locally.
   - Copy them to your external SSD by dragging or using copy-paste commands.
8. Optionally, to automate local backups, you can use macOS features like **Time Machine** (set your external SSD as a backup drive) or third-party backup tools to schedule backups of your OneDrive folder to the SSD.
