# Installation Guide for Windows Server

This guide explains how to install the File Backups utility on Windows Server using PowerShell.

## Requirements

- Windows Server (2008 R2 or newer)
- PowerShell 2.0 or higher
- Local drive (other than C:) for installation
- Administrator privileges (recommended)

## Installation

### Quick Install (Default Location)

By default, the script installs to `d:\data\myapp`. To install with defaults:

```powershell
.\install.ps1
```

### Custom Installation Location

You can specify a custom installation path using the `FILE_BACKUPS_INSTALL_PATH` environment variable:

#### Option 1: Set environment variable for current session

```powershell
$env:FILE_BACKUPS_INSTALL_PATH = "e:\applications\file-backups"
.\install.ps1
```

#### Option 2: Set environment variable permanently (requires Administrator)

```powershell
[Environment]::SetEnvironmentVariable("FILE_BACKUPS_INSTALL_PATH", "e:\applications\file-backups", "Machine")
.\install.ps1
```

#### Option 3: Set for current user only

```powershell
[Environment]::SetEnvironmentVariable("FILE_BACKUPS_INSTALL_PATH", "e:\applications\file-backups", "User")
.\install.ps1
```

### Running as Administrator

For best results, run PowerShell as Administrator:

1. Right-click on PowerShell icon
2. Select "Run as Administrator"
3. Navigate to the installation directory
4. Run the install script

### Execution Policy

If you encounter an execution policy error, you may need to allow script execution:

```powershell
# View current policy
Get-ExecutionPolicy

# Set policy for current session only
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Or set for current user
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

## Installation Process

The installation script will:

1. Check for administrator privileges (warning if not present)
2. Determine the installation path (environment variable or default)
3. Validate that the target drive is not C:
4. Verify the target drive exists
5. Create the installation directory structure
6. Copy all necessary files and folders
7. Create an installation info file
8. Display installation summary

## Validation

After installation, verify the following:

1. Check that files exist at the installation location
2. Review `install-info.txt` in the installation directory
3. Verify all subdirectories were created:
   - addon
   - build-tools
   - docs
   - assets
   - background_scripts
   - content_scripts
   - extUI
   - libs
   - popup
   - settings

## Uninstallation

To uninstall, use the provided uninstall script:

```powershell
.\uninstall.ps1
```

Or manually delete the installation directory.

## Troubleshooting

### Error: Drive does not exist

Ensure the target drive (e.g., D:, E:) is available and accessible.

### Error: Cannot create directory

- Check disk space
- Verify you have write permissions
- Run PowerShell as Administrator

### Error: Cannot copy files

- Ensure source files are present
- Check file locks (close any programs using the files)
- Verify antivirus isn't blocking the operation

### PowerShell Version

To check your PowerShell version:

```powershell
$PSVersionTable.PSVersion
```

## Examples

### Install to D: drive (default)

```powershell
.\install.ps1
```

Result: Files installed to `d:\data\myapp`

### Install to E: drive

```powershell
$env:FILE_BACKUPS_INSTALL_PATH = "e:\myapps\file-backups"
.\install.ps1
```

Result: Files installed to `e:\myapps\file-backups`

### Install to network-mapped drive

```powershell
# Map a network drive first (example)
net use Z: \\server\share

# Install to the mapped drive
$env:FILE_BACKUPS_INSTALL_PATH = "z:\applications\file-backups"
.\install.ps1
```

**Note:** While network drives are supported, it's recommended to use local drives for better performance.

## Post-Installation

After installation:

1. Review the main README.md in the installation directory
2. Configure the browser extension according to your needs
3. Set up backup locations as described in the main documentation

## Support

For issues or questions:
- Check the main README.md
- Visit: [GitHub Repository](https://github.com/pmario/file-backups)
- Review existing issues or create a new one

## License

Copyright Mario Pietsch 2017-2020
[CC-BY-NC-SA](https://creativecommons.org/licenses/by-nc-sa/4.0)
