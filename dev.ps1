# ============================================================
#  WhatsMyIP - Dev Launcher
#  Arranca el emulador Pixel_API_34 y la app de una sola vez
#  Uso: .\dev.ps1
# ============================================================

$FLUTTER   = "$env:USERPROFILE\gasapp_tools\flutter\bin\flutter.bat"
$EMULATOR  = "$env:USERPROFILE\gasapp_tools\android-sdk\emulator\emulator.exe"
$ADB       = "$env:USERPROFILE\gasapp_tools\android-sdk\platform-tools\adb.exe"
$AVD_NAME  = "Pixel_API_34"

$env:ANDROID_HOME = "$env:USERPROFILE\gasapp_tools\android-sdk"
$env:PATH = "$env:USERPROFILE\gasapp_tools\android-sdk\platform-tools;$env:USERPROFILE\gasapp_tools\flutter\bin;" + $env:PATH

Write-Host ""
Write-Host "  [WhatsMyIP] Dev Launcher" -ForegroundColor Cyan
Write-Host "  ------------------------" -ForegroundColor DarkGray

# 1. Limpiar procesos Dart y bloqueos de Flutter de sesiones previas
Write-Host "  [INFO] Verificando bloqueos de sesiones previas..." -ForegroundColor DarkGray
Get-Process -Name "dart" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 300
$flutterCache = "$env:USERPROFILE\gasapp_tools\flutter\bin\cache"
if (Test-Path $flutterCache) {
    Get-ChildItem -Path $flutterCache -Filter "*lock*" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
}

# 2. Comprobar estado del emulador y ADB
$emuProcess = Get-Process -Name "emulator", "qemu-system-x86_64" -ErrorAction SilentlyContinue
$avdPath = "$env:USERPROFILE\.android\avd\$AVD_NAME.avd"

if (-not $emuProcess) {
    if (Test-Path $avdPath) {
        Get-ChildItem -Path $avdPath -Filter "*.lock" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    }
    & $ADB kill-server 2>$null
    Start-Sleep -Milliseconds 500
    & $ADB start-server 2>$null
    Start-Sleep -Milliseconds 500
}

# Comprobar si el emulador ya esta online
$devices = & $ADB devices 2>&1
$isOnline = ($devices | Where-Object { $_ -match "emulator-\d+\s+device" }) -and $emuProcess
$isOffline = ($devices | Where-Object { $_ -match "emulator-\d+\s+offline" })

if ($isOffline -or ($emuProcess -and -not $isOnline)) {
    Write-Host "  [INFO] Emulador desconectado o no responde, reconectando ADB..." -ForegroundColor Yellow
    & $ADB reconnect offline 2>$null
    Start-Sleep -Seconds 2
    $devices = & $ADB devices 2>&1
    $isOnline = ($devices | Where-Object { $_ -match "emulator-\d+\s+device" })

    if (-not $isOnline) {
        Write-Host "  [AVISO] El emulador no responde. Reiniciando proceso..." -ForegroundColor Yellow
        Stop-Process -Name "emulator", "qemu-system-x86_64" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        if (Test-Path $avdPath) {
            Get-ChildItem -Path $avdPath -Filter "*.lock" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        }
        $emuProcess = $null
        & $ADB kill-server 2>$null
        Start-Sleep -Milliseconds 500
        & $ADB start-server 2>$null
        Start-Sleep -Milliseconds 500
    }
}

if ($isOnline) {
    Write-Host "  [OK] Emulador ya activo y conectado" -ForegroundColor Green
} else {
    if (-not $emuProcess) {
        Write-Host "  [INFO] Arrancando emulador $AVD_NAME..." -ForegroundColor White
        Start-Process -FilePath $EMULATOR -ArgumentList "-avd $AVD_NAME -dns-server 8.8.8.8 -gpu host" -WindowStyle Normal
    }

    Write-Host "  [INFO] Esperando conexion de Android con ADB..." -ForegroundColor White
    $connectWait = 0
    while ($connectWait -lt 30) {
        $devs = & $ADB devices 2>&1
        if ($devs | Where-Object { $_ -match "emulator-\d+\s+device" }) {
            break
        }
        Start-Sleep -Seconds 2
        $connectWait += 2
        Write-Host "  [...] Esperando al emulador ($($connectWait)s)..." -ForegroundColor DarkGray
    }

    # Esperar a que el sistema complete el arranque
    $booted = ""
    $attempts = 0
    while ($booted -ne "1" -and $attempts -lt 40) {
        Start-Sleep -Seconds 3
        $raw = & $ADB shell getprop sys.boot_completed 2>$null | Out-String
        $booted = $raw.Trim()
        $attempts++
        Write-Host "  [...] Esperando arranque de Android ($($attempts * 3)s)..." -ForegroundColor DarkGray
    }

    if ($booted -eq "1") {
        Write-Host "  [OK] Android listo!" -ForegroundColor Green
        Start-Sleep -Seconds 2
    } else {
        Write-Host "  [AVISO] Continuando lanzamiento de Flutter..." -ForegroundColor Yellow
    }
}

# 3. Detectar el ID del dispositivo emulador
$currentDevices = & $ADB devices 2>&1
$targetDevice = "android"
foreach ($line in $currentDevices) {
    if ($line -match "(emulator-\d+)\s+device") {
        $targetDevice = $Matches[1]
        break
    }
}

# 4. Lanzar la app con hot reload apuntando explicitamente al emulador
Write-Host "  [INFO] Lanzando WhatsMyIP en $targetDevice..." -ForegroundColor White
Write-Host ""
Write-Host "  Atajos utiles:" -ForegroundColor DarkGray
Write-Host "    r  = Hot reload (recarga cambios al instante)" -ForegroundColor DarkGray
Write-Host "    R  = Hot restart (reinicia la app)" -ForegroundColor DarkGray
Write-Host "    q  = Salir" -ForegroundColor DarkGray
Write-Host ""

Set-Location $PSScriptRoot
& $FLUTTER run -d $targetDevice
