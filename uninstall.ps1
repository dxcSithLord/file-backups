#
# File Backups Uninstallation Script for Windows Server
# PowerShell 2.0+ Compatible
#
# This script removes the File Backup utility from the installed location
# Environment Variable: FILE_BACKUPS_INSTALL_PATH
# Default: d:\data\myapp
#

# Set strict mode for better error handling
Set-StrictMode -Version 2.0

# Function to write log messages
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

# Function to test if running as Administrator (PS 2.0 compatible)
function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check for administrator privileges
if (-not (Test-Administrator)) {
    Write-Log "WARNING: Not running as Administrator. Uninstallation may fail if permissions are required." "WARN"
}

# Determine installation path
$defaultInstallPath = "d:\data\myapp"
$installPath = $env:FILE_BACKUPS_INSTALL_PATH

if ([string]::IsNullOrEmpty($installPath)) {
    $installPath = $defaultInstallPath
    Write-Log "Environment variable FILE_BACKUPS_INSTALL_PATH not set. Using default: $installPath"
} else {
    Write-Log "Using installation path from environment variable: $installPath"
}

# Normalize the path
$installPath = $installPath.TrimEnd('\').TrimEnd('/')

Write-Log "============================================"
Write-Log "File Backups Uninstaller"
Write-Log "============================================"
Write-Log "Installation path: $installPath"
Write-Log ""

# Check if installation exists
if (-not (Test-Path $installPath)) {
    Write-Log "WARNING: Installation directory not found at: $installPath" "WARN"
    Write-Log "Nothing to uninstall."
    exit 0
}

# Check for install-info.txt to verify this is our installation
$installInfoFile = Join-Path $installPath "install-info.txt"
$isValidInstallation = $false

if (Test-Path $installInfoFile) {
    $isValidInstallation = $true
    Write-Log "Found installation info file - this appears to be a valid installation"

    # Display installation info
    try {
        $installInfo = Get-Content $installInfoFile
        Write-Log "Installation details:"
        $installInfo | ForEach-Object { Write-Log "  $_" }
        Write-Log ""
    } catch {
        Write-Log "Could not read installation info file" "WARN"
    }
} else {
    Write-Log "WARNING: Could not find installation info file." "WARN"
    Write-Log "This may not be a File Backups installation directory." "WARN"
}

# Confirm with user
Write-Host ""
Write-Host "WARNING: This will permanently delete all files in: $installPath" -ForegroundColor Yellow
Write-Host ""

# If this doesn't appear to be a valid installation, require explicit path confirmation
if (-not $isValidInstallation) {
    Write-Host "This directory does not contain an install-info.txt file." -ForegroundColor Red
    Write-Host "To proceed with deletion, please type the full path exactly as shown above: " -NoNewline -ForegroundColor Red
    $pathConfirmation = Read-Host

    if ($pathConfirmation -ne $installPath) {
        Write-Log "Path confirmation failed. Uninstallation cancelled for safety." "ERROR"
        exit 1
    }
    Write-Host ""
}

Write-Host "Are you sure you want to continue? (yes/no): " -NoNewline -ForegroundColor Yellow
$confirmation = Read-Host

# Use case-insensitive comparison for better user experience
if ($confirmation.ToLower() -ne "yes") {
    Write-Log "Uninstallation cancelled by user."
    exit 0
}

# Perform uninstallation
Write-Log "Starting uninstallation..."

try {
    # Remove the directory and all contents
    Write-Log "Removing installation directory: $installPath"
    Remove-Item -Path $installPath -Recurse -Force -ErrorAction Stop
    Write-Log "Installation directory removed successfully"

    Write-Log "============================================"
    Write-Log "Uninstallation completed successfully!"
    Write-Log "============================================"
    Write-Log ""
    Write-Log "The File Backups utility has been removed from your system."
    Write-Log ""

    # Suggest removing environment variable if it was set
    if (-not [string]::IsNullOrEmpty($env:FILE_BACKUPS_INSTALL_PATH)) {
        Write-Log "NOTE: The FILE_BACKUPS_INSTALL_PATH environment variable is still set."
        Write-Log "To remove it permanently, run:"
        Write-Log "  [Environment]::SetEnvironmentVariable('FILE_BACKUPS_INSTALL_PATH', `$null, 'Machine')"
        Write-Log "  or"
        Write-Log "  [Environment]::SetEnvironmentVariable('FILE_BACKUPS_INSTALL_PATH', `$null, 'User')"
        Write-Log ""
    }

    exit 0

} catch {
    Write-Log "ERROR: Failed to remove installation directory: $_" "ERROR"
    Write-Log ""
    Write-Log "Possible causes:" "ERROR"
    Write-Log "- Files may be in use by another program" "ERROR"
    Write-Log "- Insufficient permissions (try running as Administrator)" "ERROR"
    Write-Log "- Files may be locked by antivirus software" "ERROR"
    Write-Log ""
    Write-Log "Manual removal steps:" "ERROR"
    Write-Log "1. Close all programs that may be using files in: $installPath" "ERROR"
    Write-Log "2. Try running this script as Administrator" "ERROR"
    Write-Log "3. Manually delete the folder: $installPath" "ERROR"
    exit 1
}
