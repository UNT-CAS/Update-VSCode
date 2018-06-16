Automagically update VS Code so I don't have to worry about it anymore.

Don't even need the script file on the computer. Probably just want to run as the `System` user via a scheduled task. You have at least two options to accomplish this:
1. Base64 encode it and run it with the `powershell.exe -EncodedCommand` parameter. **(Personal Preference)**
1. Run it straight from GitHub, I'm sure GitHub won't mind. 😏 

Yes, the while loop could potentially run forever. Use the scheduled task to create a timeout.

Both options are below ... 

# Base64

```powershell
$urlGist = 'https://raw.githubusercontent.com/UNT-CAS/Update-VSCode/master/Update-VSCode.ps1'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$command = Invoke-WebRequest -Uri $urlGist -UseBasicParsing
$bytes = [System.Text.Encoding]::Unicode.GetBytes($command)
$encodedCommand = [Convert]::ToBase64String($bytes)
```

Then use the contents of `$encodedCommand` like this:

```bash
powershell.exe -W H -Ex B -NoP -NonI -EncodedCommand "IwBSAGUAcQB1AGkAcgBlAHMAIAAtAFIAdQBuAEEAcwBBAGQAbQBpAG4AaQBzAHQAcgBhAHQAbwByAAoACgAkAGEAcABwAGwAaQBjAGEAdABpAG8AbgBOAGEAbQBlACAAPQAgACcATQBpAGMAcgBvAHMAbwBmAHQAIABWAGkAcwB1AGEAbAAgAFMAdAB1AGQAaQBvACAAQwBvAGQAZQAnAAoACgAkAHUAcgBsAFQAYQBnAHMAIAA9ACAAJwBoAHQAdABwAHMAOgAvAC8AYQBwAGkALgBnAGkAdABoAHUAYgAuAGMAbwBtAC8AcgBlAHAAbwBzAC8ATQBpAGMAcgBvAHMAbwBmAHQALwB2AHMAYwBvAGQAZQAvAHQAYQBnAHMAJwAKACQAdQByAGwATABhAHQAZQBzAHQARABvAHcAbgBsAG8AYQBkACAAPQAgACcAaAB0AHQAcABzADoALwAvAGEAegA3ADYANAAyADkANQAuAHYAbwAuAG0AcwBlAGMAbgBkAC4AbgBlAHQALwBzAHQAYQBiAGwAZQAvAHsAMAB9AC8AVgBTAEMAbwBkAGUAUwBlAHQAdQBwAC0AeAA2ADQALQB7ADEAfQAuAGUAeABlACcACgAKAFsATgBlAHQALgBTAGUAcgB2AGkAYwBlAFAAbwBpAG4AdABNAGEAbgBhAGcAZQByAF0AOgA6AFMAZQBjAHUAcgBpAHQAeQBQAHIAbwB0AG8AYwBvAGwAIAA9ACAAWwBOAGUAdAAuAFMAZQBjAHUAcgBpAHQAeQBQAHIAbwB0AG8AYwBvAGwAVAB5AHAAZQBdADoAOgBUAGwAcwAxADIACgAkAHQAYQBnAHMAIAA9ACAAKABJAG4AdgBvAGsAZQAtAFcAZQBiAFIAZQBxAHUAZQBzAHQAIAAtAFUAcgBpACAAJAB1AHIAbABUAGEAZwBzACAALQBVAHMAZQBCAGEAcwBpAGMAUABhAHIAcwBpAG4AZwAgAC0ARQByAHIAbwByAEEAYwB0AGkAbwBuACAAUwB0AG8AcAApAC4AQwBvAG4AdABlAG4AdAAgAHwAIABDAG8AbgB2AGUAcgB0AEYAcgBvAG0ALQBKAHMAbwBuAAoAJAB2AGUAcgBzAGkAbwBuAHMAIAA9ACAAJAB0AGEAZwBzACAAfAAgAFcAaABlAHIAZQAtAE8AYgBqAGUAYwB0ACAAewAgACQAXwAuAG4AYQBtAGUAIAAtAGEAcwAgAFsAdgBlAHIAcwBpAG8AbgBdACAAfQAKAFsAdgBlAHIAcwBpAG8AbgBdACAAJAB2AGUAcgBzAGkAbwBuAEwAYQB0AGUAcwB0ACAAPQAgACgAJAB2AGUAcgBzAGkAbwBuAHMAIAB8ACAAUwBvAHIAdAAtAE8AYgBqAGUAYwB0ACAALQBQAHIAbwBwAGUAcgB0AHkAIAAnAG4AYQBtAGUAJwAgAC0ARABlAHMAYwBlAG4AZABpAG4AZwApAFsAMABdAC4AbgBhAG0AZQAKACQAcwBoAGEATABhAHQAZQBzAHQAIAA9ACAAKAAkAHYAZQByAHMAaQBvAG4AcwAgAHwAIABTAG8AcgB0AC0ATwBiAGoAZQBjAHQAIAAtAFAAcgBvAHAAZQByAHQAeQAgACcAbgBhAG0AZQAnACAALQBEAGUAcwBjAGUAbgBkAGkAbgBnACkAWwAwAF0ALgBjAG8AbQBtAGkAdAAuAHMAaABhAAoAWwB2AGUAcgBzAGkAbwBuAF0AIAAkAHYAZQByAHMAaQBvAG4ASQBuAHMAdABhAGwAbABlAGQAIAA9ACAAJABuAHUAbABsAAoACgAkAHUAbgBpAG4AcwB0AGEAbABsAEsAZQB5AHMAIAA9ACAAQAAoAAoAIAAgACAAIAAnAFIAZQBnAGkAcwB0AHIAeQA6ADoASABLAEUAWQBfAEwATwBDAEEATABfAE0AQQBDAEgASQBOAEUAXABTAE8ARgBUAFcAQQBSAEUAXABNAGkAYwByAG8AcwBvAGYAdABcAFcAaQBuAGQAbwB3AHMAXABDAHUAcgByAGUAbgB0AFYAZQByAHMAaQBvAG4AXABVAG4AaQBuAHMAdABhAGwAbABcACcACgAgACAAIAAgACcAUgBlAGcAaQBzAHQAcgB5ADoAOgBIAEsARQBZAF8ATABPAEMAQQBMAF8ATQBBAEMASABJAE4ARQBcAFMATwBGAFQAVwBBAFIARQBcAFcATwBXADYANAAzADIATgBvAGQAZQBcAE0AaQBjAHIAbwBzAG8AZgB0AFwAVwBpAG4AZABvAHcAcwBcAEMAdQByAHIAZQBuAHQAVgBlAHIAcwBpAG8AbgBcAFUAbgBpAG4AcwB0AGEAbABsAFwAJwAKACkACgAKAGYAbwByAGUAYQBjAGgAIAAoACQAdQBuAGkAbgBzAHQAYQBsAGwASwBlAHkAIABpAG4AIAAkAHUAbgBpAG4AcwB0AGEAbABsAEsAZQB5AHMAKQAgAHsACgAgACAAIAAgAGkAZgAgACgAVABlAHMAdAAtAFAAYQB0AGgAIAAkAHUAbgBpAG4AcwB0AGEAbABsAEsAZQB5ACkAIAB7AAoAIAAgACAAIAAgACAAIAAgAGYAbwByAGUAYQBjAGgAIAAoACQAaQBuAHMAdABhAGwAbABlAGQAUwBvAGYAdAB3AGEAcgBlACAAaQBuACAAKABHAGUAdAAtAEMAaABpAGwAZABJAHQAZQBtACAAJAB1AG4AaQBuAHMAdABhAGwAbABLAGUAeQApACkAIAB7AAoAIAAgACAAIAAgACAAIAAgACAAIAAgACAAJABpAG4AcwB0AGEAbABsAGUAZABTAG8AZgB0AHcAYQByAGUAUAByAG8AcABlAHIAdABpAGUAcwAgAD0AIABHAGUAdAAtAEkAdABlAG0AUAByAG8AcABlAHIAdAB5ACAAKAAnAFIAZQBnAGkAcwB0AHIAeQA6ADoAewAwAH0AJwAgAC0AZgAgACQAaQBuAHMAdABhAGwAbABlAGQAUwBvAGYAdAB3AGEAcgBlAC4ATgBhAG0AZQApAAoACgAgACAAIAAgACAAIAAgACAAIAAgACAAIABpAGYAIAAoACQAaQBuAHMAdABhAGwAbABlAGQAUwBvAGYAdAB3AGEAcgBlAFAAcgBvAHAAZQByAHQAaQBlAHMALgBEAGkAcwBwAGwAYQB5AE4AYQBtAGUAIAAtAGUAcQAgACQAYQBwAHAAbABpAGMAYQB0AGkAbwBuAE4AYQBtAGUAKQAgAHsACgAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgAFcAcgBpAHQAZQAtAFYAZQByAGIAbwBzAGUAIAAoACcAVgBTACAAQwBvAGQAZQAgAGYAbwB1AG4AZAA6ACAAewAwAH0AJwAgAC0AZgAgACgAJABpAG4AcwB0AGEAbABsAGUAZABTAG8AZgB0AHcAYQByAGUAUAByAG8AcABlAHIAdABpAGUAcwAgAHwAIABPAHUAdAAtAFMAdAByAGkAbgBnACkAKQAKACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAWwB2AGUAcgBzAGkAbwBuAF0AIAAkAHYAZQByAHMAaQBvAG4ASQBuAHMAdABhAGwAbABlAGQAIAA9ACAAJABpAG4AcwB0AGEAbABsAGUAZABTAG8AZgB0AHcAYQByAGUAUAByAG8AcABlAHIAdABpAGUAcwAuAEQAaQBzAHAAbABhAHkAVgBlAHIAcwBpAG8AbgAKACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAACgAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgAFcAcgBpAHQAZQAtAFYAZQByAGIAbwBzAGUAIAAoACcAVgBTACAAQwBvAGQAZQAgAGYAbwB1AG4AZAA6ACAAewAwAH0AJwAgAC0AZgAgACQAdgBlAHIAcwBpAG8AbgBJAG4AcwB0AGEAbABsAGUAZAApAAoAIAAgACAAIAAgACAAIAAgACAAIAAgACAAfQAKACAAIAAgACAAIAAgACAAIAB9AAoAIAAgACAAIAB9AAoAfQAKAAoAaQBmACAAKAAkAHYAZQByAHMAaQBvAG4ASQBuAHMAdABhAGwAbABlAGQAIAAtAG4AZQAgACQAdgBlAHIAcwBpAG8AbgBMAGEAdABlAHMAdAApACAAewAKACAAIAAgACAAJAB2AHMAYwBvAGQAZQBTAGUAdAB1AHAAIAA9ACAAJwB7ADAAfQBcAFYAUwBDAG8AZABlAFMAZQB0AHUAcAAuAGUAeABlACcAIAAtAGYAIAAkAGUAbgB2ADoAVABlAG0AcAAKACAAIAAgACAASQBuAHYAbwBrAGUALQBXAGUAYgBSAGUAcQB1AGUAcwB0ACAALQBVAHIAaQAgACgAJAB1AHIAbABMAGEAdABlAHMAdABEAG8AdwBuAGwAbwBhAGQAIAAtAGYAIAAkAHMAaABhAEwAYQB0AGUAcwB0ACwAIAAkAHYAZQByAHMAaQBvAG4ATABhAHQAZQBzAHQAKQAgAC0ATwB1AHQARgBpAGwAZQAgACQAdgBzAGMAbwBkAGUAUwBlAHQAdQBwACAALQBVAHMAZQBCAGEAcwBpAGMAUABhAHIAcwBpAG4AZwAKAAoAIAAgACAAIAB3AGgAaQBsAGUAIAAoAEcAZQB0AC0AUAByAG8AYwBlAHMAcwAgACcAQwBvAGQAZQAnACAALQBJAG4AYwBsAHUAZABlAFUAcwBlAHIATgBhAG0AZQAgAC0ARQByAHIAbwByAEEAYwB0AGkAbwBuACAAUwBpAGwAZQBuAHQAbAB5AEMAbwBuAHQAaQBuAHUAZQApACAAewAKACAAIAAgACAAIAAgACAAIABXAHIAaQB0AGUALQBWAGUAcgBiAG8AcwBlACAAKAAnAFYAUwAgAEMAbwBkAGUAIABpAHMAIABjAHUAcgByAGUAbgB0AGwAeQAgAGkAbgAgAHUAcwBlACAAYgB5ACAAewAwAH0AOwAgAHcAaQBsAGwAIABjAGgAZQBjAGsAIABhAGcAYQBpAG4AIABpAG4AIABhACAAbQBpAG4AdQB0AGUAIAAuAC4ALgAnACAALQBmACAAKAAoACgARwBlAHQALQBQAHIAbwBjAGUAcwBzACAAJwBDAG8AZABlACcAIAAtAEkAbgBjAGwAdQBkAGUAVQBzAGUAcgBOAGEAbQBlACkALgBVAHMAZQByAE4AYQBtAGUAIAB8ACAAUwBvAHIAdAAtAE8AYgBqAGUAYwB0ACAALQBVAG4AaQBxAHUAZQApACAALQBqAG8AaQBuACAAJwAsACAAJwApACkACgAgACAAIAAgACAAIAAgACAAUwB0AGEAcgB0AC0AUwBsAGUAZQBwACAALQBTAGUAYwBvAG4AZABzACAANgAwAAoAIAAgACAAIAB9AAoACgAgACAAIAAgAFcAcgBpAHQAZQAtAFYAZQByAGIAbwBzAGUAIAAnAEkAbgBzAHQAYQBsAGwAaQBuAGcAIABsAGEAdABlAHMAdAAgAHYAZQByAHMAaQBvAG4ALgAuAC4AJwAKACAAIAAgACAAUwB0AGEAcgB0AC0AUAByAG8AYwBlAHMAcwAgAC0ARgBpAGwAZQBQAGEAdABoACAAJAB2AHMAYwBvAGQAZQBTAGUAdAB1AHAAIAAtAEEAcgBnAHUAbQBlAG4AdABMAGkAcwB0ACAAIgAvAHMAaQBsAGUAbgB0ACAALwBtAGUAcgBnAGUAdABhAHMAawBzAD0AIQByAHUAbgBjAG8AZABlACAALwBuAG8AcgBlAHMAdABhAHIAdAAiACAALQBXAGEAaQB0AAoAfQAgAGUAbABzAGUAIAB7AAoAIAAgACAAIABXAHIAaQB0AGUALQBWAGUAcgBiAG8AcwBlACAAJwBMAGEAdABlAHMAdAAgAHYAZQByAHMAaQBvAG4AIABhAGwAcgBlAGEAZAB5ACAAaQBuAHMAdABhAGwAbABlAGQALgAnAAoAfQA="
```

Might want to re-base64 it to be sure I didn't fix any bugs since posting this. I likely won't come back and update this.

# Download and Execute

❗️ **Seriously, don't do it this way unless you fork this repo and point it at your fork.**

```bash
powershell.exe -W H -Ex B -NoP -NonI "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest 'https://raw.githubusercontent.com/UNT-CAS/Update-VSCode/master/Update-VSCode.ps1' -UseBasicParsing | Invoke-Expression"
```
