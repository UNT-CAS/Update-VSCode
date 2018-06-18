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
    [switch]
    $DoNotBlock,

    [Parameter()]
    [IO.FileInfo]
    $LogPath = $(if ($env:UpdateVSCodeLogPath) { $env:UpdateVSCodeLogPath } else { "${env:SystemRoot}\Logs\Update-VSCode.ps1.log" }),

    [Parameter()]
    [string]
    $PopupTitle = $(if ($env:UpdateVSCodePopupTitle) { $env:UpdateVSCodePopupTitle } else { 'VS Code: Installing/Upgrading' }),

    [Parameter()]
    [string]
    $PopupText = $(if ($env:UpdateVSCodePopupText) { $env:UpdateVSCodePopupText } else { 'VS Code is currently being installed or upgraded. It will not be accessible for the duration of the install. This won''t take long ... try again in a minute.' }),

    [Parameter()]
    [string]
    $PopupDuration = $(if ($env:UpdateVSCodePopupDuration) { $env:UpdateVSCodePopupDuration } else { '30' }),

    [Parameter()]
    [string]
    $PopupType = $(if ($env:UpdateVSCodePopupType) { $env:UpdateVSCodePopupType } else { '0x30' }),

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
$processNames = @('Code')
$scriptGuid = 'a229ded3-1ecb-4a0a-b627-9c66b7692d3e'
$urlTags = 'https://api.github.com/repos/Microsoft/vscode/tags'
$urlDownload = 'https://az764295.vo.msecnd.net/stable/{0}/VSCodeSetup-x64-{1}.exe'
$vscodeSetup = "${env:Temp}\VSCodeSetup.exe"

Write-Host "# General Settings"
Write-Host "## Application Name: ${applicationName}"
Write-Host "## Process Names: ${processNames}"
Write-Host "## Script GUID: ${scriptGuid}"
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

    [System.Collections.ArrayList] $vbsFilePaths = @()
    if ((-not $DoNotBlock.IsPresent) -or (-not $env:UpdateVSCodeDoNotBlock)) {
        Write-Host '## Will block VS Code from executing during the installation ...'

        $debuggerCommand = 'wscript.exe //E:vbscript {0}'
        $blockedAppVbs = @'
Dim wshShell: Set wshShell = WScript.CreateObject("WScript.Shell")
WshShell.Popup "{0}", {1}, "{2}", {3}
'@ -f @(
            $PopupText,
            ($PopupDuration -as [int]),
            $PopupTitle,
            ($PopupType -as [int32])
        )

        foreach ($processName in $processNames) {
            Write-Host ('### Blocking: {0}.exe' -f $processName)

            $vbsFilePath = New-TemporaryFile
            $vbsFilePaths.Add($vbsFilePath) | Out-Null
            
            ($blockedAppVbs -f $processName) | Out-File -Encoding ascii -LiteralPath $vbsFilePath

            [string] $processKey = Join-Path $ifeoKey "${processName}.exe" -ErrorAction Stop
            try {
                # The $processKey key already exists
                [string] $processKey = Resolve-Path $processKey -ErrorAction Stop
            } catch [System.Management.Automation.ItemNotFoundException] {
                # The $processKey key does not exist
                New-Item -Type Directory $processKey -ErrorAction Stop | Out-Null
                [string] $processKey = Resolve-Path $processKey -ErrorAction Stop
                New-ItemProperty -Path $processKey -Name ('{0}MadeMe' -f $scriptGuid) -Type 'DWORD' -Value $true | Out-Null
            }

            $debuggerExisting = (Get-ItemProperty $processKey).Debugger
            if (($debuggerExisting | Measure-Object).Count) {
                # The 'Debugger' value already exists
                New-ItemProperty -Path $processKey -Name ('Debugger_{0}RenamedMe' -f $scriptGuid) -Value $debuggerExisting -ErrorAction 'SilentlyContinue' | Out-Null
                Remove-ItemProperty -Path $processKey -Name 'Debugger' | Out-Null
            }

            New-ItemProperty -Path $processKey -Name 'Debugger' -Value ($debuggerCommand -f $vbsFilePath) | Out-Null
            New-ItemProperty -Path $processKey -Name ('{0}MadeDebugger' -f $scriptGuid) -Type 'DWORD' -Value $true | Out-Null
        }
    }

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

    Write-Host '## Time to unblock VS Code from executing ...'
    foreach ($processName in $processNames) {
        Write-Host ('### Unblocking: {0}.exe' -f $processName)

        [string] $processKey = Join-Path $ifeoKey "${processName}.exe" -ErrorAction Stop
        Write-Debug "### Process Key: ${processKey}"
        
        try {
            $properties = Get-ItemProperty -Path $processKey -ErrorAction Stop
            Write-Host "### Process Key Properties: $($properties | Out-String)"
        } catch [System.Management.Automation.ItemNotFoundException] {
            Write-Error "[ItemNotFoundException] Unexpected Error; should never see this: $_"
            continue
        }

        Write-Debug "### MadeMe: $($properties["${scriptGuid}MadeMe"])"

        if ($properties.$("${scriptGuid}MadeMe")) {
            Write-Host "### Deleting Key: ${processKey}"
            Remove-Item $processKey -Recurse -Force -ErrorAction Stop | Out-Null
        } elseif ($properties.$("${scriptGuid}MadeDebugger")) {
            Write-Host "### Deleting Key Value: ${processKey} : Debugger"
            Remove-ItemProperty -Path $processKey -Name 'Debugger' -ErrorAction Stop | Out-Null

            Write-Host "### Deleting Key Value: ${processKey} : ${scriptGuid}MadeDebugger"
            Remove-ItemProperty -Path $processKey -Name "${scriptGuid}MadeDebugger" -ErrorAction Stop | Out-Null
        } elseif ($properties.$("Debugger_${scriptGuid}RenamedMe")) {
            Write-Host "### Deleting Key Value: ${processKey} : Debugger"
            Remove-ItemProperty -Path $processKey -Name 'Debugger' -ErrorAction Stop | Out-Null

            Write-Host "### Renaming Key: ${processKey} : Debugger_${scriptGuid}RenamedMe > Debugger"
            New-ItemProperty -Path $processKey -Name 'Debugger' -Value $properties.$("Debugger_${scriptGuid}RenamedMe") -ErrorAction Stop | Out-Null
            Remove-ItemProperty -Path $processKey -Name "Debugger_${scriptGuid}RenamedMe" -ErrorAction Stop | Out-Null
        }
    }

    $vbsFilePaths | Remove-Item -Force
} else {
    Write-Host "## Latest version already installed."
}

Stop-Transcript