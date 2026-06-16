param(
  [string]$Mode = "dev"
)

$ErrorActionPreference = "Stop"
$RootDir = $PSScriptRoot
$ServerDir = Join-Path $RootDir "server"
$ServerEnvFile = Join-Path $ServerDir ".env"

Write-Host "╔══════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Uni Path Germany — Dev Starter   ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════╝" -ForegroundColor Cyan

# ──────────────────────────────────────────
# 1. Gemini API Key
# ──────────────────────────────────────────
if (-not (Test-Path $ServerEnvFile)) {
  $key = Read-Host "`nEnter your Gemini API Key (saved to server\.env, gitignored)"
  if ([string]::IsNullOrWhiteSpace($key)) {
    Write-Host "❌ Key is required" -ForegroundColor Red; exit 1
  }
  Set-Content -Path $ServerEnvFile -Value "GEMINI_API_KEY=$key" -Encoding UTF8
  Write-Host "✅ Saved to server\.env" -ForegroundColor Green
}

$apiKey = (Select-String -Path $ServerEnvFile -Pattern '^GEMINI_API_KEY=(.+)$').Matches.Groups[1].Value
if ([string]::IsNullOrWhiteSpace($apiKey)) {
  Write-Host "❌ GEMINI_API_KEY not found in server\.env" -ForegroundColor Red; exit 1
}

# ──────────────────────────────────────────
# 2. Start Server
# ──────────────────────────────────────────
Write-Host "`n🚀 Starting AI Proxy Server..." -ForegroundColor Cyan
$env:GEMINI_API_KEY = $apiKey
$serverLog = Join-Path $ServerDir "server.log"
$serverErr = Join-Path $ServerDir "server_error.log"

$serverProcess = Start-Process -FilePath "dart" -WorkingDirectory $ServerDir `
  -ArgumentList "run", "lib/server.dart" `
  -NoNewWindow -PassThru `
  -RedirectStandardOutput $serverLog `
  -RedirectStandardError $serverErr

$ready = $false
for ($i = 0; $i -lt 30; $i++) {
  Start-Sleep -Milliseconds 500
  if (Select-String -Path $serverLog -Pattern "AI Proxy running" -Quiet) { $ready = $true; break }
  if ($serverProcess.HasExited) {
    Write-Host "❌ Server failed:" -ForegroundColor Red
    Get-Content $serverErr -Tail 5
    $serverProcess.Kill(); exit 1
  }
}
if (-not $ready) {
  Write-Host "❌ Server timeout. Check server\server.log" -ForegroundColor Red
  $serverProcess.Kill(); exit 1
}
Write-Host "✅ Server running (PID: $($serverProcess.Id))" -ForegroundColor Green

# ──────────────────────────────────────────
# 3. Start Flutter
# ──────────────────────────────────────────
try {
  Write-Host "`n📱 Starting Flutter ($Mode mode)..." -ForegroundColor Cyan
  if ($Mode -eq "release") {
    & flutter build apk --dart-define-from-file="$RootDir\.env" --obfuscate --split-debug-info="$RootDir\debug-info"
    Write-Host "✅ APK built at build\app\outputs\flutter-apk\" -ForegroundColor Green
  } else {
    & flutter run --dart-define-from-file="$RootDir\.env"
  }
}
catch {
  Write-Host "`n⚠️  $_" -ForegroundColor Yellow
}
finally {
  if (-not $serverProcess.HasExited) {
    Write-Host "`n🛑 Stopping server..." -ForegroundColor Yellow
    $serverProcess.Kill(); Remove-Item $serverLog -ErrorAction SilentlyContinue; Remove-Item $serverErr -ErrorAction SilentlyContinue
  }
}

Write-Host "`n✅ Done" -ForegroundColor Green
