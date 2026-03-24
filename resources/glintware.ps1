$glintArt = @'
  /$$$$$$  /$$ /$$             /$$     /$$      /$$                              
 /$$__  $$| $$|__/            | $$    | $$  /$ | $$                              
| $$  \__/| $$ /$$ /$$$$$$$  /$$$$$$  | $$ /$$$| $$  /$$$$$$   /$$$$$$   /$$$$$$ 
| $$ /$$$$| $$| $$| $$__  $$|_  $$_/  | $$/$$ $$ $$ |____  $$ /$$__  $$ /$$__  $$
| $$|_  $$| $$| $$| $$  \ $$  | $$    | $$$$_  $$$$  /$$$$$$$| $$  \__/| $$$$$$$$
| $$  \ $$| $$| $$| $$  | $$  | $$ /$$| $$$/ \  $$$ /$$__  $$| $$      | $$_____/
|  $$$$$$/| $$| $$| $$  | $$  |  $$$$/| $$/   \  $$|  $$$$$$$| $$      |  $$$$$$$
 \______/ |__/|__/|__/  |__/   \___/  |__/     \__/ \_______/|__/       \_______/
'@

Write-Host $glintArt -ForegroundColor DarkRed
Write-Host ""
Write-Host "Loading..."
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$boot = Get-WinEvent -FilterHashtable @{ LogName='System'; Id=6005 } -MaxEvents 1
$startTime = $boot.TimeCreated
$tz = Get-TimeZone
$UserTime = $tz.DisplayName
$Bias = $tz.BaseUtcOffset
$Day = $tz.SupportsDaylightSavingTime
$logs = @("System","Application","Security")
$events = @()

foreach ($log in $logs) {
    try {
        $tmp = Get-WinEvent -FilterHashtable @{ LogName = $log; StartTime = $startTime } -MaxEvents 300
        foreach ($e in $tmp) {
            $msg = $e.Message
            if ($msg.Length -gt 150) { $msg = $msg.Substring(0,150) }
            $events += [PSCustomObject]@{
                Time      = $e.TimeCreated
                Type      = "EVENT"
                Log       = $log
                EventID   = $e.Id
                Process   = ""
                Message   = ($msg -replace "`r|`n"," ")
            }
            Start-Sleep -Milliseconds 5
        }
    } catch {}
}

$processes = Get-Process | Where-Object { $_.StartTime -ge $startTime } | ForEach-Object {
    Start-Sleep -Milliseconds 5
    [PSCustomObject]@{
        Time      = $_.StartTime
        Type      = "PROCESS"
        Log       = "LIVE"
        EventID   = ""
        Process   = $_.ProcessName
        Message   = "PID: $($_.Id)"
    }
}

$Glint = $events + $processes | Sort-Object Time -Descending
$sw.Stop()
Write-Host "Loading completed in $($sw.Elapsed.TotalSeconds) seconds." -ForegroundColor Green
$logFolder = Join-Path -Path $PSScriptRoot -ChildPath "script_log"
if (-not (Test-Path $logFolder)) { New-Item -ItemType Directory -Path $logFolder | Out-Null }
$logFile = Join-Path $logFolder -ChildPath "$(Get-Date -Format 'yyyy-MM-dd').txt"
$Glint | ForEach-Object {
    "{0} [{1}] {2} - {3} : {4}" -f $_.Time, $_.Type, $_.Log, $_.EventID, $_.Message
} | Out-File -FilePath $logFile -Encoding UTF8
Write-Host "Log saved to $logFile" -ForegroundColor Cyan
$Glint | Out-GridView -PassThru -Title "GlintWare ($($Glint.Count)) - TimeZone: $UserTime -> Bias: $Bias - DST: $Day"

# Created by Itelcan3 and 85cs for a better control -GlintWare