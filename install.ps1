#
# File Backups Installation Script for Windows Server
# PowerShell 2.0+ Compatible
#
# This script installs the File Backup utility to a specified location
# Environment Variable: FILE_BACKUPS_INSTALL_PATH
# Default: d:\data\myapp
#

# Set strict mode for better error handling
Set-StrictMode -Version 2.0

# Get the directory where this script is located
$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

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
    Write-Log "WARNING: Not running as Administrator. Installation may fail if permissions are required." "WARN"
}

# Determine installation path
# Priority: Environment variable > Default path
$defaultInstallPath = "d:\data\myapp"
$installPath = $env:FILE_BACKUPS_INSTALL_PATH

if ([string]::IsNullOrEmpty($installPath)) {
    $installPath = $defaultInstallPath
    Write-Log "Environment variable FILE_BACKUPS_INSTALL_PATH not set. Using default: $installPath"
} else {
    Write-Log "Using installation path from environment variable: $installPath"
}

# Validate that the installation path is not on C: drive
$installDrive = Split-Path -Qualifier $installPath
if ($installDrive -eq "C:") {
    Write-Log "ERROR: Installation path cannot be on C: drive. Please use a different drive." "ERROR"
    Write-Log "Set the FILE_BACKUPS_INSTALL_PATH environment variable or modify the default in this script." "ERROR"
    exit 1
}

# Normalize the path
$installPath = $installPath.TrimEnd('\').TrimEnd('/')

Write-Log "Installing File Backups to: $installPath"

# Check if the drive exists (reuse $installDrive variable)
if (-not (Test-Path $installDrive)) {
    Write-Log "ERROR: Drive $installDrive does not exist. Please check the installation path." "ERROR"
    exit 1
}

# Validate drive type - must be a local disk, not a network drive
# Using WMI for PowerShell 2.0 compatibility
# DriveType: 3 = Local Disk, 4 = Network Drive, 5 = CD-ROM, 6 = RAM Disk
try {
    $driveLetter = $installDrive.TrimEnd(':')
    $driveInfo = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$installDrive'" -ErrorAction Stop

    if ($driveInfo -eq $null) {
        Write-Log "ERROR: Unable to retrieve information for drive $installDrive" "ERROR"
        exit 1
    }

    $driveType = $driveInfo.DriveType
    $driveTypeName = switch ($driveType) {
        0 { "Unknown" }
        1 { "No Root Directory" }
        2 { "Removable Disk" }
        3 { "Local Disk" }
        4 { "Network Drive" }
        5 { "Compact Disc" }
        6 { "RAM Disk" }
        default { "Unknown ($driveType)" }
    }

    Write-Log "Drive $installDrive type: $driveTypeName"

    # Reject network drives
    if ($driveType -eq 4) {
        Write-Log "ERROR: Installation to network drives is not supported." "ERROR"
        Write-Log "Network drives may have reliability issues with file operations." "ERROR"
        Write-Log "Please use a local drive (e.g., D:, E:, F:) instead." "ERROR"
        exit 1
    }

    # Warn for non-standard drive types but allow them
    if ($driveType -ne 3) {
        Write-Log "WARNING: Drive type is '$driveTypeName'. Local Disk (type 3) is recommended for best reliability." "WARN"
        Write-Log "Installation will continue, but you may experience issues." "WARN"
    }

    # Check if drive is ready and has available space
    if ($driveInfo.DriveType -eq 3) {
        $freeSpaceGB = [math]::Round($driveInfo.FreeSpace / 1GB, 2)
        Write-Log "Drive $installDrive has $freeSpaceGB GB free space available"

        if ($driveInfo.FreeSpace -lt 100MB) {
            Write-Log "WARNING: Low disk space on $installDrive. Installation may fail." "WARN"
        }
    }

} catch {
    Write-Log "WARNING: Could not validate drive type: $_" "WARN"
    Write-Log "Installation will continue, but drive validation was skipped." "WARN"
}

# Create installation directory if it doesn't exist
try {
    if (-not (Test-Path $installPath)) {
        Write-Log "Creating installation directory: $installPath"
        New-Item -ItemType Directory -Path $installPath -Force -ErrorAction Stop | Out-Null
        Write-Log "Installation directory created successfully"
    } else {
        Write-Log "Installation directory already exists"
    }
} catch {
    Write-Log "ERROR: Failed to create installation directory: $_" "ERROR"
    exit 1
}

# Create subdirectories explicitly for better error handling and progress reporting
# Note: While Copy-Item -Recurse can create directories, pre-creating them allows
# us to catch permission issues early and provide clearer feedback to the user
$subdirs = @("addon", "build-tools", "docs")
foreach ($subdir in $subdirs) {
    $subdirPath = Join-Path $installPath $subdir
    try {
        if (-not (Test-Path $subdirPath)) {
            Write-Log "Creating subdirectory: $subdir"
            New-Item -ItemType Directory -Path $subdirPath -Force -ErrorAction Stop | Out-Null
        }
    } catch {
        Write-Log "ERROR: Failed to create subdirectory $subdir : $_" "ERROR"
        exit 1
    }
}

# Copy files from source to installation directory
Write-Log "Copying files to installation directory..."

# Define items to copy
$itemsToCopy = @(
    "addon",
    "assets",
    "background_scripts",
    "banner.js",
    "build-tools",
    "content_scripts",
    "docs",
    "extUI",
    "libs",
    "package.json",
    "package-lock.json",
    "popup",
    "settings",
    "README.md",
    "webpack.config.js"
)

$copiedCount = 0
$failedCount = 0

foreach ($item in $itemsToCopy) {
    $sourcePath = Join-Path $scriptDir $item
    $destPath = Join-Path $installPath $item

    if (Test-Path $sourcePath) {
        try {
            if (Test-Path $sourcePath -PathType Container) {
                # It's a directory - use robocopy for better reliability in PS 2.0
                Write-Log "Copying directory: $item"
                # Use Copy-Item with recurse (note: has bugs in PS 2.0 but will work for most cases)
                Copy-Item -Path $sourcePath -Destination $installPath -Recurse -Force -ErrorAction Stop
            } else {
                # It's a file
                Write-Log "Copying file: $item"
                Copy-Item -Path $sourcePath -Destination $destPath -Force -ErrorAction Stop
            }
            $copiedCount++
        } catch {
            Write-Log "WARNING: Failed to copy $item : $_" "WARN"
            $failedCount++
        }
    } else {
        Write-Log "WARNING: Source item not found: $item" "WARN"
    }
}

Write-Log "Copied $copiedCount items successfully, $failedCount failed"

# Create a version info file
$versionFile = Join-Path $installPath "install-info.txt"
try {
    $versionInfo = @"
File Backups Installation Information
======================================
Installation Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Installation Path: $installPath
PowerShell Version: $($PSVersionTable.PSVersion)
Operating System: $([Environment]::OSVersion.VersionString)
Computer Name: $env:COMPUTERNAME
Installed By: $env:USERNAME
"@

    $versionInfo | Out-File -FilePath $versionFile -Encoding ASCII -Force
    Write-Log "Installation info saved to: $versionFile"
} catch {
    Write-Log "WARNING: Failed to create installation info file: $_" "WARN"
}

# Installation complete
Write-Log "============================================"
Write-Log "Installation completed successfully!"
Write-Log "Installation location: $installPath"
Write-Log "============================================"
Write-Log ""
Write-Log "Next steps:"
Write-Log "1. Review the installation at: $installPath"
Write-Log "2. Configure the browser extension as needed"
Write-Log "3. Refer to README.md for usage instructions"
Write-Log ""

# Exit successfully
exit 0
