# ============================================================
#  WhatsMyIP - APK Release Builder
# ============================================================

$env:ANDROID_HOME = "$env:USERPROFILE\gasapp_tools\android-sdk"
$env:PATH = "$env:USERPROFILE\gasapp_tools\android-sdk\platform-tools;$env:USERPROFILE\gasapp_tools\flutter\bin;" + $env:PATH
$FLUTTER = "$env:USERPROFILE\gasapp_tools\flutter\bin\flutter.bat"

Write-Host "Iniciando compilacion de WhatsMyIP Release APK..." -ForegroundColor Cyan
& $FLUTTER build apk --release

if ($LASTEXITCODE -eq 0) {
    $apkPath = "$PSScriptRoot\build\app\outputs\flutter-apk\app-release.apk"
    $targetApk = "C:\Users\pepor\Downloads\WhatsMyIP_release.apk"
    if (Test-Path $apkPath) {
        Copy-Item $apkPath $targetApk -Force
        $sizeMB = [math]::Round((Get-Item $targetApk).Length / 1MB, 2)
        Write-Host "APK generado exitosamente!" -ForegroundColor Green
        Write-Host "Copiado a: $targetApk" -ForegroundColor Green
        Write-Host "Tamano: $sizeMB MB" -ForegroundColor White
    }
} else {
    Write-Host "Error durante la compilacion del APK." -ForegroundColor Red
    exit $LASTEXITCODE
}
