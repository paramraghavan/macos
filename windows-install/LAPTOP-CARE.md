# Acer Aspire Go 15: performance and long-life guide

**Machine:** Acer Aspire Go 15.6", Intel Core i7-13620H (10 cores: 6 performance + 4 efficiency, 16 threads), 16 GB DDR5, 512 GB SSD, Intel integrated graphics.

The i7-13620H is a 45 W "H" chip, which is fast but runs hot in a thin budget chassis. Most of the advice below comes down to keeping it **updated, cool, uncluttered**, and keeping the battery away from 100% when you don't need it.

---

## 1. First day (do once, before or right after `setup-windows.ps1`)

1. **Plug in the charger** for everything in this section.
2. **Windows Update, all of it.** Settings → Windows Update → *Check for updates*. Then go to *Advanced options → Optional updates* and install any driver updates listed there. Restart and repeat until nothing is left.
3. **Acer drivers and BIOS.** On acer.com → Support, enter the serial number (on the sticker underneath, or run `(Get-CimInstance Win32_BIOS).SerialNumber` in PowerShell). Install the latest **BIOS**, chipset, Intel graphics and Wi-Fi drivers listed for *your* model.
   - Only update the BIOS while plugged in, and never interrupt it.
4. **Intel Driver & Support Assistant** keeps Intel graphics, Wi-Fi and Bluetooth drivers current:

   ```powershell
   winget install --id Intel.IntelDriverAndSupportAssistant -e
   ```

