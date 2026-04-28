# proto-maker installer (Windows)
#
# Usage: Right-click this file → Run with PowerShell
# Or:    PowerShell -ExecutionPolicy Bypass -File install.ps1
#
# Installs:
#   - binary   → %USERPROFILE%\proto-maker\bin\proto-maker-server.exe
#   - skills   → %USERPROFILE%\.codex\skills\proto-maker\
#   - agents   → %USERPROFILE%\.codex\skills\proto-maker\agents\
#   - templates→ %USERPROFILE%\proto-maker\templates\
#   - AGENTS.md→ %USERPROFILE%\.codex\AGENTS.md (if none exists)
#
# Adds %USERPROFILE%\proto-maker\bin\ to the user PATH.
# Runs Unblock-File on the .exe to clear Mark-of-the-Web.

$ErrorActionPreference = "Stop"

$InstallDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$UserProfile = $env:USERPROFILE

# Detect arch
$Arch = if ([Environment]::Is64BitOperatingSystem) { "amd64" } else {
    Write-Error "32-bit Windows not supported."; exit 2
}

$BinarySrc = Join-Path $InstallDir "proto-maker-server-windows-$Arch.exe"
if (-not (Test-Path $BinarySrc)) {
    Write-Error "Expected binary not found: $BinarySrc"
    exit 2
}

Write-Host "Installing proto-maker for windows-$Arch..."

# Binary
$BinDir = Join-Path $UserProfile "proto-maker\bin"
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
$BinDest = Join-Path $BinDir "proto-maker-server.exe"
Copy-Item -Force $BinarySrc $BinDest
Unblock-File $BinDest
Write-Host "  Binary installed to $BinDest"

# Skills + agents
$SkillsDir = Join-Path $UserProfile ".codex\skills\proto-maker"
if (Test-Path $SkillsDir) { Remove-Item -Recurse -Force $SkillsDir }
New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null
Copy-Item -Recurse -Force (Join-Path $InstallDir "skills\*") $SkillsDir
$AgentsDir = Join-Path $SkillsDir "agents"
New-Item -ItemType Directory -Force -Path $AgentsDir | Out-Null
Copy-Item -Recurse -Force (Join-Path $InstallDir "agents\*") $AgentsDir
Write-Host "  Skills installed to $SkillsDir"

# Templates
$TemplatesDir = Join-Path $UserProfile "proto-maker\templates"
if (Test-Path $TemplatesDir) { Remove-Item -Recurse -Force $TemplatesDir }
New-Item -ItemType Directory -Force -Path $TemplatesDir | Out-Null
Copy-Item -Recurse -Force (Join-Path $InstallDir "templates\*") $TemplatesDir
Write-Host "  Templates installed to $TemplatesDir"

# AGENTS.md
$AgentsMdTarget = Join-Path $UserProfile ".codex\AGENTS.md"
if (Test-Path $AgentsMdTarget) {
    Write-Host "  NOTE: $AgentsMdTarget already exists. Not overwriting."
    Write-Host "        proto-maker's AGENTS.md is at: $(Join-Path $InstallDir 'AGENTS.md')"
} else {
    New-Item -ItemType Directory -Force -Path (Split-Path $AgentsMdTarget) | Out-Null
    Copy-Item -Force (Join-Path $InstallDir "AGENTS.md") $AgentsMdTarget
    Write-Host "  AGENTS.md installed to $AgentsMdTarget"
}

# PATH: add $BinDir to user PATH if not already there
$UserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($UserPath -notlike "*$BinDir*") {
    $NewPath = if ($UserPath) { "$UserPath;$BinDir" } else { $BinDir }
    [Environment]::SetEnvironmentVariable("PATH", $NewPath, "User")
    Write-Host "  Added $BinDir to user PATH (restart your terminal for this to take effect)"
} else {
    Write-Host "  $BinDir already on user PATH"
}

Write-Host ""
Write-Host "Done. Open Codex CLI in a new terminal and try: /setup"
Write-Host ""
Write-Host "If Windows SmartScreen blocked this script, see README.md for the bypass."
