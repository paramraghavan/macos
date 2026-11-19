<#
.SYNOPSIS
  New Windows machine setup:
    - Google Chrome, VS Code, OneDrive, Git + Git Bash (VS Code's default terminal), GitHub CLI, Python 3.12, Java 17 (Temurin)
    - Clones (or updates) every repo for a GitHub account, private ones included
    - PySpark in a virtualenv, with winutils/HADOOP_HOME so Spark can write files on Windows

.HOW TO RUN
  1. Right-click Start -> "Terminal (Admin)"
  2. cd to the folder holding this file, then:
       Unblock-File .\setup-windows.ps1
       Set-ExecutionPolicy -Scope Process Bypass -Force
       .\setup-windows.ps1
  It is safe to re-run: installed apps are skipped and existing repos are pulled.

.OPTIONS
  -GitHubUser paramraghavan   GitHub account whose repos to clone
  -CodeDir    "$HOME\code"    Where repos and the PySpark venv go
  -SkipRepos                  Don't clone repos
  -SkipPySpark                Don't set up PySpark
  -SkipWinutils               Don't download winutils.exe/hadoop.dll (third-party binaries)
#>
param(
    [string]$GitHubUser = "paramraghavan",
    [string]$CodeDir    = "$HOME\code",
    [switch]$SkipRepos,
    [switch]$SkipPySpark,
    [switch]$SkipWinutils
)

$ErrorActionPreference = "Stop"
$ProgressPreference    = "SilentlyContinue"   # makes Invoke-WebRequest much faster

New-Item -ItemType Directory -Force -Path $CodeDir | Out-Null
Start-Transcript -Path "$CodeDir\setup-windows.log" -Append | Out-Null

function Step($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }

function Update-Path {
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [Environment]::GetEnvironmentVariable("Path", "User")
}

function Install-App([string]$Id) {
    Write-Host "-> $Id"
    winget list --id $Id -e --accept-source-agreements *> $null
    if ($LASTEXITCODE -eq 0) { Write-Host "   already installed"; return }
    winget install --id $Id -e --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { Write-Warning "   winget returned $LASTEXITCODE for $Id" }
}

# ---------------------------------------------------------------- preflight
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
           IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { throw "Please run this from an Administrator terminal (Start -> Terminal (Admin))." }

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget not found. Install 'App Installer' from the Microsoft Store, then re-run."
}

# ---------------------------------------------------------------- apps
Step "Installing apps"
$apps = @(
    "Google.Chrome",
    "Microsoft.VisualStudioCode",
    "Microsoft.OneDrive",              # usually preinstalled on Windows 11; skipped if so
    "Git.Git",                         # Git for Windows - includes Git Bash
    "GitHub.cli",
    "Python.Python.3.12",
    "EclipseAdoptium.Temurin.17.JDK"   # Spark needs Java
)
foreach ($a in $apps) { Install-App $a }
Update-Path

# VS Code extensions (Python + Jupyter)
$code = Get-Command code -ErrorAction SilentlyContinue
if (-not $code) { $code = Get-Item "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd" -ErrorAction SilentlyContinue }
if ($code) {
    foreach ($ext in "ms-python.python", "ms-toolsai.jupyter") {
        & $code.Source --install-extension $ext --force | Out-Null
    }
}

# ---------------------------------------------------------------- git bash
Step "Git Bash"
$gitBash = "C:\Program Files\Git\bin\bash.exe"
if (Test-Path $gitBash) {
    Write-Host "Git Bash: $gitBash  (Start menu -> 'Git Bash', or right-click a folder -> 'Open Git Bash here')"

    # Make Git Bash the default terminal inside VS Code
    $vsSettings = "$env:APPDATA\Code\User\settings.json"
    New-Item -ItemType Directory -Force -Path (Split-Path $vsSettings) | Out-Null
    $settings = $null
    if (Test-Path $vsSettings) {
        try { $settings = Get-Content $vsSettings -Raw | ConvertFrom-Json } catch { $settings = $null }
        if (-not $settings) { Write-Warning "Couldn't parse $vsSettings - set the VS Code default terminal to Git Bash by hand." }
    } else {
        $settings = [pscustomobject]@{}
    }
    if ($settings) {
        $settings | Add-Member -NotePropertyName "terminal.integrated.defaultProfile.windows" -NotePropertyValue "Git Bash" -Force
        [IO.File]::WriteAllText($vsSettings, ($settings | ConvertTo-Json -Depth 20))   # UTF-8, no BOM
        Write-Host "VS Code default terminal -> Git Bash"
    }
} else {
    Write-Warning "Git Bash not found at $gitBash - did Git.Git install?"
}

# ---------------------------------------------------------------- git identity
Step "Git config"
if (-not (git config --global user.name))  { git config --global user.name  (Read-Host "Git user.name (your full name)") }
if (-not (git config --global user.email)) { git config --global user.email (Read-Host "Git user.email") }
git config --global init.defaultBranch main