5. **Remove trial software and bloat.** The quick way is [`remove-bloat.ps1`](remove-bloat.ps1) (see [section 4](#4-removing-bloat-with-remove-bloatps1)). To do it by hand: Settings → Apps → Installed apps. Uninstall:
   - antivirus trials (McAfee, Norton). Microsoft Defender is built in and enough (see [section 5](#5-security-microsoft-defender)).
   - games, Booking.com, Dropbox promos, and anything else you don't recognise as useful.

   Keep anything from **Intel**, **Realtek**, and Acer's own control app (**AcerSense** or **Acer Care Center**, whichever came preinstalled). It controls the battery limit and fan modes.
6. **Startup apps.** Settings → Apps → Startup. Turn off everything you don't need at boot. Fewer startup apps means a faster boot and more free RAM.
7. **Device encryption / BitLocker.** Settings → Privacy & security → Device encryption should be **On**. Make sure the recovery key is saved to your Microsoft account (account.microsoft.com/devices/recoverykey). If you ever lose it, you lose the disk.
8. **Restore point.** Search Start for "Create a restore point" → select C: → *Configure* → *Turn on system protection* (about 5% of the disk) → *Create*. Now you can roll back a bad driver.

---

## 2. Performance settings

| Setting | Where | Recommended |
|---|---|---|
| Power mode, plugged in | Settings → System → Power & battery → Power mode | **Best performance** |
| Power mode, on battery | same | **Balanced** (or Best power efficiency for long trips) |
| Acer fan/performance mode | AcerSense / Acer Care Center | **Performance** when plugged in for heavy work (Spark jobs, builds); **Balanced/Quiet** otherwise |
| Graphics | Settings → System → Display → Graphics | Default is fine (integrated GPU only) |
| Visual effects | Start → "Adjust the appearance and performance of Windows" | Optional: *Adjust for best performance*, then re-tick "Smooth edges of screen fonts" |
| Chrome memory | Chrome → Settings → Performance | **Memory Saver: On** |

**Run heavy work plugged in.** On battery the CPU is power-limited and can be half as fast.

### Getting the most from 16 GB of RAM with PySpark

16 GB is fine for local Spark if Chrome, VS Code and Spark aren't all fighting over it.

- Check how full memory is: Task Manager (Ctrl+Shift+Esc) → Performance → Memory. If it often sits above 85%, close tabs/apps or give Spark less.
- Also on that screen: *Slots used* tells you whether the RAM is upgradeable. On many thin laptops it's soldered. If a slot is free, a matching second stick (dual-channel) is the single biggest upgrade.
- Size Spark for a laptop (local mode's default of 200 shuffle partitions is built for clusters):

  ```python
  from pyspark.sql import SparkSession

  spark = (SparkSession.builder
           .master("local[*]")                          # all 16 threads
           .config("spark.driver.memory", "6g")         # leave ~10 GB for Windows + apps
           .config("spark.sql.shuffle.partitions", "16")
           .getOrCreate())
  ```

  `spark.driver.memory` only takes effect if it's set before the first SparkSession in that Python process. Restart the kernel/terminal after changing it.
- Leave the Windows page file on *System managed*. Don't disable it.

### Faster dev folder (optional)

- **Dev Drive** (Windows 11): Settings → System → Storage → Advanced storage settings → Disks & volumes → *Create dev drive*. It's a ReFS volume tuned for code, with a lighter antivirus scan mode. It needs at least 50 GB. Good home for `code\`, but on a 512 GB disk, size it carefully.
- **Defender folder exclusion** (alternative): excluding your `code` folder from real-time scanning makes `git`, `pip` and builds noticeably faster. The trade-off is that malware in that folder wouldn't be caught. If you want it, in **Admin** PowerShell:

  ```powershell
  Add-MpPreference -ExclusionPath "$HOME\code"
  ```

  Only exclude folders that hold your own code, never Downloads.

---

## 3. Battery: long life and on the move

Lithium batteries wear fastest when they're **full, hot, or empty**.

1. **Set a charge limit of 80%.** Open AcerSense / Acer Care Center → Battery → turn on *Battery Charge Limit* (Acer's limit is 80%). If you mostly work at a desk plugged in, this is the most important setting on this page.
   - Turn it off the night before a day you need the full battery.
2. **Don't run it down to 0%** regularly. Charge when it reaches 20 to 30%.
3. **Heat is the enemy.** Don't charge it on a bed, sofa or in a hot car.
4. **Long storage** (weeks unused): leave it at about 50%, powered off.
5. **Check battery health** every few months. In PowerShell:

   ```powershell
   powercfg /batteryreport /output "$HOME\battery-report.html"
   start "$HOME\battery-report.html"
   ```

   Compare **Full charge capacity** to **Design capacity**. Losing about 5 to 10% a year is normal.

### On the move: getting the most hours from one charge

Roughly in order of how much battery each one saves:

1. **Start at 100%.** The night before, turn *off* the 80% charge limit in AcerSense / Acer Care Center and charge fully. Turn the limit back on when you're home.
2. **Screen brightness** is the biggest single drain. Use about 40 to 50% indoors (Fn + brightness keys, or Win+A → slider). Dark mode helps a little: Settings → Personalization → Colors → *Dark*.
3. **Power mode → Best power efficiency.** Settings → System → Power & battery → Power mode → *When on battery* → **Best power efficiency**. In AcerSense / Care Center, choose the **Quiet/Eco** fan mode.
4. **Energy saver.** Same page → *Energy saver* → set *Turn energy saver on automatically* to **30%**, or switch it on right away for a long day. It dims the screen and pauses background activity, including OneDrive sync.
5. **Close the heavy stuff.** Stop Spark sessions, Jupyter kernels and anything else running Java or Python in the background. Check Task Manager → Processes, sorted by **CPU** and **Power usage**.
6. **Browser.** Chrome → Settings → Performance → **Energy saver: On** (choose *when unplugged*). Fewer open tabs is better; one YouTube tab can cost an hour.
7. **Radios.** Turn **Bluetooth off** when you don't use it (Win+A). Working offline? Use **Airplane mode**; you can turn Wi-Fi back on inside Airplane mode if you need it.
8. **Unplug USB devices** you aren't using (mouse dongles, drives, phones charging from the laptop).
9. **Background apps.** Settings → System → Power & battery → **Battery usage** shows what's been draining it. For anything you don't need running: Settings → Apps → Installed apps → ⋯ → Advanced options → *Background apps permissions* → **Never**.
10. **Keyboard backlight off** (if the model has one: Fn + the key with the keyboard/light icon).
11. **Short timeouts.** Settings → System → Power & battery → *Screen, sleep & hibernate timeouts*: on battery, screen off after **2 to 3 min**, sleep after **5 to 10 min**.
12. **Hibernate for long breaks.** Sleep still uses battery; hibernate uses none. Enable it in **Admin** PowerShell with `powercfg /hibernate on`. Then add it to the power menu: Control Panel → Power Options → *Choose what the power buttons do* → *Change settings that are currently unavailable* → tick **Hibernate**.
13. **Carry the charger, or check USB-C charging.** If a USB-C port on your laptop shows a charging/power symbol (or the manual says it supports USB-C Power Delivery), a small 65 W USB-C charger or power bank can top it up. Otherwise bring the Acer charger.

**Before you leave, quick checklist:** charged to 100% · power mode *Best power efficiency* · brightness about 50% · Bluetooth off · Spark/Jupyter closed · Chrome energy saver on.

---

## 4. Removing bloat with `remove-bloat.ps1`

New Acer laptops come with trial antivirus, games and promo apps that use disk space, RAM, battery and pop-ups. [`remove-bloat.ps1`](remove-bloat.ps1) removes them. **It's safe by default:** with no options it only *shows* what it would remove.

In **Terminal (Admin)**, in this folder:

```powershell
Unblock-File .\remove-bloat.ps1
Set-ExecutionPolicy -Scope Process Bypass -Force
.\remove-bloat.ps1            # 1. preview: lists what it would remove, changes nothing
.\remove-bloat.ps1 -Apply     # 2. remove: shows the list again and asks "Remove these? (y/N)"
```

What it does with `-Apply`:
- Creates a **restore point** first, so you can roll everything back.
- Removes **Store apps** on its list: Acer extras (Acer Collection, Registration, Jumpstart, the user-experience program), McAfee/Norton trials, ExpressVPN, Booking.com, games like Candy Crush, social/streaming promos, plus Microsoft extras like Clipchamp, Tips, Solitaire, Feedback Hub, Cortana and consumer Teams.
- Uninstalls **desktop programs** on its list (McAfee, Norton, ExpressVPN, Acer Jumpstart, etc.) with winget. Anything that can't be removed silently is listed at the end for you to remove from Settings → Apps.
- Stops those Store apps from being reinstalled for new user accounts.

What it **never** touches: drivers, Intel/Realtek/Dolby software, **AcerSense / Acer Care Center / Quick Access** (they control the battery limit and fans), Microsoft Store, winget, Edge, OneDrive, Photos, Calculator, Notepad, Terminal, Windows Security.

Options:
- `-IncludeXbox` also removes the Xbox apps. Note that this removes Xbox Game Bar (Win+G), which some people use for screen recording.
- `-Yes` skips the confirmation (with `-Apply`).

**Want to keep something on the list** (for example Spotify or Prime Video)? Open the script in VS Code and delete that line from `$StoreApps` or `$DesktopApps`. Removed something you wanted? Reinstall it from the Microsoft Store, or use System Restore.

---

## 5. Security: Microsoft Defender

**Use the built-in Microsoft Defender as your antivirus. Don't buy or install another one.** It's free, already installed, updated daily, and scores near the top of independent tests. Once the McAfee/Norton trial is removed, Defender switches itself back on automatically.

Open source? The open-source options (**ClamAV**, and **ClamWin**, a Windows app built on it) have **no real-time protection** on Windows: they only find threats when you run a scan, and they detect less. They're fine as an occasional second opinion on a suspicious download (`winget search clamav`), alongside Defender, never instead of it. Never run two *real-time* antivirus programs; they conflict and slow the laptop down.

### One-time setup

Open **Windows Security** (Start → "Windows Security") and check:

| Where | Setting | Should be |
|---|---|---|
| Virus & threat protection → *Manage settings* | Real-time protection | **On** |
| same | Cloud-delivered protection | **On** |
| same | Automatic sample submission | **On** (or *Prompt* if you prefer) |
| same | Tamper protection (stops malware from switching Defender off) | **On** |
| App & browser control → *Reputation-based protection settings* | Potentially unwanted app blocking (adware, bundled junk), tick *Block apps* and *Block downloads* | **On** |
| same | Check apps and files / SmartScreen for Microsoft Edge | **On** |
| Device security → *Core isolation details* | Memory integrity | **On** |
| Firewall & network protection | Domain, Private and Public networks | all **On** |

Quick check from PowerShell (no admin needed):

```powershell
Get-MpComputerStatus | Select-Object AntivirusEnabled, RealTimeProtectionEnabled, IsTamperProtected, AntivirusSignatureLastUpdated
```

All three should say `True`, and the signature date should be today or yesterday.

**Turning on potentially-unwanted-app blocking from PowerShell** (Admin), if you'd rather not click through:

```powershell
Set-MpPreference -PUAProtection Enabled
```

### Scans

- **Quick scans run automatically.** You don't need to schedule anything.
- **Monthly: Microsoft Defender Offline scan.** Windows Security → Virus & threat protection → *Scan options* → **Microsoft Defender Offline scan** → *Scan now*. The laptop restarts and scans for about 15 minutes before Windows loads, which catches malware that hides while Windows is running. Save your work first.
- **Scan a single file or folder:** right-click it → *Show more options* → **Scan with Microsoft Defender**.

### Developer note

Real-time scanning slows down `git`, `pip` and Spark on lots of small files. The two fixes, a **Dev Drive** or a **folder exclusion** for `code\`, are in [section 2](#faster-dev-folder-optional). Never exclude Downloads.

### Good habits (they matter more than any antivirus)

- Install software with **winget** or from official sites, not from download-aggregator sites or ads.
- Keep **Windows Update** and **`winget upgrade --all`** current; most attacks use old, already-fixed bugs.
- Use a **password manager** and turn on **two-factor authentication** for your Microsoft, Google and GitHub accounts.
- Be suspicious of email attachments and "your account is locked" links, even from familiar names.

---

## 6. Heat and physical care

An H-series CPU in a thin chassis will throttle (slow itself down) when hot.

- Use it on a **hard, flat surface**. The air intake is underneath, so beds, laps and blankets choke it.
- A **laptop stand** or anything that raises the back 1 to 2 cm noticeably lowers temperatures and makes typing more comfortable.
- **Clean the vents** every 6 to 12 months: short bursts of compressed air into the vents with the laptop **off**. Hold the fan still with a toothpick so it doesn't over-spin.
- Close the lid gently from the middle, not a corner, to protect the hinge and screen.
- Wipe the screen with a dry microfibre cloth; no household glass cleaner.
- Don't carry it in a bag with a water bottle or heavy items pressing on the lid.

Want to see if it's throttling? Task Manager → Performance → CPU: if *Speed* drops well below about 3 GHz during a long job while plugged in, it's probably heat. Clean the vents, raise the back, and set Acer's fan mode to Performance.

---

## 7. Storage: keep the 512 GB SSD healthy

- **Keep at least 15 to 20% free** (about 80 to 100 GB). SSDs slow down and wear faster when nearly full.
- **Storage Sense:** Settings → System → Storage → turn on *Storage Sense*, so it empties temp files and the Recycle Bin automatically.
- See what's big: Settings → System → Storage → *Show more categories*. Usual suspects for this setup: the repos, `pyspark-env`, `pip` cache (`py -m pip cache purge`), Downloads, and Spark temp folders in `%TEMP%`.
- **Don't defragment the SSD.** Windows' *Optimize Drives* already does the right thing (TRIM) on a schedule. Leave it on.
- Optional SSD health check: `winget install --id CrystalDewWorld.CrystalDiskInfo -e`. "Good" plus the health % is what matters.

---

## 8. Backups

- **OneDrive:** Settings → Accounts → Windows backup → OneDrive folder syncing. Back up Desktop, Documents and Pictures.
- **Code:** GitHub is the backup. Commit and push regularly. Keep `code\` *outside* OneDrive (see the README).
- **Windows backup:** Settings → Accounts → Windows backup → *Back up now*. This saves your settings and app list to your Microsoft account, which makes a reinstall or new laptop much faster.

---

## 9. Routine checklist

**Weekly**
- [ ] Restart (don't just sleep). It clears memory and finishes updates.
- [ ] Push your code to GitHub.

**Monthly**
- [ ] Windows Update, including *Optional updates*.
- [ ] `winget upgrade --all` to update Chrome, VS Code, Git, Python and everything else installed by winget.
- [ ] Check free disk space (keep 15 to 20% free).
- [ ] Run a **Microsoft Defender Offline scan**, and confirm protection is on (Windows Security shows green ticks).

**Every 6 to 12 months**
- [ ] Check the Acer support page for a BIOS update.
- [ ] Clean the vents with compressed air.
- [ ] Run the battery report and compare with last time.
