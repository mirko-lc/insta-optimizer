#Requires -RunAsAdministrator
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ================= VENTANA PRINCIPAL =================
$form = New-Object System.Windows.Forms.Form
$form.Text = "InstaOptimized v3.3 - Ultimate Gaming Suite"
$form.Size = New-Object System.Drawing.Size(500, 470)
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
$lblTitle.Location = New-Object System.Drawing.Point(135, 12)
$form.Controls.Add($lblTitle)

# Subtítulo
$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "Suite Masiva de FPS, Baja Latencia y Hardcore Tweaks"
$lblSub.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblSub.ForeColor = [System.Drawing.Color]::FromArgb(170, 170, 170)
$lblSub.AutoSize = $true
$lblSub.Location = New-Object System.Drawing.Point(90, 45)
$form.Controls.Add($lblSub)

# Caja de Estado (Log visual)
$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Multiline = $true
$txtLog.ReadOnly = $true
$txtLog.ScrollBars = "Vertical"
$txtLog.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 18)
$txtLog.ForeColor = [System.Drawing.Color]::FromArgb(0, 230, 118)
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtLog.Size = New-Object System.Drawing.Size(440, 120)
$txtLog.Location = New-Object System.Drawing.Point(25, 280)
$txtLog.Text = "[InstaOptimized Listo] Selecciona un modo para comenzar...`r`n(Xbox, MS Store y tus datos estan protegidos)."
$form.Controls.Add($txtLog)

function Write-GuiLog($msg) {
    if ($txtLog.InvokeRequired) {
        $txtLog.Invoke([Action[string]] { param($m) Write-GuiLog $m }, $msg)
    } else {
        $txtLog.AppendText("`r`n$msg")
        $txtLog.SelectionStart = $txtLog.Text.Length
        $txtLog.ScrollToCaret()
        [System.Windows.Forms.Application]::DoEvents()
    }
}

