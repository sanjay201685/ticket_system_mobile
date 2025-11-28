# Find and Open APK File
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Ticket System APK Location Finder" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$projectPath = "D:\Android_projects\ticket_system"
$apkPaths = @(
    "$projectPath\build\app\outputs\flutter-apk\app-release.apk",
    "$projectPath\build\app\outputs\apk\release\app-release.apk"
)

$foundApk = $null

foreach ($apkPath in $apkPaths) {
    if (Test-Path $apkPath) {
        $file = Get-Item $apkPath
        Write-Host "✅ APK Found!" -ForegroundColor Green
        Write-Host "   Path: $($file.FullName)" -ForegroundColor Yellow
        Write-Host "   Size: $([math]::Round($file.Length / 1MB, 2)) MB" -ForegroundColor Yellow
        Write-Host "   Created: $($file.LastWriteTime)" -ForegroundColor Yellow
        Write-Host ""
        $foundApk = $file.FullName
        break
    }
}

if ($foundApk) {
    Write-Host "Opening file location..." -ForegroundColor Cyan
    Start-Process "explorer.exe" -ArgumentList "/select,`"$foundApk`""
    Write-Host ""
    Write-Host "The APK file location has been opened in Windows Explorer." -ForegroundColor Green
    Write-Host "You can now copy or move the APK file to your desired location." -ForegroundColor Green
} else {
    Write-Host "❌ APK file not found at expected locations." -ForegroundColor Red
    Write-Host "   Please rebuild the APK using: flutter build apk --release" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")








