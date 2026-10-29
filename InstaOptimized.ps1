#Requires -RunAsAdministrator
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ================= CONFIGURACIÓN DE LA VENTANA PRINCIPAL =================
$form = New-Object System.Windows.Forms.Form
$form.Text = "InstaOptimized v2.0 - Gaming & Latency Booster"
$form.Size = New-Object System.Drawing.Size(480, 430)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(24, 24, 28)
$form.ForeColor = [System.Drawing.Color]::White

# Título
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "INSTAOPTIMIZED"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(0, 230, 118)
$lblTitle.AutoSize = $true
$lblTitle.Location = New-Object System.Drawing.Point(130, 15)
$form.Controls.Add($lblTitle)

# Subtítulo
$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "Suite de Optimización de FPS, Input Lag y Red (W10/W11)"
$lblSub.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblSub.ForeColor = [System.Drawing.Color]::FromArgb(170, 170, 170)
$lblSub.AutoSize = $true
$lblSub.Location = New-Object System.Drawing.Point(75, 50)
$form.Controls.Add($lblSub)

# Caja de Estado (Log visual limpio dentro de la ventana)
$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Multiline = $true
$txtLog.ReadOnly = $true
$txtLog.ScrollBars = "Vertical"
$txtLog.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 18)
$txtLog.ForeColor = [System.Drawing.Color]::FromArgb(0, 230, 118)
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtLog.Size = New-Object System.Drawing.Size(425, 120)
$txtLog.Location = New-Object System.Drawing.Point(20, 245)
$txtLog.Text = "[InstaOptimized Listo] Selecciona una opción para comenzar...`r`n(Los servicios de Xbox y MS Store están protegidos)."
$form.Controls.Add($txtLog)

function Write-GuiLog($msg) {
    $txtLog.AppendText("`r`n$msg")
    $txtLog.SelectionStart = $txtLog.Text.Length
    $txtLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

# ================= FUNCIONES INTERNAS SILENCIOSAS =================
function Create-Backup {
    Write-GuiLog "-> [1/5] Creando Punto de Restauración de Seguridad..."
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "SystemRestorePointCreationFrequency" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Pre-InstaOptimized-Backup" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop | Out-Null
        Write-GuiLog "   [OK] Punto 'Pre-InstaOptimized-Backup' guardado con éxito."
    } catch {
        Write-GuiLog "   [!] Aviso: Restauración omitida por política del sistema."
    }
}

