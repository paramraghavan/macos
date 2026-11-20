<#
.SYNOPSIS
  Removes preinstalled trial software and bloat from a new Windows laptop (tuned for Acer).

  SAFE BY DEFAULT: with no options it only LISTS what it would remove. Nothing changes
  until you re-run it with -Apply, and even then it shows the list and asks "Remove these? (y/N)".

.HOW TO RUN  (Terminal (Admin), in this folder)
    Unblock-File .\remove-bloat.ps1
    Set-ExecutionPolicy -Scope Process Bypass -Force
    .\remove-bloat.ps1            # preview only
    .\remove-bloat.ps1 -Apply     # actually remove (asks once to confirm)

.OPTIONS
  -Apply         Actually remove (default is preview only)
  -IncludeXbox   Also remove Xbox apps. Note: this removes Xbox Game Bar (Win+G screen recording)
  -Yes           Skip the confirmation prompt (with -Apply)

.EDITING THE LIST
  Want to keep something (e.g. Spotify, Netflix)? Delete its line from $StoreApps / $DesktopApps below.
  Never add drivers or anything from Intel, Realtek, Dolby or Acer's control app (AcerSense / Care Center / Quick Access).
#>
param(
    [switch]$Apply,
    [switch]$IncludeXbox,
    [switch]$Yes
)

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------------ what to remove
# Microsoft Store (Appx) apps - wildcard patterns on the package name
$StoreApps = @(
    # Acer extras (NOT AcerSense / Care Center / Quick Access - those control battery & fans)
    "AcerIncorporated.AcerCollection*",
    "AcerIncorporated.AcerRegistration*",
    "AcerIncorporated.UserExperienceImprovementProgram*",
    "AcerIncorporated.AcerJumpstart*",
    "AcerIncorporated.PlanetNine*",
    # Third-party promos
    "*McAfee*",
    "*Norton*",
    "*ExpressVPN*",
    "*Booking*",
    "*CandyCrush*",
    "king.com.*",
    "*ForgeofEmpires*",
    "*WildTangent*",
    "*DropboxOEM*",
    "*AmazonAlexa*",
    "*Facebook*",
    "*Instagram*",
    "*TikTok*",
    "*Disney*",
    "*SpotifyAB.SpotifyMusic*",
    "*PrimeVideo*",
    # Microsoft extras most people never use
    "Clipchamp.Clipchamp",
    "Microsoft.BingNews",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",                     # "Tips"
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.People",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.MicrosoftOfficeHub",             # "Microsoft 365 (Office)" promo app, not Office itself
    "Microsoft.549981C3F5F10",                  # Cortana
    "MicrosoftTeams",                           # consumer Teams (personal); work Teams is separate
    "Microsoft.PowerAutomateDesktop",
    "Microsoft.MixedReality.Portal"
)
if ($IncludeXbox) {
    $StoreApps += "Microsoft.XboxApp", "Microsoft.GamingApp", "Microsoft.XboxGamingOverlay",
                  "Microsoft.XboxGameOverlay", "Microsoft.XboxIdentityProvider", "Microsoft.XboxSpeechToTextOverlay",
                  "Microsoft.Xbox.TCUI"
}

# Classic desktop programs - wildcard patterns on the name shown in "Installed apps"
$DesktopApps = @(
    "McAfee*",
    "Norton*",
    "ExpressVPN*",
    "Booking.com*",
    "Forge of Empires*",
    "WildTangent*",
    "Dropbox promotion*",
    "Acer Jumpstart*",
    "Acer Collection*",
    "Acer Product Registration*",
    "Acer Registration*",
    "Acer User Experience Improvement Program*"
)

# Safety net: never touch anything matching these, even if a pattern above would.
$Protected = "Intel|Realtek|Dolby|DTS|NVIDIA|AcerSense|Care ?Center|QuickAccess|Quick Access|PurifiedVoice|" +
             "DesktopAppInstaller|WindowsStore|StorePurchase|WindowsTerminal|Calculator|Photos|Notepad|" +
             "OneDrive|Edge|VCLibs|NET\.Native|UI\.Xaml|SecHealthUI|WindowsAppRuntime"

# ------------------------------------------------------------------ preflight
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
           IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { throw "Please run this from an Administrator terminal (Start -> Terminal (Admin))." }

