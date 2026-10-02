param(
    [Parameter(Mandatory = $true)][string]$ArgLine,
    [string]$Ripes = ".\Ripes.exe",
    [int]$Runs = 5
)

for ($i = 1; $i -le $Runs; $i++) {
    $out = "run$i.txt"
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $p = Start-Process -FilePath $Ripes -ArgumentList $ArgLine `
        -NoNewWindow -PassThru -RedirectStandardOutput $out
    $peak = 0
    while (-not $p.HasExited) {
        try {
            $p.Refresh()
            if ($p.PeakWorkingSet64 -gt $peak) { $peak = $p.PeakWorkingSet64 }
        } catch {}
        Start-Sleep -Milliseconds 50
    }
    $sw.Stop()
    "---- run $i : whole-process wall time = $($sw.ElapsedMilliseconds) ms, peak memory = {0:N1} MiB" -f ($peak / 1MB)
    Get-Content $out
}