# ---------------------------------------------------------------- repos
if (-not $SkipRepos) {
    Step "Cloning GitHub repos for $GitHubUser"
    gh auth status *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "A browser will open - sign in to GitHub and paste the one-time code shown here."
        gh auth login --hostname github.com --git-protocol https --web
    }
    gh auth setup-git   # lets plain `git pull/push` use the gh login (needed for private repos)

    $repoDir = Join-Path $CodeDir "github"
    New-Item -ItemType Directory -Force -Path $repoDir | Out-Null

    # When you're logged in as this user, the list includes private repos.
    $names = gh repo list $GitHubUser --limit 1000 --json name --jq ".[].name"
    Write-Host "Found $(@($names).Count) repos"

    foreach ($name in $names) {
        $path = Join-Path $repoDir $name
        if (Test-Path (Join-Path $path ".git")) {
            Write-Host "-> pull  $name"
            git -C $path pull --ff-only
        } else {
            Write-Host "-> clone $name"
            gh repo clone "$GitHubUser/$name" $path
        }
        if ($LASTEXITCODE -ne 0) { Write-Warning "   problem with $name (continuing)" }
    }
}

# ---------------------------------------------------------------- pyspark
if (-not $SkipPySpark) {
    Step "Java"
    $jdk = Get-ChildItem "C:\Program Files\Eclipse Adoptium" -Directory -Filter "jdk-17*" -ErrorAction SilentlyContinue |
           Sort-Object Name -Descending | Select-Object -First 1
    if (-not $jdk) { throw "Java 17 not found under C:\Program Files\Eclipse Adoptium" }
    [Environment]::SetEnvironmentVariable("JAVA_HOME", $jdk.FullName, "User")
    $env:JAVA_HOME = $jdk.FullName
    $env:Path = "$($jdk.FullName)\bin;$env:Path"
    Write-Host "JAVA_HOME = $($jdk.FullName)"

    if (-not $SkipWinutils) {
        Step "winutils / HADOOP_HOME (needed for df.write on Windows)"
        $hadoop = "C:\hadoop"
        New-Item -ItemType Directory -Force -Path "$hadoop\bin" | Out-Null
        $base = "https://raw.githubusercontent.com/cdarlint/winutils/master/hadoop-3.3.6/bin"
        try {
            foreach ($f in "winutils.exe", "hadoop.dll") {
                Invoke-WebRequest "$base/$f" -OutFile "$hadoop\bin\$f"
            }
            [Environment]::SetEnvironmentVariable("HADOOP_HOME", $hadoop, "User")
            $env:HADOOP_HOME = $hadoop
            $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
            if ($userPath -notlike "*$hadoop\bin*") {
                [Environment]::SetEnvironmentVariable("Path", "$userPath;$hadoop\bin", "User")
            }
            $env:Path = "$hadoop\bin;$env:Path"
        } catch {
            Write-Warning "winutils download failed: $_  (Spark will run, but writing files may fail)"
        }
    }

    Step "Python venv + PySpark"
    $venv = Join-Path $CodeDir "pyspark-env"
    if (-not (Test-Path "$venv\Scripts\python.exe")) {
        if (Get-Command py -ErrorAction SilentlyContinue) { py -3.12 -m venv $venv }
        else { python -m venv $venv }
    }
    $py = "$venv\Scripts\python.exe"
    & $py -m pip install --upgrade pip
    & $py -m pip install "pyspark>=3.5,<3.6" jupyter pandas pyarrow
    [Environment]::SetEnvironmentVariable("PYSPARK_PYTHON", $py, "User")
    $env:PYSPARK_PYTHON = $py

    Step "PySpark smoke test"
    $test = Join-Path $CodeDir "pyspark_smoke_test.py"
    @'
from pyspark.sql import SparkSession
import os, tempfile

spark = SparkSession.builder.master("local[*]").appName("smoke").getOrCreate()
df = spark.createDataFrame([(1, "a"), (2, "b"), (3, "c")], ["id", "val"])
df.show()
out = os.path.join(tempfile.gettempdir(), "pyspark_smoke.parquet")
df.write.mode("overwrite").parquet(out)
print("wrote + read back", spark.read.parquet(out).count(), "rows")
print("Spark", spark.version, "OK")
spark.stop()
'@ | Set-Content -Path $test -Encoding UTF8
    & $py $test
}

# ---------------------------------------------------------------- done
Step "Done"
Write-Host "Repos:        $CodeDir\github"
Write-Host "PySpark venv: $CodeDir\pyspark-env   (activate: $CodeDir\pyspark-env\Scripts\Activate.ps1)"
Write-Host "Log:          $CodeDir\setup-windows.log"
Write-Host "Open a NEW terminal so JAVA_HOME / HADOOP_HOME / PATH changes take effect."
Stop-Transcript | Out-Null
