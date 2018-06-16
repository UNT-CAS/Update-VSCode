#Requires -RunAsAdministrator

$applicationName = 'Microsoft Visual Studio Code'

$urlTags = 'https://api.github.com/repos/Microsoft/vscode/tags'
$urlLatestDownload = 'https://az764295.vo.msecnd.net/stable/{0}/VSCodeSetup-x64-{1}.exe'

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$tags = (Invoke-WebRequest -Uri $urlTags -UseBasicParsing -ErrorAction Stop).Content | ConvertFrom-Json
$versions = $tags | Where-Object { $_.name -as [version] }
[version] $versionLatest = ($versions | Sort-Object -Property 'name' -Descending)[0].name
$shaLatest = ($versions | Sort-Object -Property 'name' -Descending)[0].commit.sha
[version] $versionInstalled = $null

$uninstallKeys = @(
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\'
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\'
)

foreach ($uninstallKey in $uninstallKeys) {
    if (Test-Path $uninstallKey) {
        foreach ($installedSoftware in (Get-ChildItem $uninstallKey)) {
            $installedSoftwareProperties = Get-ItemProperty ('Registry::{0}' -f $installedSoftware.Name)

            if ($installedSoftwareProperties.DisplayName -eq $applicationName) {
                Write-Verbose ('VS Code found: {0}' -f ($installedSoftwareProperties | Out-String))
                [version] $versionInstalled = $installedSoftwareProperties.DisplayVersion
                
                Write-Verbose ('VS Code found: {0}' -f $versionInstalled)
            }
        }
    }
}

if ($versionInstalled -ne $versionLatest) {
    $vscodeSetup = '{0}\VSCodeSetup.exe' -f $env:Temp
    Invoke-WebRequest -Uri ($urlLatestDownload -f $shaLatest, $versionLatest) -OutFile $vscodeSetup -UseBasicParsing

    while (Get-Process 'Code' -IncludeUserName -ErrorAction SilentlyContinue) {
        Write-Verbose ('VS Code is currently in use by {0}; will check again in a minute ...' -f (((Get-Process 'Code' -IncludeUserName).UserName | Sort-Object -Unique) -join ', '))
        Start-Sleep -Seconds 60
    }

    Write-Verbose 'Installing latest version...'
    Start-Process -FilePath $vscodeSetup -ArgumentList "/silent /mergetasks=!runcode /norestart" -Wait
} else {
    Write-Verbose 'Latest version already installed.'
}
