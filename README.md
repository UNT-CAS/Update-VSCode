[VS Code](https://vscode.microsoft.com) [doesn't do completely silent updates](https://github.com/Microsoft/vscode/issues/9539#issuecomment-397772482).
This works around that shortcoming and allows the user to just *use* VS Code.

# Parameters

Parameters let you customize some installer options.
All parameters can also be set with an environment variable as such: `UpdateVSCode${Parameter}`.
For example, the `SetupSilent` variable as an environment variable would be: `UpdateVSCodeSetupSilent`.

Keep in mind that environment variables are always strings.
So, setting a switch parameter to `'$false'` via an environment variable would still be `$true`.
You can see what I mean with these examples: `[bool]'true'`, `[bool]'false'`, `[bool]'$true'`, `[bool]'$false'`, `[bool]'0'`, and `[bool]''`.

## LogPath

- Type: `[IO.FileInfo]`
- Default: `"${env:SystemRoot}\Logs\Update-VSCode.ps1.log"`

This is the full path (directory and name) of the log file.
Additionally, the `setup.exe` will use this to generate its log file's full path by appending `-Setup` before the extension; such as: `"${env:SystemRoot}\Logs\Update-VSCode.ps1-Setup.log"`.

Only the latest iteration of the log file is kept.
In other words: the logging will not append to the previous run of this script.
This keeps the log file from getting bloated.
I tend to believe that only the latest iteration is ever really needed anyway.

## SetupMergeTasks

- Type: `[string]`
- Default: `'addcontextmenufiles,addcontextmenufolders,addtopath,associatewithfiles,!desktopicon,!quicklaunchicon,!runcode'`

This setting allows you to customize some of the installer options/tasks.
The tasks listed as *default*, above, are [the current tasks in the `code.iss` file](https://github.com/Microsoft/vscode/blob/12ab70d329a13dd5b18d892cd40edd7138259bc3/build/win32/code.iss#L61-L68), [thanks StackOverflow](https://stackoverflow.com/a/42582896/615422).
Think of each task as a checkbox.
Putting a bang (`!`) in front of the taskname is like unchecking the box.

These tasks are subject to change.
Check the latest version of that `code.iss` file for details; it will definitely be more updated than this README.

## SetupSilent

- Type: `[switch]`

If set, the `setup.exe` will be passed the `/SILENT` parameter, instead of using this script's default `/VERYSILENT` parameter.

If you specify this switch and the [SetupSilentNoCancel](#setupsilent) switch, the [SetupSilentNoCancel](#setupsilent) switch will take precedence.

## SetupSilentNoCancel

- Type: `[switch]`

If set, the `setup.exe` will be passed the `/SILENT` and `/NOCANCEL` parameters, instead of using this script's default `/VERYSILENT` parameter.

If you specify this switch and the [SetupSilent](#setupsilent) switch, this switch will take precedence.

# Examples

The script file is not needed on the computer.
I just created a scheduled task to run this as the `System` user.
You have at least two options to accomplish this:

1. [Base64 encode](#base64-encoded) it and run it with the `powershell.exe -EncodedCommand` parameter. **(Personal Preference)**
1. [Download and Execute](#download-and-execute) it straight from GitHub, I'm sure GitHub won't mind. 😏

There is while loop in this script that could potentially run forever.
Use the scheduled task settings to create a timeout.

Both options are below ... 

## Base64 Encoded

This is my personal preference because there's really no reason to download the code base constantly.

```powershell
$url = 'https://raw.githubusercontent.com/UNT-CAS/Update-VSCode/master/Update-VSCode.ps1'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$command = Invoke-WebRequest -Uri $url -UseBasicParsing
$bytes = [System.Text.Encoding]::Unicode.GetBytes($command)
$encodedCommand = [Convert]::ToBase64String($bytes)
```

Then use the contents of `$encodedCommand` like this:

```bash
powershell.exe -W H -Ex B -NoP -NonI -EncodedCommand "WwBEAGkAYQBnAG4AbwBzAHQAaQBjAHMALgBQAHIAbwBjAGUAcwBzAF0AOgA6AFMAdABhAHIAdAAoACcAaAB0AHQAcABzADoALwAvAHUAbgB0AGMAYQBzAC4AcABhAGcAZQAuAGwAaQBuAGsALwBMADgAdABjACcAKQA="
```

*Note: you might want to re-base64 it yourself.*
*It is not the base64 you are looking for.*

## Download and Execute

❗️ **Seriously, don't do it this way unless you point it at a commit id, or you fork this repo and point it at your fork.**

```bash
powershell.exe -W H -Ex B -NoP -NonI "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest 'https://raw.githubusercontent.com/UNT-CAS/Update-VSCode/e00b0c8c25a66d07361148a6573c47810be8c63a/Update-VSCode.ps1' -UseBasicParsing | Invoke-Expression"
```

*Note: you might want to confirm that the commit id in that URL is the id you want.*
*I likely won't come back and update the commit id every time I make a change to the code.*
