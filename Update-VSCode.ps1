# Requires -RunAsAdministrator

<#
    .Synopsis

        Automagically update VS Code so you don't have to worry about it anymore.

    .Description

        By default, this will install/upgrade VS Code the same way I do on Windows computers that I manage.

        For a details, take a look at the README: https://github.com/UNT-CAS/Update-VSCode
#>

[CmdletBinding()]
Param(
    [Parameter()]
    [IO.FileInfo]
    $LogPath = $(if ($env:UpdateVSCodeLogPath) { $env:UpdateVSCodeLogPath } else { "${env:SystemRoot}\Logs\Update-VSCode.ps1.log" }),

    [Parameter()]
    [string]
    $SetupMergeTasks = $(if ($env:UpdateVSCodeSetupMergeTasks) { $env:UpdateVSCodeSetupMergeTasks } else { '!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath' }),

    [switch]
    $SetupSilent,
    
    [string]
    $SetupSilentNoCancel
)

Start-Transcript -LiteralPath $LogPath -IncludeInvocationHeader -Force

Write-Host "# Parameters"
Write-Host "## SetupSilent:         $($SetupSilent.IsPresent)"
Write-Host "## SetupSilentNoCancel: $($SetupSilentNoCancel.IsPresent)"
Write-Host "## LogPath:             ${LogPath}"

Write-Host "# Environment Variables Starting with ""UpdateVSCode"""
foreach ($envVariable in (Get-ChildItem env: | Where-Object { $_.Name.StartsWith('UpdateVSCode') })) {
    Write-Host ("{0,-30} {1}" -f "$($envVariable.Name):", $envVariable.Value)
}

if (
    ($SetupSilent.IsPresent -or $env:UpdateVSCodeSetupSilent) -and
    ($SetupSilentNoCancel.IsPresent -or $env:UpdateVSCodeSetupSilentNoCancel)
) {
    Write-Warning "Parameter overridden: SetupSilentNoCancel will override SetupSilent."
}

$applicationName = 'Microsoft Visual Studio Code'
$urlTags = 'https://api.github.com/repos/Microsoft/vscode/tags'
$urlDownload = 'https://az764295.vo.msecnd.net/stable/{0}/VSCodeSetup-x64-{1}.exe'
$vscodeSetup = "${env:Temp}\VSCodeSetup.exe"

Write-Host "# General Settings"
Write-Host "## Application Name: ${applicationName}"
Write-Host "## URL Tags: ${urlTags}"
Write-Host "## URL Download: ${urlDownload}"
Write-Host "## VS Code Setup *Download To* Location: ${vscodeSetup}"

Write-Host "# TLS 1.2 Required"
Write-Host "## Current Net.ServicePointManager: $([Net.ServicePointManager]::SecurityProtocol)"
Write-Host '## Setting TLS 1.2'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Write-Host "## New Net.ServicePointManager: $([Net.ServicePointManager]::SecurityProtocol)"

Write-Host "# Getting Latest Information"
Write-Host "## GitHub Tags:"
$tags = (Invoke-WebRequest -Uri $urlTags -UseBasicParsing -ErrorAction Stop -Verbose).Content | ConvertFrom-Json 4>&1
Write-Host ($tags | Out-String)

Write-Host "## GitHub Versions (Tags that look like Version numbers):"
$versions = $tags | Where-Object { $_.name -as [version] }
Write-Host ($versions | Out-String)

Write-Host "## Latest GitHub Versions:"
[version] $versionLatest = ($versions | Sort-Object -Property 'name' -Descending)[0].name
Write-Host $versionLatest

Write-Host "## Latest GitHub Sha:"
$shaLatest = ($versions | Sort-Object -Property 'name' -Descending)[0].commit.sha
Write-Host $shaLatest

[version] $versionInstalled = $null

$uninstallKeys = @(
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\'
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\'
)

Write-Host "# Checking if VSCode is Installed"
:mainLoop foreach ($uninstallKey in $uninstallKeys) {
    if (Test-Path $uninstallKey) {
        Write-Host "## Checking Key: ${uninstallKey}"
        foreach ($installedSoftware in (Get-ChildItem $uninstallKey)) {
            Write-Host "### Checking SubKey: $($installedSoftware.Name)"
            $installedSoftwareProperties = Get-ItemProperty ('Registry::{0}' -f $installedSoftware.Name)
            
            Write-Host "#### DisplayName: $($installedSoftwareProperties.DisplayName)"
            if ($installedSoftwareProperties.DisplayName -eq $applicationName) {
                Write-Host "##### VS Code found: $($installedSoftwareProperties | Out-String)"
                [version] $versionInstalled = $installedSoftwareProperties.DisplayVersion
                
                Write-Host "##### Version Installed: ${versionInstalled}"
                break mainLoop
            }
        }
    } else {
        Write-Host "## Key Doesn't Exist: ${uninstallKey}"
    }
}

Write-Host "# Install VS Code if needed."
if ($versionInstalled -ne $versionLatest) {
    Write-Host "## Need to install/upgrade VS Code"
    Write-Host "## Download Setup"
    Invoke-WebRequest -Uri ($urlDownload -f $shaLatest, $versionLatest) -OutFile $vscodeSetup -UseBasicParsing -Verbose 4>&1
    
    Write-Host "## Wait for VS Code to not be in use ..."
    while (Get-Process 'Code' -IncludeUserName -ErrorAction SilentlyContinue) {
        Write-Host ('### VS Code is currently in use by {0}; will check again in a minute ...' -f (((Get-Process 'Code' -IncludeUserName).UserName | Sort-Object -Unique) -join ', '))
        Start-Sleep -Seconds 60
    }
    Write-Host "## VS Code not in use"

    Write-Host "## Running VSCode Setup"
    if ($SetupSilentNoCancel.IsPresent -or $env:UpdateVSCodeSetupSilentNoCancel) {
        $ArgumentList = @('/SILENT', '/NOCANCEL')
    } elseif ($SetupSilent.IsPresent -or $env:UpdateVSCodeSetupSilent) {
        $ArgumentList = @('/SILENT')
    } else {
        $ArgumentList = @('/VERYSILENT')
    }

    $startProcess = @{
        FilePath = $vscodeSetup
        ArgumentList = $ArgumentList + @(
            "/MERGETASKS=""${SetupMergeTasks}""",
            '/NORESTART',
            "/LOG=""$($LogPath.DirectoryName)\$($LogPath.BaseName)-Setup.log"""
        )
        PassThru = $true
        Wait = $true
    }
    Write-Host ($startProcess | ConvertTo-Json)
    
    $result = Start-Process @startProcess
    Write-Host "Exit Code: $($result.ExitCode)"
} else {
    Write-Host "## Latest version already installed."
}

Stop-Transcript