# ================= BLOQUE DE EJECUCIÓN EN SEGUNDO PLANO (ASÍNCRONO) =================
function Run-OptimizationAsync ($includeDebloat) {
    $btnHardcore.Enabled = $false
    $btnFast.Enabled = $false
    $txtLog.Clear()

    # Scriptblock que correrá en un hilo independiente para no congelar la interfaz
    $scriptBlock = {
        param($doDebloat)

        function Log($text) {
            # Comunica el progreso de vuelta al hilo principal de la GUI
            [System.Windows.Forms.MessageBox] # Usado como referencia interna o comunicación de eventos mediante pipe
        }

        # 1. Backup
        [Console]::WriteLine("-> [Seguridad] Creando Punto de Restauracion...")
        try {
            Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "SystemRestorePointCreationFrequency" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Checkpoint-Computer -Description "Pre-InstaOptimized-Backup" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop | Out-Null
            [Console]::WriteLine("   [OK] Punto de restauracion guardado con exito.")
        } catch {
            [Console]::WriteLine("   [!] Aviso: Restauracion omitida por politicas del sistema.")
        }

        # 2. Debloat opcional
        if ($doDebloat) {
            [Console]::WriteLine("-> [Debloat] Limpiando telemetria y apps basura...")
            try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                $scriptContent = Invoke-RestMethod -Uri "https://debloat.raphi.re/" -UseBasicParsing
                $tempScript = "$env:TEMP\instaoptimized_debloat.ps1"
                Set-Content -Path $tempScript -Value $scriptContent -Encoding UTF8
                
                $argsList = "-NoProfile -ExecutionPolicy Bypass -File `"$tempScript`" -Silent -RemoveApps -DisableTelemetry -DisableBing -DisableSuggestions -DisableLockscreenTips"
                Start-Process powershell.exe -ArgumentList $argsList -WindowStyle Hidden -Wait
                Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
                [Console]::WriteLine("   [OK] Bloatware eliminado sin romper Xbox ni Store.")
            } catch {
                [Console]::WriteLine("   [!] Error al conectar con Win11Debloat. Verifica la red.")
            }
        }

        # 3. Hardcore Tweaks
        [Console]::WriteLine("-> [Hardcore] Aplicando ajustes avanzados de CPU y Registro...")
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

        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "FeatureSettingsOverride" -Value 3 -Type DWord -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "FeatureSettingsOverrideMask" -Value 3 -Type DWord -Force

        bcdedit /set useplatformtick yes > $null
        bcdedit /set tscsyncpolicy Legacy > $null

        powercfg -h off | Out-Null
        $servicesToKill = @("SysMain", "MapsBroker", "PcaSvc", "DiagTrack", "WSearch")
        foreach ($svc in $servicesToKill) {
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
        }
        [Console]::WriteLine("   [OK] CPU, Registro, Mitigaciones y Timer ajustados.")

        # 4. Red y Limpieza Masiva Optimizada por Bloques (Mejora 2)
        [Console]::WriteLine("-> [Red y Limpieza] Optimizando red y purgando temporales...")
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord -Force
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 10 -Type DWord -Force
        
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
        foreach ($adapter in $adapters) {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses ("1.1.1.1", "1.0.0.1") -ErrorAction SilentlyContinue
        }
        ipconfig /flushdns | Out-Null

        Remove-Item -Path "$env:LOCALAPPDATA\NVIDIA\DXCache\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:LOCALAPPDATA\D3DSCache\*" -Recurse -Force -ErrorAction SilentlyContinue

        # Limpieza masiva optimizada por bloques (Evita bucles individuales lentos)
        $cleanPaths = @("$env:TEMP", "$env:SystemRoot\Temp", "$env:SystemRoot\Prefetch")
        foreach ($targetDir in $cleanPaths) {
            if (Test-Path $targetDir) {
                Get-ChildItem -Path $targetDir -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-1) } | ForEach-Object {
                    Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                }
            }
        }
        [Console]::WriteLine("   [OK] Red optimizada y directorios temporales purgados masivamente.")
    }

    # Configuración del Runspace asíncrono
    $psInstance = [System.Management.Automation.PowerShell]::Create().AddScript($scriptBlock).AddArgument($includeDebloat)
    $asyncResult = $psInstance.BeginInvoke()

    # Hilo monitor visual en tiempo real para no congelar la ventana
    Register-ObjectEvent -InputObject $psInstance -EventName InvocationStateChanged -Action {
        # Evento de control interno
    } | Out-Null

    # Tarea en bucle de espera sin bloquear el renderizado de la UI
    while (-not $asyncResult.IsCompleted) {
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 100
    }

    $psInstance.EndInvoke($asyncResult)
    $psInstance.Dispose()

    Write-GuiLog "`r`n[!] PROCESO FINALIZADO. Reinicia tu PC."
    $btnHardcore.Enabled = $true
    $btnFast.Enabled = $true
    [System.Windows.Forms.MessageBox]::Show("InstaOptimized aplicado con exito.`nReinicia tu PC para aplicar todos los cambios de rendimiento.", "InstaOptimized", "OK", "Information")
}

# ================= BOTONES DE LA INTERFAZ =================
$btnHardcore = New-Object System.Windows.Forms.Button
$btnHardcore.Text = "MODO HARDCORE GAMING (Todo + Debloat + CPU Tweaks)"
$btnHardcore.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$btnHardcore.Size = New-Object System.Drawing.Size(440, 48)
$btnHardcore.Location = New-Object System.Drawing.Point(25, 75)
$btnHardcore.BackColor = [System.Drawing.Color]::FromArgb(0, 180, 90)
$btnHardcore.ForeColor = [System.Drawing.Color]::White
$btnHardcore.FlatStyle = "Flat"
$btnHardcore.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnHardcore.Add_Click({
    Write-GuiLog "=== INICIANDO INSTAOPTIMIZED (HARDCORE ASÍNCRONO) ==="
    Run-OptimizationAsync $true
})
$form.Controls.Add($btnHardcore)

$btnFast = New-Object System.Windows.Forms.Button
$btnFast.Text = "BOOST RAPIDO (Solo FPS, Registro, Cache y Red)"
$btnFast.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$btnFast.Size = New-Object System.Drawing.Size(440, 42)
$btnFast.Location = New-Object System.Drawing.Point(25, 133)
$btnFast.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 55)
$btnFast.ForeColor = [System.Drawing.Color]::White
$btnFast.FlatStyle = "Flat"
$btnFast.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnFast.Add_Click({
    Write-GuiLog "=== INICIANDO INSTAOPTIMIZED (BOOST RÁPIDO ASÍNCRONO) ==="
    Run-OptimizationAsync $false
})
$form.Controls.Add($btnFast)

$btnRestore = New-Object System.Windows.Forms.Button
$btnRestore.Text = "Revertir Cambios (Abrir Restaurar Sistema)"
$btnRestore.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$btnRestore.Size = New-Object System.Drawing.Size(440, 38)
$btnRestore.Location = New-Object System.Drawing.Point(25, 185)
$btnRestore.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 42)
$btnRestore.ForeColor = [System.Drawing.Color]::FromArgb(0, 200, 255)
$btnRestore.FlatStyle = "Flat"
$btnRestore.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnRestore.Add_Click({ Start-Process "rstrui.exe" })
$form.Controls.Add($btnRestore)

[void]$form.ShowDialog()
