# Radiant Installation Script for Windows
# Rady @ UCSD - Automated installer for R, RStudio, and Radiant packages on Windows

# Require Administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges. Restarting as Administrator..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "Rady @ UCSD Radiant Installer for Windows" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Set error action preference
$ErrorActionPreference = "Stop"

# Create temp directory
$TEMP_DIR = New-TemporaryFile | %{ rm $_; mkdir $_ }
Set-Location $TEMP_DIR
Write-Host "📁 Working in temporary directory: $TEMP_DIR" -ForegroundColor Gray
Write-Host ""

# Function to check success
function Check-Success {
    param($Message)
    if ($LASTEXITCODE -eq 0 -or $?) {
        Write-Host "✅ $Message successful" -ForegroundColor Green
    } else {
        Write-Host "❌ $Message failed" -ForegroundColor Red
        exit 1
    }
}

# Get system drive (usually C:)
$SystemDrive = $env:SystemDrive

# Check and Install R
Write-Host "🔧 Step 1: Checking R installation..." -ForegroundColor Yellow

# Get current R version if installed
$CurrentRVersion = $null
$RPath = "$SystemDrive\R\R-*\bin\R.exe"
$RInProgramFiles = $false

# Check if R is in Program Files (bad location)
if (Test-Path "$env:ProgramFiles\R\R-*\bin\R.exe") {
    $RInProgramFiles = $true
    Write-Host "⚠️  R is installed in Program Files - this can cause problems!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   R works best when installed in $SystemDrive\R instead of Program Files." -ForegroundColor Gray
    Write-Host "   This avoids permission issues with package installation." -ForegroundColor Gray
    Write-Host ""
    
    # Ask about R experience
    $response = ""
    while ($response -notmatch "^[YyNn]$") {
        $response = Read-Host "   Have you used R successfully from this location before? (Y/N)"
    }
    
    if ($response -match "^[Yy]$") {
        Write-Host "   Proceeding with existing R installation..." -ForegroundColor Gray
        $RInProgramFiles = $false  # User says it works, so don't force reinstall
        
        # Try to get version from Program Files location
        $RProgramFilesPath = Get-ChildItem "$env:ProgramFiles\R\R-*\bin\R.exe" | Select-Object -First 1
        if ($RProgramFilesPath) {
            $VersionOutput = & $RProgramFilesPath.FullName --version 2>&1
            if ($VersionOutput -match "R version (\d+\.\d+\.\d+)") {
                $CurrentRVersion = $matches[1]
                Write-Host "   Current R version: $CurrentRVersion (in Program Files)" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "   R should be reinstalled in $SystemDrive\R for best results" -ForegroundColor Yellow
    }
}

# Check for R in correct location
if (Test-Path $RPath) {
    $RExe = Get-ChildItem $RPath | Select-Object -First 1
    if ($RExe) {
        $VersionOutput = & $RExe.FullName --version 2>&1
        if ($VersionOutput -match "R version (\d+\.\d+\.\d+)") {
            $CurrentRVersion = $matches[1]
            Write-Host "   Current R version: $CurrentRVersion (in $SystemDrive\R)" -ForegroundColor Gray
        }
    }
}

# Get latest R version from CRAN
Write-Host "   Checking latest R version from CRAN..." -ForegroundColor Gray
$ReleasePage = Invoke-WebRequest -Uri "https://cloud.r-project.org/bin/windows/base/release.html" -UseBasicParsing
$RURL = $null
$LatestRVersion = $null

# The release.html page redirects to the actual installer
# We need to get the redirect URL
try {
    $Response = Invoke-WebRequest -Uri "https://cloud.r-project.org/bin/windows/base/release.html" -MaximumRedirection 0 -ErrorAction SilentlyContinue
} catch {
    if ($_.Exception.Response.StatusCode -eq 302) {
        $RURL = $_.Exception.Response.Headers.Location.ToString()
        if ($RURL -match "R-(\d+\.\d+\.\d+)-win.exe") {
            $LatestRVersion = $matches[1]
            Write-Host "   Latest R version: $LatestRVersion" -ForegroundColor Gray
        }
    }
}

# Fallback if redirect didn't work
if (-not $RURL) {
    $CRANPage = Invoke-WebRequest -Uri "https://cloud.r-project.org/bin/windows/base/" -UseBasicParsing
    if ($CRANPage.Content -match 'href="(R-\d+\.\d+\.\d+-win.exe)"') {
        $RURL = "https://cloud.r-project.org/bin/windows/base/$($matches[1])"
        if ($matches[1] -match "R-(\d+\.\d+\.\d+)-win.exe") {
            $LatestRVersion = $matches[1]
            Write-Host "   Latest R version: $LatestRVersion" -ForegroundColor Gray
        }
    }
}

if ($CurrentRVersion -eq $LatestRVersion -and -not $RInProgramFiles) {
    Write-Host "✅ R is already up to date (version $CurrentRVersion)" -ForegroundColor Green
} else {
    if ($RInProgramFiles) {
        Write-Host "   R needs to be reinstalled in the correct location" -ForegroundColor Yellow
        Write-Host "   Please uninstall R from Program Files first, then re-run this script" -ForegroundColor Red
        Write-Host "" 
        Write-Host "   To uninstall R:" -ForegroundColor Yellow
        Write-Host "   1. Open Control Panel → Programs → Uninstall a program" -ForegroundColor Gray
        Write-Host "   2. Find R for Windows and uninstall it" -ForegroundColor Gray
        Write-Host "   3. Delete the folder: $env:USERPROFILE\Documents\R (if it exists)" -ForegroundColor Gray
        Write-Host "   4. Re-run this installer script" -ForegroundColor Gray
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    if ($CurrentRVersion) {
        Write-Host "   R update available: $CurrentRVersion → $LatestRVersion" -ForegroundColor Yellow
    }
    
    Write-Host "   Downloading R installer from CRAN..." -ForegroundColor Gray
    if (-not $RURL) {
        Write-Host "❌ Could not determine R download URL" -ForegroundColor Red
        exit 1
    }
    Invoke-WebRequest -Uri $RURL -OutFile "R-installer.exe"
    Check-Success "R download"
    
    Write-Host "   Installing R to $SystemDrive\R..." -ForegroundColor Gray
    # Silent install with custom directory
    Start-Process -FilePath "R-installer.exe" -ArgumentList "/VERYSILENT /DIR=`"$SystemDrive\R\R-$LatestRVersion`"" -Wait
    Check-Success "R installation"
    
    # Add R to PATH if not already there
    $RBinPath = "$SystemDrive\R\R-$LatestRVersion\bin\x64"
    $CurrentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($CurrentPath -notlike "*$RBinPath*") {
        [Environment]::SetEnvironmentVariable("Path", "$CurrentPath;$RBinPath", "Machine")
        $env:Path = "$env:Path;$RBinPath"
        Write-Host "   Added R to system PATH" -ForegroundColor Gray
    }
}
Write-Host ""

# Check and Install RStudio
Write-Host "🔧 Step 2: Checking RStudio installation..." -ForegroundColor Yellow

# Get current RStudio version if installed
$CurrentRStudioVersion = $null
$RStudioPath = "${env:ProgramFiles}\RStudio\resources\app\.webpack\desktop-info.json"
if (Test-Path $RStudioPath) {
    $DesktopInfo = Get-Content $RStudioPath | ConvertFrom-Json
    if ($DesktopInfo.version) {
        $CurrentRStudioVersion = $DesktopInfo.version -replace '-', '+'
        Write-Host "   Current RStudio version: $CurrentRStudioVersion" -ForegroundColor Gray
    }
}

# Get latest RStudio version from Posit
Write-Host "   Checking latest RStudio version from Posit..." -ForegroundColor Gray
$RStudioPage = Invoke-WebRequest -Uri "https://posit.co/download/rstudio-desktop/" -UseBasicParsing
if ($RStudioPage.Content -match '//download1\.rstudio\.org/electron/windows/RStudio-([^"]+)\.exe') {
    $RStudioURL = "https:$($matches[0])"
    $LatestRStudioVersion = $matches[1] -replace '-', '+'
    Write-Host "   Latest RStudio version: $LatestRStudioVersion" -ForegroundColor Gray
}

if ($CurrentRStudioVersion -eq $LatestRStudioVersion) {
    Write-Host "✅ RStudio is already up to date (version $CurrentRStudioVersion)" -ForegroundColor Green
} else {
    if ($CurrentRStudioVersion) {
        Write-Host "   RStudio update available: $CurrentRStudioVersion → $LatestRStudioVersion" -ForegroundColor Yellow
    }
    
    Write-Host "   Downloading RStudio from Posit..." -ForegroundColor Gray
    Invoke-WebRequest -Uri $RStudioURL -OutFile "RStudio-installer.exe"
    Check-Success "RStudio download"
    
    Write-Host "   Installing RStudio..." -ForegroundColor Gray
    Start-Process -FilePath "RStudio-installer.exe" -ArgumentList "/S" -Wait
    Check-Success "RStudio installation"
}
Write-Host ""

# Check and Install 7-Zip
Write-Host "🔧 Step 3: Checking 7-Zip installation..." -ForegroundColor Yellow

$7ZipInstalled = $false
$7ZipPaths = @(
    "${env:ProgramFiles}\7-Zip\7z.exe",
    "${env:ProgramFiles(x86)}\7-Zip\7z.exe"
)

foreach ($path in $7ZipPaths) {
    if (Test-Path $path) {
        $7ZipInstalled = $true
        Write-Host "✅ 7-Zip is already installed" -ForegroundColor Green
        break
    }
}

if (-not $7ZipInstalled) {
    Write-Host "   Downloading 7-Zip..." -ForegroundColor Gray
    $7ZipURL = "https://www.7-zip.org/a/7z2501-x64.exe"
    Invoke-WebRequest -Uri $7ZipURL -OutFile "7zip-installer.exe"
    Check-Success "7-Zip download"
    
    Write-Host "   Installing 7-Zip..." -ForegroundColor Gray
    Start-Process -FilePath "7zip-installer.exe" -ArgumentList "/S" -Wait
    Check-Success "7-Zip installation"
    
    # Add 7-Zip to PATH
    if (Test-Path "${env:ProgramFiles}\7-Zip") {
        $7ZipPath = "${env:ProgramFiles}\7-Zip"
    } else {
        $7ZipPath = "${env:ProgramFiles(x86)}\7-Zip"
    }
    
    $CurrentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($CurrentPath -notlike "*$7ZipPath*") {
        [Environment]::SetEnvironmentVariable("Path", "$CurrentPath;$7ZipPath", "Machine")
        $env:Path = "$env:Path;$7ZipPath"
        Write-Host "   Added 7-Zip to system PATH" -ForegroundColor Gray
    }
}
Write-Host ""

# Install R packages
Write-Host "🔧 Step 4: Installing Radiant and R packages..." -ForegroundColor Yellow
Write-Host "   This may take several minutes..." -ForegroundColor Gray

# Create R script for package installation
$RScript = @'
# Set options
options(HTTPUserAgent = sprintf("R/%s R (%s)", getRversion(), paste(getRversion(), R.version$platform, R.version$arch, R.version$os)))
repos <- c(CRAN = "https://cloud.r-project.org")
options(repos = repos)

# Update existing packages
update.packages(lib.loc = .libPaths()[1], ask = FALSE, type = "binary")

# Install required packages
cat("Installing Radiant and dependencies ...\n")
ipkgs <- rownames(installed.packages())
install <- function(x) {
  pkgs <- x[!x %in% ipkgs]
  if (length(pkgs) > 0) {
    cat(paste("   Installing:", paste(pkgs, collapse = ", "), "\n"))
    install.packages(pkgs, lib = .libPaths()[1], type = "binary")
  }
}

# Install core packages
install(c("radiant", "miniUI", "webshot", "usethis", "remotes", "tinytex"))

# Install installr for Windows-specific functionality
install("installr")

# Install PhantomJS for webshot
cat("Installing PhantomJS for screenshots...\n")
if (is.null(webshot:::find_phantom())) {
  webshot::install_phantomjs()
}

cat("R packages installation complete\n")
'@

$RScript | Out-File -FilePath "install_packages.R" -Encoding UTF8

# Find R executable
$RExePath = Get-ChildItem "$SystemDrive\R\R-*\bin\R.exe" | Select-Object -First 1
if ($RExePath) {
    & $RExePath.FullName --slave --no-restore --file=install_packages.R
    Check-Success "R packages installation"
} else {
    Write-Host "❌ Could not find R executable" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Install TinyTeX
Write-Host "🔧 Step 5: Installing TinyTeX for PDF reports..." -ForegroundColor Yellow
Write-Host "   This enables PDF generation in Radiant reports..." -ForegroundColor Gray

$TinyTeXScript = @'
# Check if pdflatex already exists
pl <- Sys.which("pdflatex")
if (nchar(pl) == 0) {
  cat("Installing TinyTeX...\n")
  tinytex::install_tinytex()
  cat("TinyTeX installation complete\n")
} else {
  cat("LaTeX already installed, skipping TinyTeX\n")
}
'@

$TinyTeXScript | Out-File -FilePath "install_tinytex.R" -Encoding UTF8
& $RExePath.FullName --slave --no-restore --file=install_tinytex.R
Check-Success "TinyTeX installation"
Write-Host ""

# Cleanup
Set-Location $env:TEMP
Remove-Item -Path $TEMP_DIR -Recurse -Force
Write-Host "🧹 Cleaned up temporary files" -ForegroundColor Gray
Write-Host ""

# Final instructions
Write-Host "🎉 Installation Complete!" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green
Write-Host ""
Write-Host "✅ R installed in $SystemDrive\R" -ForegroundColor Green
Write-Host "✅ RStudio installed and ready" -ForegroundColor Green
Write-Host "✅ Radiant packages installed" -ForegroundColor Green
Write-Host "✅ 7-Zip installed for compression" -ForegroundColor Green
Write-Host "✅ TinyTeX installed for PDF reports" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Close this window" -ForegroundColor Gray
Write-Host "   2. Open RStudio from Start Menu" -ForegroundColor Gray
Write-Host "   3. In RStudio, go to: Addins → Start radiant" -ForegroundColor Gray
Write-Host "   4. Radiant will open in your web browser" -ForegroundColor Gray
Write-Host ""
Write-Host "Press Enter to exit..."
Read-Host