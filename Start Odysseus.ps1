# Start Odysseus.ps1
# ============================================

$launcherPath = "E:\odysseus\launch-windows.ps1"
$url = "http://127.0.0.1:7000"

# 1. Clear out any zombie processes hanging onto port 7000 from earlier crashes
Write-Host "[*] Cleaning up any previous stuck server instances..." -ForegroundColor Yellow
$stuckProcesses = Get-NetTCPConnection -LocalPort 7000 -ErrorAction SilentlyContinue
if ($stuckProcesses) {
    foreach ($connection in $stuckProcesses) {
        Stop-Process -Id $connection.OwningProcess -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Seconds 2
}

# 2. Verify launcher exists
if (-not (Test-Path $launcherPath)) {
    Write-Host "[X] Error: Could not find the launcher file at $launcherPath" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    Exit
}

# 3. Start Odysseus in its own independent minimized window
# This gives it a real console environment so Python/FastAPI don't crash, 
# while keeping it cleanly tucked away in your taskbar.
Write-Host "[*] Launching Odysseus server in background..." -ForegroundColor Green
Start-Process powershell.exe -ArgumentList "-NoExit -ExecutionPolicy Bypass -File `"$launcherPath`"" -WindowStyle Minimized

# 4. Wait until Odysseus is completely finished starting and listening
Write-Host "[*] Waiting for Odysseus to respond on port 7000..." -ForegroundColor Yellow
$serverReady = $false
while (-not $serverReady) {
    $connection = Test-NetConnection -ComputerName 127.0.0.1 -Port 7000 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    if ($connection.TcpTestSucceeded) {
        $serverReady = $true
    } else {
        Start-Sleep -Seconds 1
    }
}
Write-Host "[!] Odysseus server is up and accepting connections!" -ForegroundColor Cyan

# 5. Open Chrome in incognito mode (will pop up active on top)
Write-Host "[*] Opening incognito Chrome..." -ForegroundColor Green
try {
    Start-Process "chrome.exe" -ArgumentList "--incognito", $url -ErrorAction Stop
}
catch {
    $chromePaths = @(
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    )
    
    foreach ($path in $chromePaths) {
        if (Test-Path $path) {
            Start-Process $path -ArgumentList "--incognito", $url
            break
        }
    }
}

Write-Host "[!] Done! You can close this temporary setup window." -ForegroundColor Green
Start-Sleep -Seconds 2