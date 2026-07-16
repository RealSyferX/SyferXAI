# ============================================================
#  SyferX Control Panel - Lightweight WinForms GUI
#  Pure PowerShell + built-in .NET. Zero extra dependencies.
#  Setup:  Install / Build / Rebuild / Clean Cache
#  Run:    Start / Stop / Restart / Open Dashboard / Data Folder
#  Toggle: Start SyferX at Windows login  +  Low-memory mode
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Config -------------------------------------------------
$script:ProjectRoot = $PSScriptRoot
if (-not $script:ProjectRoot) { $script:ProjectRoot = (Get-Location).Path }
$script:Port         = 20127
$script:RunKeyPath   = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$script:RunKeyName   = "SyferXAI"
$script:DashboardUrl = "http://localhost:$($script:Port)/dashboard"
$script:DataDir      = Join-Path $env:APPDATA "9router"

# --- Palette (SyferX cyber-cyan) ----------------------------
$clrBg     = [System.Drawing.Color]::FromArgb(10, 14, 20)
$clrPanel  = [System.Drawing.Color]::FromArgb(19, 26, 36)
$clrText   = [System.Drawing.Color]::FromArgb(226, 232, 240)
$clrMuted  = [System.Drawing.Color]::FromArgb(148, 163, 184)
$clrCyan   = [System.Drawing.Color]::FromArgb(34, 211, 238)
$clrCyanDk = [System.Drawing.Color]::FromArgb(8, 145, 178)
$clrGreen  = [System.Drawing.Color]::FromArgb(34, 197, 94)
$clrRed    = [System.Drawing.Color]::FromArgb(239, 68, 68)
$clrAmber  = [System.Drawing.Color]::FromArgb(245, 158, 11)
$clrBorder = [System.Drawing.Color]::FromArgb(35, 45, 59)

# --- Helpers ------------------------------------------------
function Resolve-Pnpm {
    $cmd = Get-Command pnpm.cmd -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $cmd = Get-Command pnpm -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return "pnpm"
}
$script:Pnpm = Resolve-Pnpm

function Test-ServerRunning {
    try {
        $conn = Get-NetTCPConnection -LocalPort $script:Port -State Listen -ErrorAction SilentlyContinue
        return [bool]$conn
    } catch {
        $r = (netstat -ano | Select-String ":$($script:Port)\s" | Select-String "LISTENING")
        return [bool]$r
    }
}

function Get-ServerPids {
    $pids = @()
    try {
        $conns = Get-NetTCPConnection -LocalPort $script:Port -State Listen -ErrorAction SilentlyContinue
        foreach ($c in $conns) { $pids += $c.OwningProcess }
    } catch {
        $lines = netstat -ano | Select-String ":$($script:Port)\s" | Select-String "LISTENING"
        foreach ($l in $lines) {
            $parts = ($l.ToString() -split "\s+") | Where-Object { $_ -ne "" }
            if ($parts.Count -ge 5) { $pids += [int]$parts[-1] }
        }
    }
    return ($pids | Sort-Object -Unique)
}

function Write-Log {
    param([string]$msg, [System.Drawing.Color]$color = $clrText)
    $ts = Get-Date -Format "HH:mm:ss"
    $logBox.SelectionStart = $logBox.TextLength
    $logBox.SelectionLength = 0
    $logBox.SelectionColor = $color
    $logBox.AppendText("[$ts] $msg`r`n")
    $logBox.SelectionColor = $logBox.ForeColor
    $logBox.ScrollToCaret()
}

function Test-NodeModules { return (Test-Path (Join-Path $script:ProjectRoot "node_modules")) }
function Test-Built { return (Test-Path (Join-Path $script:ProjectRoot ".next\BUILD_ID")) }