# The Appx cmdlets are Windows PowerShell 5.1 modules; load them in compatibility mode on PowerShell 7.
if ($PSVersionTable.PSVersion.Major -ge 7) {
    Import-Module Appx -UseWindowsPowerShell -WarningAction SilentlyContinue
    Import-Module Dism -UseWindowsPowerShell -WarningAction SilentlyContinue
}

# ------------------------------------------------------------------ find matches
Write-Host "Scanning installed apps..." -ForegroundColor Cyan

$appx = Get-AppxPackage -AllUsers | Where-Object {
    $n = $_.Name
    ($StoreApps | Where-Object { $n -like $_ }) -and ($n -notmatch $Protected)
} | Sort-Object Name -Unique

$provisioned = Get-AppxProvisionedPackage -Online | Where-Object {
    $n = $_.DisplayName
    ($StoreApps | Where-Object { $n -like $_ }) -and ($n -notmatch $Protected)
}

$uninstallKeys = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
                 "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
                 "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
$desktop = Get-ItemProperty $uninstallKeys -ErrorAction SilentlyContinue | Where-Object {
    $n = $_.DisplayName
    $n -and ($DesktopApps | Where-Object { $n -like $_ }) -and ($n -notmatch $Protected)
} | Sort-Object DisplayName -Unique

# ------------------------------------------------------------------ report
if (-not $appx -and -not $desktop -and -not $provisioned) {
    Write-Host "Nothing on the list is installed. Already clean." -ForegroundColor Green
    return
}

Write-Host "`nStore apps that would be removed:" -ForegroundColor Yellow
if ($appx) { $appx | ForEach-Object { Write-Host "  - $($_.Name)" } } else { Write-Host "  (none)" }

Write-Host "`nDesktop programs that would be uninstalled:" -ForegroundColor Yellow
if ($desktop) { $desktop | ForEach-Object { Write-Host "  - $($_.DisplayName)" } } else { Write-Host "  (none)" }

if ($provisioned) {
    Write-Host "`n(Also stops $(@($provisioned).Count) of these from being reinstalled for new user accounts.)"
}

if (-not $Apply) {
    Write-Host "`nPreview only - nothing was changed. Re-run with -Apply to remove." -ForegroundColor Cyan
    return
}

if (-not $Yes) {
    $answer = Read-Host "`nRemove these? (y/N)"
    if ($answer -notmatch '^(y|yes)$') { Write-Host "Cancelled. Nothing changed."; return }
}

# ------------------------------------------------------------------ restore point
Write-Host "`nCreating a restore point (so you can roll back)..." -ForegroundColor Cyan
try {
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
    Checkpoint-Computer -Description "Before remove-bloat.ps1" -RestorePointType MODIFY_SETTINGS
    Write-Host "  restore point created"
} catch {
    Write-Warning "  couldn't create a restore point ($($_.Exception.Message)). Windows allows one every 24h."
}

# ------------------------------------------------------------------ remove
$failed = @()

foreach ($p in $appx) {
    Write-Host "-> removing $($p.Name)"
    try { Remove-AppxPackage -Package $p.PackageFullName -AllUsers -ErrorAction Stop }
    catch { $failed += $p.Name; Write-Warning "   $($_.Exception.Message)" }
}

foreach ($p in $provisioned) {
    try { Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName -ErrorAction Stop | Out-Null }
    catch { Write-Warning "   couldn't de-provision $($p.DisplayName)" }
}

foreach ($d in $desktop) {
    Write-Host "-> uninstalling $($d.DisplayName)"
    winget uninstall --name "$($d.DisplayName)" --exact --silent --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        $failed += $d.DisplayName
        Write-Warning "   winget couldn't uninstall it silently. Remove it from Settings -> Apps -> Installed apps."
    }
}

# ------------------------------------------------------------------ done
Write-Host "`nDone." -ForegroundColor Green
if ($failed) {
    Write-Host "These need removing by hand (Settings -> Apps -> Installed apps):" -ForegroundColor Yellow
    $failed | Sort-Object -Unique | ForEach-Object { Write-Host "  - $_" }
}
Write-Host "Restart the laptop to finish. Changed your mind? Reinstall any app from the Microsoft Store,"
Write-Host "or roll back with Start -> 'Create a restore point' -> System Restore."