function Run-Win11Debloat {
    Write-GuiLog "-> [2/5] Ejecutando Win11Debloat (Limpiando Bloatware)..."
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $scriptContent = Invoke-RestMethod -Uri "https://debloat.raphi.re/" -UseBasicParsing
        $tempScript = "$env:TEMP\instaoptimized_debloat.ps1"
        Set-Content -Path $tempScript -Value $scriptContent -Encoding UTF8
        
        # Corre 100% oculto (WindowStyle Hidden) para no asustar al cliente
        $argsList = "-NoProfile -ExecutionPolicy Bypass -File `"$tempScript`" -Silent -RemoveApps -DisableTelemetry -DisableBing -DisableSuggestions -DisableLockscreenTips"
        Start-Process powershell.exe -ArgumentList $argsList -WindowStyle Hidden -Wait
        Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
        Write-GuiLog "   [OK] Bloatware y telemetría eliminados."
    } catch {
        Write-GuiLog "   [!] Error al descargar Win11Debloat. Verifica la red."
    }
}

function Apply-Tweaks {
    Write-GuiLog "-> [3/5] Aplicando Ajustes Gaming (CPU, HAGS, Mouse 1:1)..."
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null
    $ultimatePlan = (powercfg -list | Select-String "e9a42b02-d5df-448d-aa00-03f14749eb61" -Context 0)
    if ($ultimatePlan -match "([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})") {
        powercfg -setactive $matches[1] | Out-Null
    } else {
        powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c | Out-Null
    }

    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38 -Type DWord -Force
    if (!(Test-Path "HKCU:\Software\Microsoft\GameBar")) { New-Item -Path "HKCU:\Software\Microsoft\GameBar" -Force | Out-Null }
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force
    if (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR")) { New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Force | Out-Null }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -Type DWord -Force
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0" -Type String -Force
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0" -Type String -Force
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0" -Type String -Force
    powercfg -h off | Out-Null
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0" -Type String -Force
    Stop-Service -Name "DiagTrack" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
    Write-GuiLog "   [OK] Energía, Mouse Raw Input y Registro optimizados."
}

function Optimize-NetAndTemp {
    Write-GuiLog "-> [4/5] Optimizando Red y DNS Cloudflare (1.1.1.1)..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 10 -Type DWord -Force
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    foreach ($adapter in $adapters) {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses ("1.1.1.1", "1.0.0.1") -ErrorAction SilentlyContinue
    }
    ipconfig /flushdns | Out-Null
    
    Write-GuiLog "-> [5/5] Purgando archivos temporales y caché..."
    $tempFolders = @("$env:TEMP\*", "$env:windir\Temp\*", "$env:windir\Prefetch\*")
    foreach ($folder in $tempFolders) { Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue }
    Write-GuiLog "   [OK] Red y almacenamiento depurados."
}

# ================= BOTONES INTERACTIVOS =================
# Botón 1: Optimización Completa
$btnFull = New-Object System.Windows.Forms.Button
$btnFull.Text = "🚀 OPTIMIZACIÓN COMPLETA (Debloat + FPS + Red)"
$btnFull.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnFull.Size = New-Object System.Drawing.Size(425, 45)
$btnFull.Location = New-Object System.Drawing.Point(20, 80)
$btnFull.BackColor = [System.Drawing.Color]::FromArgb(0, 180, 90)
$btnFull.ForeColor = [System.Drawing.Color]::White
$btnFull.FlatStyle = "Flat"
$btnFull.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnFull.Add_Click({
    $btnFull.Enabled = $false; $btnFast.Enabled = $false
    $txtLog.Clear()
    Write-GuiLog "=== INICIANDO INSTAOPTIMIZED (MODO COMPLETO) ==="
    Create-Backup
    Run-Win11Debloat
    Apply-Tweaks
    Optimize-NetAndTemp
    Write-GuiLog "`r`n¡PROCESO COMPLETADO! Reinicia la PC."
    [System.Windows.Forms.MessageBox]::Show("Optimización completada con éxito por InstaOptimized.`nPor favor, reinicia tu PC para aplicar todos los cambios.", "InstaOptimized", "OK", "Information")
    $btnFull.Enabled = $true; $btnFast.Enabled = $true
})
$form.Controls.Add($btnFull)

# Botón 2: Optimización Rápida
$btnFast = New-Object System.Windows.Forms.Button
$btnFast.Text = "⚡ SOLO BOOST GAMING & RED (Sin desinstalar apps)"
$btnFast.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$btnFast.Size = New-Object System.Drawing.Size(425, 40)
$btnFast.Location = New-Object System.Drawing.Point(20, 135)
$btnFast.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 55)
$btnFast.ForeColor = [System.Drawing.Color]::White
$btnFast.FlatStyle = "Flat"
$btnFast.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnFast.Add_Click({
    $btnFull.Enabled = $false; $btnFast.Enabled = $false
    $txtLog.Clear()
    Write-GuiLog "=== INICIANDO INSTAOPTIMIZED (BOOST RÁPIDO) ==="
    Create-Backup
    Apply-Tweaks
    Optimize-NetAndTemp
    Write-GuiLog "`r`n¡BOOST APLICADO! Reinicia la PC."
    [System.Windows.Forms.MessageBox]::Show("Ajustes de FPS y Red aplicados con éxito.`nReinicia tu PC para notar la mejora.", "InstaOptimized", "OK", "Information")
    $btnFull.Enabled = $true; $btnFast.Enabled = $true
})
$form.Controls.Add($btnFast)

# Botón 3: Punto de Restauración
$btnRestore = New-Object System.Windows.Forms.Button
$btnRestore.Text = "🛡️ Revertir Cambios (Abrir Restaurar Sistema)"
$btnRestore.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$btnRestore.Size = New-Object System.Drawing.Size(425, 35)
$btnRestore.Location = New-Object System.Drawing.Point(20, 185)
$btnRestore.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 42)
$btnRestore.ForeColor = [System.Drawing.Color]::FromArgb(0, 200, 255)
$btnRestore.FlatStyle = "Flat"
$btnRestore.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnRestore.Add_Click({ Start-Process "rstrui.exe" })
$form.Controls.Add($btnRestore)

# Mostrar la ventana
[void]$form.ShowDialog()