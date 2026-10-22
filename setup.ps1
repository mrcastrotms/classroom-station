<#
===========================================================================
 Classroom Workstation Bootstrap: Math App & Moodle Auto-Launch
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

if ($browserPath) {
    Write-Host "Detected browser: $browserPath" -ForegroundColor Green
    $targetExe = $browserPath
    $targetArgs = "--new-window `"$dashboardUrl`" `"$moodleUrl`""
    $icon = "$browserPath,0"
} else {
    Write-Host "No standalone browser path matched; using system default handler." -ForegroundColor Yellow
    $targetExe = "cmd.exe"
    $targetArgs = "/c start `"`" `"$dashboardUrl`" && start `"`" `"$moodleUrl`""
    $icon = "shell32.dll,220"
}

Write-Host "--- 2. CREATING WORKSTATION SHORTCUTS ---" -ForegroundColor Cyan
$wsh = New-Object -ComObject WScript.Shell

# 1. Desktop Shortcut
$desktopPath = [System.IO.Path]::Combine($env:USERPROFILE, "Desktop")
$desktopShortcut = $wsh.CreateShortcut("$desktopPath\Classroom Portal.lnk")
$desktopShortcut.TargetPath = $targetExe
$desktopShortcut.Arguments = $targetArgs
$desktopShortcut.IconLocation = $icon
$desktopShortcut.Save()
Write-Host "Created Desktop Shortcut: Classroom Portal.lnk" -ForegroundColor Green

# 2. Startup Shortcut (auto-boots tabs on student login)
$startupFolder = $wsh.SpecialFolders("Startup")
$startupShortcut = $wsh.CreateShortcut("$startupFolder\ClassroomPortalStartup.lnk")
$startupShortcut.TargetPath = $targetExe
$startupShortcut.Arguments = $targetArgs
$startupShortcut.IconLocation = $icon
$startupShortcut.Save()
Write-Host "Created Startup Shortcut: ClassroomPortalStartup.lnk" -ForegroundColor Green

Write-Host "--- 3. LAUNCHING URLS IMMEDIATELY ---" -ForegroundColor Cyan
if ($browserPath) {
    Start-Process -FilePath $browserPath -ArgumentList "--new-window `"$dashboardUrl`" `"$moodleUrl`""
} else {
    Start-Process $dashboardUrl
    Start-Process $moodleUrl
}

Write-Host "`n--- SETUP COMPLETE: Math App & Moodle Deployed ---" -ForegroundColor Green