function Get-FolderSizeMB {
    param([string]$path)
    if (-not (Test-Path $path)) { return 0 }
    try {
        $b = (Get-ChildItem $path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        return [math]::Round($b / 1MB, 1)
    } catch { return 0 }
}

# --- Run a pnpm task in a hidden process, stream to log -----
function Invoke-PnpmProcess {
    param([string]$Arguments, [string]$Label, [scriptblock]$OnDone, [hashtable]$ExtraEnv)
    Set-Buttons $false
    Write-Log "$Label ..." $clrCyan

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $script:Pnpm
    $psi.Arguments = $Arguments
    $psi.WorkingDirectory = $script:ProjectRoot
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    if ($ExtraEnv) { foreach ($k in $ExtraEnv.Keys) { $psi.EnvironmentVariables[$k] = $ExtraEnv[$k] } }

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    $proc.EnableRaisingEvents = $true
    Register-ObjectEvent -InputObject $proc -EventName OutputDataReceived -Action {
        if ($EventArgs.Data) { $form.Invoke([System.Windows.Forms.MethodInvoker]{ Write-Log $EventArgs.Data $clrMuted }) }
    } | Out-Null
    Register-ObjectEvent -InputObject $proc -EventName ErrorDataReceived -Action {
        if ($EventArgs.Data) { $form.Invoke([System.Windows.Forms.MethodInvoker]{ Write-Log $EventArgs.Data $clrMuted }) }
    } | Out-Null
    Register-ObjectEvent -InputObject $proc -EventName Exited -Action {
        $code = $proc.ExitCode
        $form.Invoke([System.Windows.Forms.MethodInvoker]{
            if ($code -eq 0) { Write-Log "$Label - done." $clrGreen }
            else { Write-Log "$Label - exited with code $code." $clrRed }
            Set-Buttons $true
            if ($OnDone) { & $OnDone }
        })
    } | Out-Null
    try { $proc.Start() | Out-Null; $proc.BeginOutputReadLine(); $proc.BeginErrorReadLine() }
    catch { Write-Log "Failed to launch pnpm: $($_.Exception.Message)" $clrRed; Set-Buttons $true }
}

# --- Actions ------------------------------------------------
function Do-Install { Invoke-PnpmProcess "install" "Installing dependencies" { Update-Status } }
function Do-Build   { Invoke-PnpmProcess "run build" "Building production bundle" { Update-Status } }

function Do-Rebuild {
    $nextDir = Join-Path $script:ProjectRoot ".next"
    Write-Log "Rebuild: clearing old build (.next) ..." $clrAmber
    if (Test-ServerRunning) { Write-Log "Server running - stop it first before rebuild." $clrRed; return }
    try {
        if (Test-Path $nextDir) { Remove-Item $nextDir -Recurse -Force -ErrorAction Stop }
        Write-Log ".next cleared. Starting fresh build ..." $clrCyan
    } catch { Write-Log "Could not clear .next: $($_.Exception.Message)" $clrRed; return }
    Invoke-PnpmProcess "run build" "Rebuilding production bundle" { Update-Status }
}

function Do-CleanCache {
    $cacheDir = Join-Path $script:ProjectRoot ".next\cache"
    $before = Get-FolderSizeMB $cacheDir
    if ($before -eq 0) { Write-Log "Build cache already empty." $clrMuted; return }
    try {
        Remove-Item $cacheDir -Recurse -Force -ErrorAction Stop
        Write-Log "Cleaned build cache - freed ~$before MB (safe; server still works)." $clrGreen
    } catch { Write-Log "Could not clean cache: $($_.Exception.Message)" $clrRed }
    Update-Status
}

function Start-Server {
    if (Test-ServerRunning) { Write-Log "Server already running on port $($script:Port)." $clrCyan; Update-Status; return }
    if (-not (Test-NodeModules)) { Write-Log "node_modules missing. Click 'Install Requirements' first." $clrRed; return }

    $mode = if (Test-Built) { "start" } else { "dev" }
    if ($mode -eq "dev") { Write-Log "No production build - starting in dev mode (run Build for lightest runtime)." $clrAmber }
    Write-Log "Starting SyferX server (pnpm run $mode)$(if($script:LowMem){' [low-memory]'}) ..." $clrCyan

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $script:Pnpm
    $psi.Arguments = "run $mode"
    $psi.WorkingDirectory = $script:ProjectRoot
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    if ($script:LowMem) { $psi.EnvironmentVariables["NODE_OPTIONS"] = "--max-old-space-size=512" }

    $script:ServerProc = New-Object System.Diagnostics.Process
    $script:ServerProc.StartInfo = $psi
    Register-ObjectEvent -InputObject $script:ServerProc -EventName OutputDataReceived -Action {
        if ($EventArgs.Data) { $form.Invoke([System.Windows.Forms.MethodInvoker]{ Write-Log $EventArgs.Data $clrMuted }) }
    } | Out-Null
    Register-ObjectEvent -InputObject $script:ServerProc -EventName ErrorDataReceived -Action {
        if ($EventArgs.Data) { $form.Invoke([System.Windows.Forms.MethodInvoker]{ Write-Log $EventArgs.Data $clrMuted }) }
    } | Out-Null
    try {
        $script:ServerProc.Start() | Out-Null
        $script:ServerProc.BeginOutputReadLine()
        $script:ServerProc.BeginErrorReadLine()
        Write-Log "Server launched. Waiting for port $($script:Port) ..." $clrCyan
    } catch { Write-Log "Failed to start server: $($_.Exception.Message)" $clrRed }
    Update-Status
}

function Stop-Server {
    $pids = Get-ServerPids
    if (-not $pids -or $pids.Count -eq 0) { Write-Log "No server running on port $($script:Port)." $clrMuted; Update-Status; return }
    foreach ($processId in $pids) {
        try { taskkill /PID $processId /T /F 2>&1 | Out-Null; Write-Log "Stopped process tree PID $processId." $clrGreen }
        catch { Write-Log "Could not stop PID $processId : $($_.Exception.Message)" $clrRed }
    }
    Start-Sleep -Milliseconds 400
    Update-Status
}

function Restart-Server {
    Write-Log "Restarting server ..." $clrAmber
    Stop-Server
    Start-Sleep -Milliseconds 800
    Start-Server
}

function Open-DataFolder {
    if (Test-Path $script:DataDir) { Start-Process explorer.exe $script:DataDir }
    else { Write-Log "Data folder not found yet: $($script:DataDir)" $clrMuted }
}

# --- Startup (auto-run at login) ----------------------------
function Get-StartupCommand { return (Join-Path $script:ProjectRoot "syferx-autostart.cmd") }

function Write-StartupLauncher {
    $launcher = Get-StartupCommand
    $pnpmCmd = $script:Pnpm
    $mode = if (Test-Built) { "start" } else { "dev" }
    $memLine = if ($script:LowMem) { "set NODE_OPTIONS=--max-old-space-size=512`r`n" } else { "" }
    $content = "@echo off`r`ncd /d `"$($script:ProjectRoot)`"`r`n${memLine}start `"`" /min `"$pnpmCmd`" run $mode`r`n"
    Set-Content -Path $launcher -Value $content -Encoding ASCII -Force
    return $launcher
}

function Test-StartupEnabled {
    try { return [bool](Get-ItemProperty -Path $script:RunKeyPath -Name $script:RunKeyName -ErrorAction SilentlyContinue) }
    catch { return $false }
}

function Enable-Startup {
    $launcher = Write-StartupLauncher
    Set-ItemProperty -Path $script:RunKeyPath -Name $script:RunKeyName -Value "`"$launcher`"" -Force
    Write-Log "Startup enabled - SyferX will launch at Windows login." $clrGreen
}

function Disable-Startup {
    try { Remove-ItemProperty -Path $script:RunKeyPath -Name $script:RunKeyName -ErrorAction SilentlyContinue; Write-Log "Startup disabled." $clrCyan }
    catch { Write-Log "Failed to disable startup: $($_.Exception.Message)" $clrRed }
}

# --- UI state ----------------------------------------------
$script:LowMem = $false

function Set-Buttons {
    param([bool]$enabled)
    $btnInstall.Enabled = $enabled
    $btnBuild.Enabled   = $enabled
    $btnRebuild.Enabled = $enabled
    $btnClean.Enabled   = $enabled
}

function Update-Status {
    $running = Test-ServerRunning
    if ($running) {
        $statusDot.BackColor = $clrGreen
        $statusLabel.Text = "RUNNING  -  port $($script:Port)"
        $statusLabel.ForeColor = $clrGreen
        $btnStart.Enabled = $false
        $btnStop.Enabled = $true
        $btnRestart.Enabled = $true
        $btnOpen.Enabled = $true
    } else {
        $statusDot.BackColor = $clrRed
        $statusLabel.Text = "STOPPED"
        $statusLabel.ForeColor = $clrRed
        $btnStart.Enabled = $true
        $btnStop.Enabled = $false
        $btnRestart.Enabled = $false
        $btnOpen.Enabled = $false
    }
    # Build/cache size hint in footer
    $nextMB = Get-FolderSizeMB (Join-Path $script:ProjectRoot ".next")
    $cacheMB = Get-FolderSizeMB (Join-Path $script:ProjectRoot ".next\cache")
    $footer.Text = "Build: $nextMB MB  |  Cache: $cacheMB MB  |  Root: $($script:ProjectRoot)"
}

# --- Styling helper ----------------------------------------
function Style-Button {
    param($btn, [System.Drawing.Color]$bg, [System.Drawing.Color]$fg)
    $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btn.FlatAppearance.BorderSize = 0
    $btn.BackColor = $bg
    $btn.ForeColor = $fg
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btn.Height = 38
}

# ============================================================
#  BUILD THE FORM
# ============================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "SyferX Control Panel"
$form.Size = New-Object System.Drawing.Size(560, 760)
$form.StartPosition = "CenterScreen"
$form.BackColor = $clrBg
$form.ForeColor = $clrText
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

# --- Header -------------------------------------------------
$header = New-Object System.Windows.Forms.Panel
$header.Size = New-Object System.Drawing.Size(560, 70)
$header.Location = New-Object System.Drawing.Point(0, 0)
$header.BackColor = $clrPanel
$form.Controls.Add($header)

$logo = New-Object System.Windows.Forms.Label
$logo.Text = ">_"
$logo.Font = New-Object System.Drawing.Font("Consolas", 20, [System.Drawing.FontStyle]::Bold)
$logo.ForeColor = $clrCyan
$logo.Location = New-Object System.Drawing.Point(20, 16)
$logo.Size = New-Object System.Drawing.Size(46, 40)
$header.Controls.Add($logo)

$title = New-Object System.Windows.Forms.Label
$title.Text = "SyferX"
$title.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = $clrText
$title.Location = New-Object System.Drawing.Point(66, 12)
$title.Size = New-Object System.Drawing.Size(200, 30)
$header.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = "AI Infrastructure Control Panel"
$subtitle.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$subtitle.ForeColor = $clrMuted
$subtitle.Location = New-Object System.Drawing.Point(68, 42)
$subtitle.Size = New-Object System.Drawing.Size(300, 18)
$header.Controls.Add($subtitle)

# --- Status row --------------------------------------------
$statusDot = New-Object System.Windows.Forms.Panel
$statusDot.Size = New-Object System.Drawing.Size(14, 14)
$statusDot.Location = New-Object System.Drawing.Point(24, 88)
$statusDot.BackColor = $clrRed
$form.Controls.Add($statusDot)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "STOPPED"
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$statusLabel.ForeColor = $clrRed
$statusLabel.Location = New-Object System.Drawing.Point(46, 85)
$statusLabel.Size = New-Object System.Drawing.Size(300, 22)
$form.Controls.Add($statusLabel)

# --- Setup label -------------------------------------------
$setupLabel = New-Object System.Windows.Forms.Label
$setupLabel.Text = "SETUP"
$setupLabel.Font = New-Object System.Drawing.Font("Segoe UI", 7.5, [System.Drawing.FontStyle]::Bold)
$setupLabel.ForeColor = $clrMuted
$setupLabel.Location = New-Object System.Drawing.Point(24, 116)
$setupLabel.Size = New-Object System.Drawing.Size(200, 14)
$form.Controls.Add($setupLabel)

# --- Setup buttons (2x2 grid) -------------------------------
$btnInstall = New-Object System.Windows.Forms.Button
$btnInstall.Text = "Install Requirements"
$btnInstall.Location = New-Object System.Drawing.Point(24, 133)
$btnInstall.Size = New-Object System.Drawing.Size(248, 38)
Style-Button $btnInstall $clrPanel $clrCyan
$btnInstall.FlatAppearance.BorderSize = 1
$btnInstall.FlatAppearance.BorderColor = $clrCyan
$form.Controls.Add($btnInstall)

$btnBuild = New-Object System.Windows.Forms.Button
$btnBuild.Text = "Build"
$btnBuild.Location = New-Object System.Drawing.Point(284, 133)
$btnBuild.Size = New-Object System.Drawing.Size(248, 38)
Style-Button $btnBuild $clrPanel $clrCyan
$btnBuild.FlatAppearance.BorderSize = 1
$btnBuild.FlatAppearance.BorderColor = $clrBorder
$form.Controls.Add($btnBuild)

$btnRebuild = New-Object System.Windows.Forms.Button
$btnRebuild.Text = "Rebuild (clean + build)"
$btnRebuild.Location = New-Object System.Drawing.Point(24, 179)
$btnRebuild.Size = New-Object System.Drawing.Size(248, 38)
Style-Button $btnRebuild $clrPanel $clrAmber
$btnRebuild.FlatAppearance.BorderSize = 1
$btnRebuild.FlatAppearance.BorderColor = $clrBorder
$form.Controls.Add($btnRebuild)

$btnClean = New-Object System.Windows.Forms.Button
$btnClean.Text = "Clean Cache"
$btnClean.Location = New-Object System.Drawing.Point(284, 179)
$btnClean.Size = New-Object System.Drawing.Size(248, 38)
Style-Button $btnClean $clrPanel $clrAmber
$btnClean.FlatAppearance.BorderSize = 1
$btnClean.FlatAppearance.BorderColor = $clrBorder
$form.Controls.Add($btnClean)

# --- Run label ---------------------------------------------
$runLabel = New-Object System.Windows.Forms.Label
$runLabel.Text = "SERVER"
$runLabel.Font = New-Object System.Drawing.Font("Segoe UI", 7.5, [System.Drawing.FontStyle]::Bold)
$runLabel.ForeColor = $clrMuted
$runLabel.Location = New-Object System.Drawing.Point(24, 227)
$runLabel.Size = New-Object System.Drawing.Size(200, 14)
$form.Controls.Add($runLabel)

# --- Start / Stop / Restart row -----------------------------
$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "START"
$btnStart.Location = New-Object System.Drawing.Point(24, 244)
$btnStart.Size = New-Object System.Drawing.Size(160, 46)
Style-Button $btnStart $clrCyanDk ([System.Drawing.Color]::White)
$btnStart.Height = 46
$form.Controls.Add($btnStart)

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Text = "STOP"
$btnStop.Location = New-Object System.Drawing.Point(190, 244)
$btnStop.Size = New-Object System.Drawing.Size(160, 46)
Style-Button $btnStop ([System.Drawing.Color]::FromArgb(40, 30, 34)) $clrRed
$btnStop.Height = 46
$btnStop.FlatAppearance.BorderSize = 1
$btnStop.FlatAppearance.BorderColor = $clrRed
$form.Controls.Add($btnStop)

$btnRestart = New-Object System.Windows.Forms.Button
$btnRestart.Text = "RESTART"
$btnRestart.Location = New-Object System.Drawing.Point(356, 244)
$btnRestart.Size = New-Object System.Drawing.Size(176, 46)
Style-Button $btnRestart $clrPanel $clrAmber
$btnRestart.Height = 46
$btnRestart.FlatAppearance.BorderSize = 1
$btnRestart.FlatAppearance.BorderColor = $clrAmber
$form.Controls.Add($btnRestart)

# --- Open dashboard + data folder ---------------------------
$btnOpen = New-Object System.Windows.Forms.Button
$btnOpen.Text = "Open Dashboard  ->"
$btnOpen.Location = New-Object System.Drawing.Point(24, 300)
$btnOpen.Size = New-Object System.Drawing.Size(326, 38)
Style-Button $btnOpen $clrPanel $clrText
$btnOpen.FlatAppearance.BorderSize = 1
$btnOpen.FlatAppearance.BorderColor = $clrBorder
$form.Controls.Add($btnOpen)

$btnData = New-Object System.Windows.Forms.Button
$btnData.Text = "Data Folder"
$btnData.Location = New-Object System.Drawing.Point(362, 300)
$btnData.Size = New-Object System.Drawing.Size(170, 38)
Style-Button $btnData $clrPanel $clrText
$btnData.FlatAppearance.BorderSize = 1
$btnData.FlatAppearance.BorderColor = $clrBorder
$form.Controls.Add($btnData)

# --- Toggles ------------------------------------------------
$chkStartup = New-Object System.Windows.Forms.CheckBox
$chkStartup.Text = "  Start SyferX automatically at Windows login"
$chkStartup.Location = New-Object System.Drawing.Point(26, 350)
$chkStartup.Size = New-Object System.Drawing.Size(500, 24)
$chkStartup.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$chkStartup.ForeColor = $clrText
$chkStartup.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$chkStartup.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($chkStartup)

$chkLowMem = New-Object System.Windows.Forms.CheckBox
$chkLowMem.Text = "  Low-memory mode (cap Node heap at 512 MB)"
$chkLowMem.Location = New-Object System.Drawing.Point(26, 378)
$chkLowMem.Size = New-Object System.Drawing.Size(500, 24)
$chkLowMem.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$chkLowMem.ForeColor = $clrText
$chkLowMem.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$chkLowMem.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($chkLowMem)

# --- Log box ------------------------------------------------
$logLabel = New-Object System.Windows.Forms.Label
$logLabel.Text = "Activity Log"
$logLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$logLabel.ForeColor = $clrMuted
$logLabel.Location = New-Object System.Drawing.Point(24, 412)
$logLabel.Size = New-Object System.Drawing.Size(200, 18)
$form.Controls.Add($logLabel)

$btnClearLog = New-Object System.Windows.Forms.Button
$btnClearLog.Text = "Clear"
$btnClearLog.Location = New-Object System.Drawing.Point(468, 408)
$btnClearLog.Size = New-Object System.Drawing.Size(64, 22)
Style-Button $btnClearLog $clrPanel $clrMuted
$btnClearLog.Height = 22
$btnClearLog.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$btnClearLog.FlatAppearance.BorderSize = 1
$btnClearLog.FlatAppearance.BorderColor = $clrBorder
$form.Controls.Add($btnClearLog)

$logBox = New-Object System.Windows.Forms.RichTextBox
$logBox.Location = New-Object System.Drawing.Point(24, 434)
$logBox.Size = New-Object System.Drawing.Size(508, 250)
$logBox.BackColor = $clrPanel
$logBox.ForeColor = $clrText
$logBox.Font = New-Object System.Drawing.Font("Consolas", 8.5)
$logBox.ReadOnly = $true
$logBox.BorderStyle = "None"
$logBox.ScrollBars = "Vertical"
$form.Controls.Add($logBox)

$footer = New-Object System.Windows.Forms.Label
$footer.Text = "Root: $($script:ProjectRoot)"
$footer.Font = New-Object System.Drawing.Font("Segoe UI", 7.5)
$footer.ForeColor = $clrMuted
$footer.Location = New-Object System.Drawing.Point(24, 690)
$footer.Size = New-Object System.Drawing.Size(508, 16)
$form.Controls.Add($footer)

# ============================================================
#  EVENTS
# ============================================================
$btnInstall.Add_Click({ Do-Install })
$btnBuild.Add_Click({ Do-Build })
$btnRebuild.Add_Click({ Do-Rebuild })
$btnClean.Add_Click({ Do-CleanCache })
$btnStart.Add_Click({ Start-Server })
$btnStop.Add_Click({ Stop-Server })
$btnRestart.Add_Click({ Restart-Server })
$btnOpen.Add_Click({ Start-Process $script:DashboardUrl })
$btnData.Add_Click({ Open-DataFolder })
$btnClearLog.Add_Click({ $logBox.Clear() })

$chkStartup.Add_CheckedChanged({
    if ($chkStartup.Checked) { Enable-Startup } else { Disable-Startup }
})
$chkLowMem.Add_CheckedChanged({
    $script:LowMem = $chkLowMem.Checked
    Write-Log "Low-memory mode $(if($script:LowMem){'ON (512MB heap cap)'}else{'OFF'}). Applies on next Start/Restart." $clrCyan
    if ($chkStartup.Checked) { Write-StartupLauncher | Out-Null }
})

$form.Add_FormClosing({
    param($sender, $e)
    if (Test-ServerRunning) {
        $r = [System.Windows.Forms.MessageBox]::Show(
            "SyferX server is still running. Stop it before closing?",
            "SyferX", [System.Windows.Forms.MessageBoxButtons]::YesNoCancel,
            [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($r -eq [System.Windows.Forms.DialogResult]::Yes) { Stop-Server }
        elseif ($r -eq [System.Windows.Forms.DialogResult]::Cancel) { $e.Cancel = $true }
    }
})

# --- Poll status every 3s (lightweight) ---------------------
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 3000
$timer.Add_Tick({ Update-Status })
$timer.Start()

# --- Init ---------------------------------------------------
Write-Log "SyferX Control Panel ready." $clrCyan
if (-not (Test-NodeModules)) { Write-Log "Tip: node_modules not found - click 'Install Requirements'." $clrMuted }
elseif (-not (Test-Built)) { Write-Log "Tip: no production build - click 'Build' for lightest runtime." $clrMuted }
$chkStartup.Checked = Test-StartupEnabled
Update-Status

[void]$form.ShowDialog()
$timer.Stop()
