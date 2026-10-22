<#
===========================================================================
 Classroom Station: Guaranteed Boot-Up Launcher
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

# Define root folder in local app data (survives student profile restrictions)
$stationDir = "$env:LOCALAPPDATA\ClassroomStation"
if (-not (Test-Path -Path $stationDir)) {
    New-Item -ItemType Directory -Path $stationDir -Force | Out-Null
}

Write-Host "--- 2. CREATING NATIVE BATCH LAUNCHER ---" -ForegroundColor Cyan
$batPath = "$stationDir\boot_classroom.bat"

if ($browserPath) {
    $batContent = @"
@echo off
start "" "$browserPath" --new-window "$dashboardUrl" "$moodleUrl"
exit
"@
} else {
    $batContent = @"
@echo off
start "" "$dashboardUrl"
start "" "$moodleUrl"
exit
"@
}

Set-Content -Path $batPath -Value $batContent -Force
Write-Host "Created Launcher: $batPath" -ForegroundColor Green

Write-Host "--- 3. REGISTERING PERSISTENT RUN METHODS ---" -ForegroundColor Cyan

# Method A: Windows Registry HKCU Run Key (Standard Windows startup mechanism)
$regKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Set-ItemProperty -Path $regKey -Name "MayanClassroomPortal" -Value "`"$batPath`"" -Force
Write-Host "[OK] Registry Run Key configured." -ForegroundColor Green

# Method B: Scheduled Task ONLOGON (Bypasses disabled startup items / user restrictions)
$taskName = "MayanClassroomAutoBoot"
schtasks /delete /tn "$taskName" /f 2>$null | Out-Null
$action = "`"$batPath`""
schtasks /create /tn "$taskName" /tr "$action" /sc ONLOGON /f | Out-Null
Write-Host "[OK] Scheduled Task (ONLOGON) registered." -ForegroundColor Green

# Method C: Windows Startup Folder Shortcut (Fallback)
$wsh = New-Object -ComObject WScript.Shell
$startupFolder = $wsh.SpecialFolders("Startup")
$startupLnk = "$startupFolder\ClassroomStation.lnk"
$shortcut = $wsh.CreateShortcut($startupLnk)
$shortcut.TargetPath = $batPath
$shortcut.WindowStyle = 7
if ($browserPath) { $shortcut.IconLocation = "$browserPath,0" }
$shortcut.Save()
Write-Host "[OK] Startup Folder link placed." -ForegroundColor Green

# Desktop Shortcut for manual access
$desktopPath = [System.IO.Path]::Combine($env:USERPROFILE, "Desktop")
$desktopLnk = "$desktopPath\Classroom Portal.lnk"
$deskShortcut = $wsh.CreateShortcut($desktopLnk)
$deskShortcut.TargetPath = $batPath
if ($browserPath) { $deskShortcut.IconLocation = "$browserPath,0" }
$deskShortcut.Save()
Write-Host "[OK] Desktop Icon placed." -ForegroundColor Green

Write-Host "`n--- 4. LAUNCHING IMMEDIATELY ---" -ForegroundColor Cyan
Start-Process -FilePath $batPath

Write-Host "`n--- SETUP FINISHED: Always boots Math App & Moodle ---" -ForegroundColor Green
