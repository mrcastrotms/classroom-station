<#
===========================================================================
 Classroom Workstation Bootstrap: Math App & Moodle Auto-Launch
 Target: Windows Student Terminals
===========================================================================
#>

Write-Host "--- 1. CONFIGURING STUDENT ENVIRONMENT ---" -ForegroundColor Cyan
$installDir = "$env:LOCALAPPDATA\MayanClassroom"
if (-not (Test-Path -Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

$dashboardUrl = "https://mrcastro.vercel.app/?view=dashboard"
$moodleUrl    = "https://www.mayanschool.net/moodlepkpri/login/index.php?loginredirect=1"

Write-Host "--- 2. DETECTING BROWSER ENGINE ---" -ForegroundColor Cyan
$browserPath = $null
$chromeCandidates = @(
    "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
)
$edgeCandidates = @(
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
    "${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe"
)

foreach ($path in $chromeCandidates) {
    if (Test-Path -Path $path) { $browserPath = $path; break }
}

if (-not $browserPath) {
    foreach ($path in $edgeCandidates) {
        if (Test-Path -Path $path) { $browserPath = $path; break }
    }
}

Write-Host "Using browser: $browserPath" -ForegroundColor Yellow

Write-Host "--- 3. CREATING LAUNCH RUNNER ---" -ForegroundColor Cyan
$runnerScript = "$installDir\launch_apps.ps1"
$runnerContent = @"
`$browser = "$browserPath"
`$mathUrl = "$dashboardUrl"
`$moodleUrl = "$moodleUrl"

if (`$browser -and (Test-Path `$browser)) {
    # Launch Dashboard & Moodle in focused window tabs
    Start-Process "`$browser" -ArgumentList "--new-window `"`$mathUrl`" `"`$moodleUrl`""
} else {
    Start-Process "`$mathUrl"
    Start-Process "`$moodleUrl"
}
"@
Set-Content -Path $runnerScript -Value $runnerContent -Force

Write-Host "--- 4. INSTALLING DESKTOP & STARTUP SHORTCUTS ---" -ForegroundColor Cyan
$wsh = New-Object -ComObject WScript.Shell

# Desktop shortcut
$desktopPath = [System.IO.Path]::Combine($env:USERPROFILE, "Desktop")
$desktopShortcut = $wsh.CreateShortcut("$desktopPath\Classroom Portal.lnk")
$desktopShortcut.TargetPath = "powershell.exe"
$desktopShortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$runnerScript`""
if ($browserPath) { $desktopShortcut.IconLocation = "$browserPath,0" }
$desktopShortcut.Save()

# User Startup shortcut (boots automatically on student login)
$startupFolder = $wsh.SpecialFolders("Startup")
$startupShortcut = $wsh.CreateShortcut("$startupFolder\ClassroomPortalStartup.lnk")
$startupShortcut.TargetPath = "powershell.exe"
$startupShortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$runnerScript`""
if ($browserPath) { $startupShortcut.IconLocation = "$browserPath,0" }
$startupShortcut.Save()

Write-Host "--- 5. LAUNCHING WORKSPACE NOW ---" -ForegroundColor Green
& powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "$runnerScript"

Write-Host "Deployment complete." -ForegroundColor Green
