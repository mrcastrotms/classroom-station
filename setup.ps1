<#
===========================================================================
 Classroom Station: Production Auto-Boot Deployment
 Target: Windows Student Terminals
===========================================================================
#>

$dashboardUrl = "https://mrcastro.vercel.app/?view=dashboard"
$moodleUrl    = "https://www.mayanschool.net/moodlepkpri/login/index.php?loginredirect=1"

Write-Host "--- 1. LOCATING INSTALLED BROWSER ---" -ForegroundColor Cyan

$browserPath = $null
$candidates = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
    "$env:ProgramFiles\Mozilla Firefox\firefox.exe",
    "${env:ProgramFiles(x86)}\Mozilla Firefox\firefox.exe"
)

foreach ($path in $candidates) {
    if (Test-Path -Path $path) {
        $browserPath = $path
        break
    }
}

$stationDir = "$env:LOCALAPPDATA\ClassroomStation"
if (-not (Test-Path -Path $stationDir)) {
    New-Item -ItemType Directory -Path $stationDir -Force | Out-Null
}

Write-Host "--- 2. CREATING DELAYED LAUNCH BATCH RUNNER ---" -ForegroundColor Cyan
$batPath = "$stationDir\boot_classroom.bat"

# The 8-second delay allows Windows Explorer and Wi-Fi to establish connection first
if ($browserPath) {
    Write-Host "Configured for: $browserPath" -ForegroundColor Green
    $batContent = @"
@echo off
timeout /t 8 /nobreak >nul
start "" "$browserPath" --new-window "$dashboardUrl" "$moodleUrl"
exit
"@
} else {
    Write-Host "Configured for: Default Windows Browser" -ForegroundColor Yellow
    $batContent = @"
@echo off
timeout /t 8 /nobreak >nul
start "" "$dashboardUrl"
start "" "$moodleUrl"
exit
"@
}

Set-Content -Path $batPath -Value $batContent -Force
Write-Host "Created: $batPath" -ForegroundColor Green

Write-Host "--- 3. CREATING SILENT VBSCRIPT WRAPPER ---" -ForegroundColor Cyan
# This launches the batch file with 0 (hidden window) so students do not see a black CMD popup
$vbsPath = "$stationDir\silent_boot.vbs"
$vbsContent = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run chr(34) & "$batPath" & chr(34), 0, False
"@
Set-Content -Path $vbsPath -Value $vbsContent -Force

Write-Host "--- 4. ENFORCING PERSISTENCE ---" -ForegroundColor Cyan

# Mechanism A: Registry Run Key pointing to the silent VBS
$regKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Set-ItemProperty -Path $regKey -Name "MayanClassroomAutoBoot" -Value "wscript.exe `"$vbsPath`"" -Force
Write-Host "[OK] Registry Run Key enabled." -ForegroundColor Green

# Mechanism B: Task Scheduler with 15-second logon delay
$taskName = "MayanClassroomAutoBoot"
schtasks /delete /tn "$taskName" /f 2>$null | Out-Null
$action = "wscript.exe `"$vbsPath`""
schtasks /create /tn "$taskName" /tr "$action" /sc ONLOGON /delay 0000:15 /f 2>$null | Out-Null
Write-Host "[OK] Scheduled Task registered with logon delay." -ForegroundColor Green

# Mechanism C: Startup Folder Shortcut
$wsh = New-Object -ComObject WScript.Shell
$startupFolder = $wsh.SpecialFolders("Startup")
$startupLnk = "$startupFolder\ClassroomPortal.lnk"
$shortcut = $wsh.CreateShortcut($startupLnk)
$shortcut.TargetPath = "wscript.exe"
$shortcut.Arguments = "`"$vbsPath`""
$shortcut.WindowStyle = 7
if ($browserPath) { $shortcut.IconLocation = "$browserPath,0" }
$shortcut.Save()
Write-Host "[OK] Startup Shortcut placed." -ForegroundColor Green

# Desktop Shortcut (immediate launch, no wait)
$desktopPath = [System.IO.Path]::Combine($env:USERPROFILE, "Desktop")
$desktopLnk = "$desktopPath\Classroom Portal.lnk"
$deskShortcut = $wsh.CreateShortcut($desktopLnk)
if ($browserPath) {
    $deskShortcut.TargetPath = $browserPath
    $deskShortcut.Arguments = "--new-window `"$dashboardUrl`" `"$moodleUrl`""
    $deskShortcut.IconLocation = "$browserPath,0"
} else {
    $deskShortcut.TargetPath = "cmd.exe"
    $deskShortcut.Arguments = "/c start `"`" `"$dashboardUrl`" && start `"`" `"$moodleUrl`""
    $deskShortcut.IconLocation = "shell32.dll,220"
}
$deskShortcut.Save()
Write-Host "[OK] Desktop manual launch icon placed." -ForegroundColor Green

Write-Host "--- 5. LAUNCHING TEST RUN ---" -ForegroundColor Cyan
Start-Process "wscript.exe" -ArgumentList "`"$vbsPath`""

Write-Host "`n=== SETUP SUCCESSFUL ===" -ForegroundColor Green
